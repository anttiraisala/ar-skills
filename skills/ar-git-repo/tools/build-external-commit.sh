#!/usr/bin/env bash
# build-external-commit.sh - builds an external commit zip from the changes of a local clone.
# Usage:
#   build-external-commit.sh --message "subject\n\nbody" [--trailer "Key: value"]...
#       [--repo-dir DIR] [--out-dir DIR] [--base REF] [--branch NAME] [--remote-url URL]
# The changes are everything that differs between BASE (default origin/<branch>) and the
# working tree of the clone: committed, uncommitted and untracked files. Nothing is
# committed or pushed. Output: <out-dir>/external-commit-<repo>-<YYYYMMDDHHMMSS>.zip
# (UTC time; EXTERNAL_COMMIT_TIMESTAMP=14 digits overrides it, for tests).
set -u
set -o pipefail

TOOLS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MESSAGE=""; TRAILERS=(); REPO_DIR="."; OUT_DIR="."; BASE_REF=""; BRANCH=""; REMOTE_URL=""
TMP=""

fail() { echo "FAIL $1" >&2; exit "${2:-1}"; }
cleanup() {
  local base="${TMPDIR:-/tmp}"; base="${base%/}"
  case "$TMP" in "$base"/ext-build.*) [ -d "$TMP" ] && rm -rf -- "$TMP" ;; esac
}
trap cleanup EXIT

while [ $# -gt 0 ]; do
  case "$1" in
    --message) shift; MESSAGE="${1:-}" ;;
    --message-file) shift; [ -f "${1:-}" ] || fail "message file not found"; MESSAGE="$(cat -- "$1")" ;;
    --trailer) shift; TRAILERS+=("${1:-}") ;;
    --repo-dir) shift; REPO_DIR="${1:-.}" ;;
    --out-dir) shift; OUT_DIR="${1:-.}" ;;
    --base) shift; BASE_REF="${1:-}" ;;
    --branch) shift; BRANCH="${1:-}" ;;
    --remote-url) shift; REMOTE_URL="${1:-}" ;;
    --help | -h) sed -n 2,10p "${BASH_SOURCE[0]}"; exit 0 ;;
    *) fail "unknown option: $1" ;;
  esac
  shift
done
[ -n "$MESSAGE" ] || fail "a commit message is required (--message or --message-file)"
for tool in git sha256sum sort awk sed find mktemp stat wc python3; do
  command -v "$tool" >/dev/null 2>&1 || fail "required tool missing: $tool"
done
[ -f "$TOOLS/apply-external-commit.sh" ] || fail "apply-external-commit.sh not found next to this script"

TOP="$(git -C "$REPO_DIR" rev-parse --show-toplevel 2>/dev/null)" || fail "not a git repository: $REPO_DIR"
mkdir -p -- "$OUT_DIR" && OUT_DIR="$(cd "$OUT_DIR" && pwd)" || fail "cannot use the output directory"
cd "$TOP" || fail "cannot enter $TOP"
[ -n "$BRANCH" ] || BRANCH="$(git rev-parse --abbrev-ref HEAD)"
[[ "$BRANCH" =~ ^[A-Za-z0-9._/-]+$ && "$BRANCH" != -* && "$BRANCH" != HEAD ]] || fail "cannot work out the branch (got '$BRANCH'); use --branch"

# repository: owner/name from the origin URL (last two path components)
ORIGIN="$REMOTE_URL"
[ -n "$ORIGIN" ] || ORIGIN="$(git remote get-url origin 2>/dev/null)" || fail "no origin remote; use --remote-url"
trimmed="${ORIGIN%/}"; trimmed="${trimmed%.git}"
name="${trimmed##*/}"; rest="${trimmed%/*}"; owner="${rest##*[/:]}"
[[ "$owner" =~ ^[A-Za-z0-9._-]+$ && "$name" =~ ^[A-Za-z0-9._-]+$ ]] || fail "cannot read owner/name from '$ORIGIN'; use --remote-url"
REPO="$owner/$name"
case "$ORIGIN" in
  https://github.com/* | git@github.com:* | ssh://git@github.com/*) CANON="https://github.com/$REPO.git" ;;
  *) if [ -n "$REMOTE_URL" ]; then CANON="$REMOTE_URL"; else CANON="https://github.com/$REPO.git"; fi ;;
esac

FETCH_NOTE="origin/$BRANCH was fetched before the manifest was built."
if [ -z "$BASE_REF" ]; then
  git fetch -q origin "$BRANCH" 2>/dev/null || FETCH_NOTE="The fetch of origin/$BRANCH failed; the base is the last known origin/$BRANCH."
  BASE_REF="origin/$BRANCH"
fi
BASE="$(git rev-parse --verify -q "$BASE_REF^{commit}")" || fail "base '$BASE_REF' not found"
git merge-base --is-ancestor "$BASE" HEAD || fail "the base $BASE is not an ancestor of HEAD"

STAMP="${EXTERNAL_COMMIT_TIMESTAMP:-$(date -u +%Y%m%d%H%M%S)}"
[[ "$STAMP" =~ ^[0-9]{14}$ ]] || fail "timestamp must be 14 digits YYYYMMDDHHMMSS"
NAME="external-commit-$name-$STAMP"
ZIP="$OUT_DIR/$NAME.zip"
[ ! -e "$ZIP" ] || fail "$ZIP already exists"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/ext-build.XXXXXX")" || fail "cannot create a temporary directory"
PK="$TMP/$NAME"
mkdir -p "$PK/files"

sha_of() { sha256sum | cut -d' ' -f1; }
mode_of() { if (( 8#$(stat -c %a -- "$1") & 8#111 )); then echo 100755; else echo 100644; fi; }

# ------------------------------------------------------------------ manifest
{ git diff --name-only -z --no-renames "$BASE"; git ls-files -z --others --exclude-standard; } \
  | LC_ALL=C sort -z -u >"$TMP/paths.z"

ROWS="$TMP/rows.tsv"; : >"$ROWS"
total=0; all_text=1
while IFS= read -r -d '' p; do
  [[ "$p" =~ [[:cntrl:]] || "$p" == *\\* || "$p" == " "* || "$p" == *" " ]] && fail "path not supported in a package: '$p'"
  case "${p,,}" in .git | .git/* | */.git | */.git/*) fail "refusing to package a .git path: $p" ;; esac
  line="$(git ls-tree "$BASE" -- "$p")"
  omode="-"; osha="-"
  if [ -n "$line" ]; then
    omode="${line%% *}"; rest="${line#* }"
    [ "${rest%% *}" = blob ] && [[ "$omode" == 100644 || "$omode" == 100755 ]] || fail "'$p' is not a regular file in the base ($omode)"
    osha="$(git cat-file blob "$BASE:$p" | sha_of)"
  fi
  if [ -L "$p" ]; then fail "'$p' is a symbolic link; not supported"; fi
  if [ -f "$p" ]; then
    nmode="$(mode_of "$p")"; nsha="$(sha_of <"$p")"; size="$(wc -c <"$p" | tr -d ' ')"
    [ "$omode" = "$nmode" ] && [ "$osha" = "$nsha" ] && continue
    [ "$omode" = "-" ] && act=A || act=M
    mkdir -p "$PK/files/$(dirname "$p")"
    cp -- "$p" "$PK/files/$p"
    chmod "${nmode#100}" "$PK/files/$p" 2>/dev/null || true
    if [ "$nmode" = 100755 ]; then chmod 755 "$PK/files/$p"; else chmod 644 "$PK/files/$p"; fi
    total=$((total + size))
    if [ "$size" -gt 0 ]; then
      grep -qI . "$p" || all_text=0
      [ "$(tail -c1 "$p" | od -An -c | tr -d ' ')" = '\n' ] || all_text=0
      grep -q -x -F '=====END FILE=====' "$p" && all_text=0
    fi
  else
    [ "$omode" = "-" ] && continue
    act=D; nmode="-"; nsha="-"; size=0
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$act" "$omode" "$osha" "$nmode" "$nsha" "$size" "$p" >>"$ROWS"
done <"$TMP/paths.z"
[ -s "$ROWS" ] || fail "no changes between $BASE_REF and the working tree; nothing to package"
NFILES="$(wc -l <"$ROWS" | tr -d ' ')"

{
  printf '# ACTION\tOLD_MODE\tOLD_SHA256\tNEW_MODE\tNEW_SHA256\tSIZE\tPATH\n'
  cat "$ROWS"
} >"$PK/MANIFEST.tsv"

# ------------------------------------------------------------------- metadata
{
  printf 'format=1\nrepo=%s\nremote_url=%s\nbranch=%s\nbase_commit=%s\ntimestamp=%s\n' "$REPO" "$CANON" "$BRANCH" "$BASE" "$STAMP"
} >"$PK/external-commit.meta"

{
  printf '%s\n' "$MESSAGE"
  unpushed="$(git log --format='- %h %s' "$BASE..HEAD")"
  if [ -n "$unpushed" ]; then
    printf '\nOriginal commits not yet on %s:\n%s\n' "$BRANCH" "$unpushed"
  fi
  if [ "${#TRAILERS[@]}" -gt 0 ]; then
    printf '\n'
    printf '%s\n' "${TRAILERS[@]}"
  fi
} >"$PK/COMMIT_MESSAGE.txt"

install -m 0755 "$TOOLS/apply-external-commit.sh" "$PK/apply-external-commit.sh"
[ -f "$TOOLS/dry-run-apply-external-commit.sh" ] || fail "dry-run-apply-external-commit.sh not found next to this script"
install -m 0755 "$TOOLS/dry-run-apply-external-commit.sh" "$PK/dry-run-apply-external-commit.sh"

# --------------------------------------------------------------------- report
ADD=$(awk -F'\t' '$1=="A"' "$ROWS" | wc -l | tr -d ' ')
MOD=$(awk -F'\t' '$1=="M"' "$ROWS" | wc -l | tr -d ' ')
DEL=$(awk -F'\t' '$1=="D"' "$ROWS" | wc -l | tr -d ' ')
{
  echo "# External commit report"
  echo
  echo "- Repository: https://github.com/$REPO"
  echo "- Branch: \`$BRANCH\`"
  echo "- Base commit: \`$BASE\` (the package applies on top of it or any later commit that did not change the listed files)"
  echo "- Built (UTC): $STAMP"
  echo "- Changes: $NFILES file(s): $ADD added, $MOD modified, $DEL deleted"
  echo "- Nothing in this package was pushed or committed to the repository by the builder."
  echo "- $FETCH_NOTE"
  echo
  echo "## Commit message"
  echo
  echo '```'
  cat "$PK/COMMIT_MESSAGE.txt"
  echo '```'
  echo
  echo "## Files"
  echo
  echo "| Action | Path | Old SHA-256 | New SHA-256 | Size | Mode |"
  echo "|---|---|---|---|---|---|"
  awk -F'\t' '{ m = ($1=="D") ? "-" : $4; if ($1=="M" && $2!=$4) m = $2 " -> " $4;
     printf "| %s | `%s` | `%s` | `%s` | %s | %s |\n", $1, $7, $3, $5, $6, m }' "$ROWS"
  echo
  echo "## How to apply"
  echo
  echo "Unpack the zip on Linux. The script keeps its executable bit, so no \`chmod\` is needed."
  echo
  echo '```'
  echo "unzip $NAME.zip"
  echo "cd $NAME"
  echo "./dry-run-apply-external-commit.sh      # same as apply-external-commit.sh --dry-run: verify everything, change nothing"
  echo "./apply-external-commit.sh --no-push   # commit in a temporary clone, keep it, do not push"
  echo "./apply-external-commit.sh             # commit and push (never forced)"
  echo '```'
  echo
  echo "Needs \`git\`, \`bash\` and \`sha256sum\`, and write access to the repository for the push. Options: \`--remote URL\` clones another URL (tests, mirrors). Exit codes: 0 PASS or nothing to do, 1 error, 2 integrity or guard failure (nothing changed), 3 push conflict (nothing pushed)."
  echo
  echo "What the script does: checks \`SHA256SUMS\` and that no file is missing or extra; validates the manifest and every path; clones the repository into a fresh temporary directory and confirms that the base commit is in its history; checks that every changed or deleted file still has the old content hash and mode and that added files are absent; writes the files with the recorded modes; commits with \`COMMIT_MESSAGE.txt\`; verifies the commit (exact file set, modes, content hashes); pushes without force (one fetch and rebase if rejected); checks that the remote equals the new commit and prints \`PASS <sha>\`."
  echo
  echo "## How to undo"
  echo
  echo '```'
  echo "git clone https://github.com/$REPO.git && cd ${REPO#*/}"
  echo "git revert <sha printed after PASS>"
  echo "git push origin $BRANCH"
  echo '```'
  echo
  echo "With \`--no-push\` nothing left the temporary clone: delete it (the script prints its path)."
  echo
  echo "## Commands that produced this package"
  echo
  echo '```'
  echo "git fetch origin $BRANCH; git rev-parse $BASE_REF            # base commit"
  echo "git diff --name-only -z --no-renames <base>                  # changed and deleted files"
  echo "git ls-files -z --others --exclude-standard                  # new files"
  echo "git ls-tree <base> -- <path>; git cat-file blob <base>:<path> | sha256sum   # old mode and hash"
  echo "stat -c %a <path>; sha256sum < <path>; wc -c < <path>        # new mode, hash and size"
  echo "sha256sum <every package file> > SHA256SUMS; zip -X -r $NAME.zip $NAME"
  echo '```'
  echo
  echo "Built by \`build-external-commit.sh\` of the ar-git-repo skill."
} >"$PK/REPORT.md"

# --------------------------------------------------------------------- prompt
INLINE=0
[ "$total" -lt 40000 ] && [ "$all_text" = 1 ] && [ "$DEL$ADD$MOD" != "" ] && INLINE=1
{
  echo "TASK: apply one prepared commit to the GitHub repository $REPO (branch $BRANCH)."
  echo
  echo "You need a shell with git, bash and sha256sum and write access to the repository."
  echo "Base commit the change was built on: $BASE"
  echo
  if [ "$INLINE" = 0 ]; then
    echo "The package is the attached zip: $NAME.zip (the change is too large or not plain text for pasting)."
    echo
    echo "Steps:"
    echo "1. Unpack it: unzip $NAME.zip && cd $NAME"
    echo "2. Check it: sha256sum -c SHA256SUMS"
    echo "3. Run: ./dry-run-apply-external-commit.sh   (it calls apply-external-commit.sh --dry-run)"
    echo "4. If that ends with 'DRY RUN OK' (or 'nothing to do'), run: ./apply-external-commit.sh"
    echo "   (the scripts keep their executable bit; do not run chmod, do not edit any file of the package)"
    echo
    echo "Rules: never use --force, never push by hand, never edit the package files."
    echo "If the script exits with 2 (guard or integrity) or 3 (conflict), stop and report; do not try to work around it."
  else
    echo "Rules: write each file below byte for byte, overwriting any existing file; the content of a file is the lines"
    echo "between its two marker lines (every line ends with a newline). Touch no other file. Set the mode given in the"
    echo "table (100755 = executable, 100644 = normal): git add the file, then git update-index --chmod=+x or -x."
    echo "Delete the files marked D (git rm). Never force-push. Before writing, check that each file you change or delete"
    echo "still has the old SHA-256 in the table (git show HEAD:<path> | sha256sum) and that added files do not exist;"
    echo "if anything differs, stop and report. Commit once with the message below, push to $BRANCH, then check that"
    echo "git ls-remote origin $BRANCH equals your HEAD and that the SHA-256 of every written file equals the table."
    echo
    echo "COMMIT MESSAGE (use it exactly):"
    echo "-----"
    cat "$PK/COMMIT_MESSAGE.txt"
    echo "-----"
    echo
    echo "ACTION  MODE    OLD-SHA256 (before)                                              NEW-SHA256 (after)                                               PATH"
    awk -F'\t' '{ printf "%s  %s  %s  %s  %s\n", $1, ($1=="D"?"-":$4), $3, $5, $7 }' "$ROWS"
    echo
    while IFS=$'\t' read -r act omode osha nmode nsha size path; do
      [ "$act" = D ] && continue
      echo "=====FILE: $path====="
      cat -- "$PK/files/$path"
      echo "=====END FILE====="
    done <"$ROWS"
    echo
  fi
  echo "REPORT (in the language I write in, at most five lines): the new commit SHA, whether the verification passed, and anything unexpected."
} >"$PK/PROMPT.txt"

# ------------------------------------------------------------------ checksums
(cd "$PK" && find . -type f ! -name SHA256SUMS -print0 | LC_ALL=C sort -z | xargs -0 sha256sum | sed -E 's|^([0-9a-f]{64})  \./|\1  |') >"$PK/SHA256SUMS"
chmod 644 "$PK/SHA256SUMS" "$PK/REPORT.md" "$PK/PROMPT.txt" "$PK/MANIFEST.tsv" "$PK/external-commit.meta" "$PK/COMMIT_MESSAGE.txt"
chmod 755 "$PK/apply-external-commit.sh" "$PK/dry-run-apply-external-commit.sh"

# ------------------------------------------------------------------------ zip
if command -v zip >/dev/null 2>&1; then
  (cd "$TMP" && zip -X -q -r "$ZIP" "$NAME") || fail "zip failed"
else
  python3 - "$TMP" "$NAME" "$ZIP" <<'PY' || fail "python zip fallback failed"
import os, sys, zipfile
base, name, out = sys.argv[1:4]
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    for root, dirs, files in os.walk(os.path.join(base, name)):
        dirs.sort()
        for f in sorted(files):
            full = os.path.join(root, f)
            zi = zipfile.ZipInfo.from_file(full, os.path.relpath(full, base))
            zi.compress_type = zipfile.ZIP_DEFLATED
            with open(full, "rb") as fh:
                z.writestr(zi, fh.read())
PY
fi

# ------------------------------------------------------------ self-verification
python3 -I - "$ZIP" "$NAME" <<'PY' || fail "the zip does not keep the executable bit of the apply scripts"
import sys, zipfile
z = zipfile.ZipFile(sys.argv[1]); name = sys.argv[2]; bad = 0
for f in ("apply-external-commit.sh", "dry-run-apply-external-commit.sh"):
    mode = z.getinfo(name + "/" + f).external_attr >> 16
    print("OK   zip stores %s with unix mode %o" % (f, mode & 0o7777))
    if mode & 0o111 != 0o111: bad = 1
sys.exit(bad)
PY
if command -v unzip >/dev/null 2>&1; then
  mkdir "$TMP/verify" && unzip -q "$ZIP" -d "$TMP/verify" || fail "the zip cannot be unpacked"
  [ -x "$TMP/verify/$NAME/apply-external-commit.sh" ] && [ -x "$TMP/verify/$NAME/dry-run-apply-external-commit.sh" ] || fail "after unpacking, an apply script is not executable"
  (cd "$TMP/verify/$NAME" && sha256sum -c --quiet SHA256SUMS) || fail "SHA256SUMS does not verify after unpacking"
  echo "OK   unpacked copy: both apply scripts are executable and SHA256SUMS verifies"
else
  echo "NOTE unzip is not installed; the unpack check was skipped"
fi
echo "BUILT $ZIP ($NFILES file(s): $ADD added, $MOD modified, $DEL deleted; prompt form: $([ "$INLINE" = 1 ] && echo inline || echo zip))"
