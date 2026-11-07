#!/usr/bin/env bash
# apply-external-commit.sh - applies an external commit package (see REPORT.md).
# Needs only: bash, git, sha256sum, coreutils. No sudo, no network except git.
# Exit codes: 0 PASS or nothing to do, 1 error, 2 integrity or guard failure
# (nothing changed), 3 push conflict (nothing pushed).
set -u
set -o pipefail

PKG="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY=0
NOPUSH=0
REMOTE_OVERRIDE=""
TMP=""
KEEP=0

usage() {
  cat <<'EOF'
Usage: ./apply-external-commit.sh [--dry-run] [--no-push] [--remote URL] [--help]

  --dry-run     Verify the package and the target, print what would change,
                commit nothing, push nothing.
  --no-push     Commit in a temporary clone, do not push; the clone is kept
                and its path is printed.
  --remote URL  Clone this URL instead of the one recorded in the package
                (for tests or mirrors). The base commit must still match.
  --help        This text.

Run it directly (the package keeps the executable bit); no chmod is needed.
EOF
}

cleanup() {
  local base="${TMPDIR:-/tmp}"
  base="${base%/}"
  if [ -n "$TMP" ] && [ "$KEEP" = 0 ] && [ -d "$TMP" ]; then
    case "$TMP" in
      "$base"/ext-commit.*) rm -rf -- "$TMP" ;;
    esac
  fi
}
trap cleanup EXIT

fail() {
  echo "FAIL $1" >&2
  exit "${2:-1}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --no-push) NOPUSH=1 ;;
    --remote)
      shift
      [ $# -gt 0 ] || fail "--remote needs a URL"
      REMOTE_OVERRIDE="$1"
      ;;
    --help | -h) usage; exit 0 ;;
    *) usage >&2; fail "unknown option: $1" ;;
  esac
  shift
done

for tool in git sha256sum sort awk sed find mktemp; do
  command -v "$tool" >/dev/null 2>&1 || fail "required tool missing: $tool"
done

# ---------------------------------------------------------------- 1. package
[ -f "$PKG/SHA256SUMS" ] || fail "SHA256SUMS missing in the package" 2
for f in external-commit.meta MANIFEST.tsv COMMIT_MESSAGE.txt; do
  [ -f "$PKG/$f" ] || fail "package file missing: $f" 2
done
if [ -n "$(find "$PKG" -type l -print -quit)" ]; then
  fail "the package contains a symbolic link" 2
fi
(cd "$PKG" && sha256sum -c --quiet SHA256SUMS >/dev/null 2>&1) \
  || fail "SHA-256 check of the package failed (run: cd '$PKG' && sha256sum -c SHA256SUMS)" 2
listed="$(sed -E 's/^\\?[0-9a-f]{64}[ *] //' "$PKG/SHA256SUMS" | LC_ALL=C sort)"
present="$(cd "$PKG" && find . -type f ! -name SHA256SUMS | sed 's|^\./||' | LC_ALL=C sort)"
[ "$listed" = "$present" ] || fail "the package has files that SHA256SUMS does not list, or the reverse" 2
echo "OK   package integrity: every file matches SHA256SUMS"

REPO=""; REMOTE_URL=""; BRANCH=""; BASE=""; STAMP=""; FORMAT=""
while IFS='=' read -r k v; do
  case "$k" in
    format) FORMAT="$v" ;;
    repo) REPO="$v" ;;
    remote_url) REMOTE_URL="$v" ;;
    branch) BRANCH="$v" ;;
    base_commit) BASE="$v" ;;
    timestamp) STAMP="$v" ;;
  esac
done <"$PKG/external-commit.meta"
[ "$FORMAT" = "1" ] || fail "unsupported package format: '$FORMAT'" 2
[[ "$REPO" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]] || fail "bad repo in metadata: '$REPO'" 2
[[ "$BRANCH" =~ ^[A-Za-z0-9._/-]+$ && "$BRANCH" != -* ]] || fail "bad branch in metadata: '$BRANCH'" 2
[[ "$BASE" =~ ^[0-9a-f]{40}$ ]] || fail "bad base commit in metadata" 2
[ -n "$REMOTE_URL" ] || fail "remote_url missing in metadata" 2
REPO_NAME="${REPO#*/}"

# ----------------------------------------------------------------- 2. manifest
bad_path() {
  local p="$1" l
  case "$p" in
    "" | /* | *//* | . | .. | ./* | ../* | */. | */.. | */./* | */../*) return 0 ;;
  esac
  [[ "$p" =~ [[:cntrl:]] ]] && return 0
  [[ "$p" == *\\* ]] && return 0
  l="${p,,}"
  case "$l" in
    .git | .git/* | */.git | */.git/*) return 0 ;;
  esac
  return 1
}

ACTS=(); OMODES=(); OSHAS=(); NMODES=(); NSHAS=(); PATHS=()
while IFS=$'\t' read -r act omode osha nmode nsha size path; do
  case "$act" in "" | \#*) continue ;; esac
  [[ "$act" =~ ^[AMD]$ ]] || fail "manifest: bad action '$act'" 2
  [[ "$omode" =~ ^(100644|100755|-)$ && "$nmode" =~ ^(100644|100755|-)$ ]] || fail "manifest: bad mode for '$path'" 2
  [[ "$osha" =~ ^([0-9a-f]{64}|-)$ && "$nsha" =~ ^([0-9a-f]{64}|-)$ ]] || fail "manifest: bad hash for '$path'" 2
  bad_path "$path" && fail "manifest: unsafe path '$path'" 2
  if [ "$act" != D ]; then
    [ -f "$PKG/files/$path" ] && [ ! -L "$PKG/files/$path" ] || fail "package has no payload file for '$path'" 2
    actual="$(sha256sum <"$PKG/files/$path" | cut -d' ' -f1)"
    [ "$actual" = "$nsha" ] || fail "payload of '$path' does not match the manifest hash" 2
  fi
  ACTS+=("$act"); OMODES+=("$omode"); OSHAS+=("$osha"); NMODES+=("$nmode"); NSHAS+=("$nsha"); PATHS+=("$path")
done <"$PKG/MANIFEST.tsv"
N=${#PATHS[@]}
[ "$N" -gt 0 ] || fail "the manifest lists no files" 2
dups="$(printf '%s\n' "${PATHS[@]}" | LC_ALL=C sort | uniq -d)"
[ -z "$dups" ] || fail "manifest lists a path twice: $dups" 2
echo "OK   manifest: $N file(s)"

# ------------------------------------------------------------------ 3. target
TMPBASE="${TMPDIR:-/tmp}"
TMPBASE="${TMPBASE%/}"
TMP="$(mktemp -d "$TMPBASE/ext-commit.XXXXXX")" || fail "cannot create a temporary directory"
WORK="$TMP/$REPO_NAME"
SOURCE="${REMOTE_OVERRIDE:-$REMOTE_URL}"
if [ -n "$REMOTE_OVERRIDE" ]; then
  echo "NOTE remote overridden: $SOURCE"
else
  src_name="${SOURCE%/}"; src_name="${src_name%.git}"; src_name="${src_name##*/}"
  [ "$src_name" = "$REPO_NAME" ] || fail "remote '$SOURCE' is not the repository '$REPO'" 2
fi
git clone --quiet --branch "$BRANCH" --single-branch "$SOURCE" "$WORK" 2>"$TMP/clone.err" \
  || fail "cannot clone '$SOURCE' branch '$BRANCH': $(tr '\n' ' ' <"$TMP/clone.err")"
G=(git -C "$WORK")
"${G[@]}" cat-file -e "$BASE^{commit}" 2>/dev/null \
  || fail "base commit $BASE is not in the cloned history: wrong repository?" 2
"${G[@]}" merge-base --is-ancestor "$BASE" HEAD \
  || fail "base commit $BASE is not an ancestor of $BRANCH: wrong repository or rewritten history" 2
START="$("${G[@]}" rev-parse HEAD)"
echo "OK   target: $REPO ($BRANCH), base $BASE is in its history, tip $START"

# -------------------------------------------------- 4. guard (preimage checks)
blob_sha() { "${G[@]}" cat-file blob "HEAD:$1" | sha256sum | cut -d' ' -f1; }

TODO=(); problems=0
for ((i = 0; i < N; i++)); do
  p="${PATHS[$i]}"; act="${ACTS[$i]}"
  cur_mode=""; cur_sha=""
  line="$("${G[@]}" ls-tree HEAD -- "$p")"
  if [ -n "$line" ]; then
    cur_mode="${line%% *}"
    rest="${line#* }"; cur_type="${rest%% *}"
    if [ "$cur_type" != blob ] || [[ "$cur_mode" != 100644 && "$cur_mode" != 100755 ]]; then
      echo "GUARD $p: exists but is not a regular file ($cur_mode $cur_type)" >&2
      problems=$((problems + 1)); continue
    fi
    cur_sha="$(blob_sha "$p")"
  fi
  case "$act" in
    A)
      if [ -z "$cur_mode" ]; then TODO+=("$i")
      elif [ "$cur_sha" = "${NSHAS[$i]}" ] && [ "$cur_mode" = "${NMODES[$i]}" ]; then echo "SKIP $p: already added"
      else echo "GUARD $p: exists with different content or mode (expected it to be absent)" >&2; problems=$((problems + 1)); fi
      ;;
    M)
      if [ -z "$cur_mode" ]; then echo "GUARD $p: missing on the remote (expected it to exist)" >&2; problems=$((problems + 1))
      elif [ "$cur_sha" = "${OSHAS[$i]}" ] && [ "$cur_mode" = "${OMODES[$i]}" ]; then TODO+=("$i")
      elif [ "$cur_sha" = "${NSHAS[$i]}" ] && [ "$cur_mode" = "${NMODES[$i]}" ]; then echo "SKIP $p: already changed"
      else echo "GUARD $p: changed on the remote since the base commit (old content no longer matches)" >&2; problems=$((problems + 1)); fi
      ;;
    D)
      if [ -z "$cur_mode" ]; then echo "SKIP $p: already deleted"
      elif [ "$cur_sha" = "${OSHAS[$i]}" ] && [ "$cur_mode" = "${OMODES[$i]}" ]; then TODO+=("$i")
      else echo "GUARD $p: changed on the remote since the base commit (cannot delete)" >&2; problems=$((problems + 1)); fi
      ;;
  esac
done
[ "$problems" -eq 0 ] || fail "$problems guard check(s) failed; nothing was changed" 2

if [ "$START" != "$BASE" ]; then
  moved="$("${G[@]}" rev-list --count "$BASE..HEAD")"
  others="$("${G[@]}" diff --name-only "$BASE" HEAD | grep -c -v -x -F -f <(printf '%s\n' "${PATHS[@]}") || true)"
  echo "NOTE the remote has $moved newer commit(s) since the base; $others other file(s) differ; none of the package files conflict"
fi
echo "OK   guard: old content matches for all files that change"

if [ "${#TODO[@]}" -eq 0 ]; then
  echo "nothing to do: every file already has the new content"
  exit 0
fi

echo "Plan (${#TODO[@]} file(s)):"
for i in "${TODO[@]}"; do
  case "${ACTS[$i]}" in
    A) echo "  add     ${PATHS[$i]} (mode ${NMODES[$i]})" ;;
    M) echo "  modify  ${PATHS[$i]} (mode ${OMODES[$i]} -> ${NMODES[$i]})" ;;
    D) echo "  delete  ${PATHS[$i]}" ;;
  esac
done

if [ "$DRY" = 1 ]; then
  echo "DRY RUN OK: nothing was committed or pushed"
  exit 0
fi

# ------------------------------------------------------------------ 5. apply
parents_ok() {
  local d
  d="$(dirname "$1")"
  while [ "$d" != "." ] && [ "$d" != "/" ]; do
    [ -L "$WORK/$d" ] && return 1
    d="$(dirname "$d")"
  done
  return 0
}

for i in "${TODO[@]}"; do
  p="${PATHS[$i]}"
  parents_ok "$p" || fail "'$p' lies below a symbolic link"
  if [ "${ACTS[$i]}" = D ]; then
    "${G[@]}" rm -q -- "$p" || fail "git rm failed for '$p'"
  else
    mkdir -p -- "$WORK/$(dirname "$p")" || fail "cannot create the directory of '$p'"
    cp -- "$PKG/files/$p" "$WORK/$p" || fail "cannot write '$p'"
    if [ "${NMODES[$i]}" = 100755 ]; then chmod 755 -- "$WORK/$p"; else chmod 644 -- "$WORK/$p"; fi
    [ "$(sha256sum <"$WORK/$p" | cut -d' ' -f1)" = "${NSHAS[$i]}" ] || fail "written file '$p' does not match the expected hash"
    "${G[@]}" add -- "$p" || fail "git add failed for '$p'"
    if [ "${NMODES[$i]}" = 100755 ]; then "${G[@]}" update-index --chmod=+x -- "$p"; else "${G[@]}" update-index --chmod=-x -- "$p"; fi
  fi
done

verify_commit() {
  local i p line mode rest exp got
  exp="$(for i in "${TODO[@]}"; do echo "${PATHS[$i]}"; done | LC_ALL=C sort)"
  got="$("${G[@]}" diff-tree -r --no-commit-id --no-renames --name-only HEAD | LC_ALL=C sort)"
  [ "$exp" = "$got" ] || { echo "the commit touches other files than the manifest" >&2; return 1; }
  for i in "${TODO[@]}"; do
    p="${PATHS[$i]}"
    line="$("${G[@]}" ls-tree HEAD -- "$p")"
    if [ "${ACTS[$i]}" = D ]; then
      [ -z "$line" ] || { echo "'$p' still exists" >&2; return 1; }
    else
      mode="${line%% *}"
      [ "$mode" = "${NMODES[$i]}" ] || { echo "'$p' has mode $mode, expected ${NMODES[$i]}" >&2; return 1; }
      [ "$(blob_sha "$p")" = "${NSHAS[$i]}" ] || { echo "'$p' content differs from the package" >&2; return 1; }
    fi
  done
  return 0
}

"${G[@]}" commit -q -F "$PKG/COMMIT_MESSAGE.txt" 2>"$TMP/commit.err" \
  || fail "git commit failed (is git user.name / user.email set?): $(tr '\n' ' ' <"$TMP/commit.err")"
verify_commit || fail "the new commit does not match the package"
SHA="$("${G[@]}" rev-parse HEAD)"
echo "OK   committed $SHA"

# ------------------------------------------------------------------- 6. push
if [ "$NOPUSH" = 1 ]; then
  KEEP=1
  echo "PASS $SHA (committed in a temporary clone, NOT pushed)"
  echo "Clone kept at: $WORK"
  echo "Push it:       git -C '$WORK' push origin HEAD:refs/heads/$BRANCH"
  echo "Discard it:    rm -rf '$TMP'"
  exit 0
fi

if ! "${G[@]}" push -q origin "HEAD:refs/heads/$BRANCH" 2>"$TMP/push.err"; then
  echo "NOTE push rejected, fetching and rebasing once (never forcing)"
  "${G[@]}" fetch -q origin "$BRANCH" || fail "fetch after a rejected push failed"
  if ! "${G[@]}" rebase -q "origin/$BRANCH" >/dev/null 2>&1; then
    "${G[@]}" rebase --abort >/dev/null 2>&1
    fail "rebase conflict; nothing was pushed" 3
  fi
  SHA="$("${G[@]}" rev-parse HEAD)"
  verify_commit || fail "after the rebase the commit does not match the package; nothing was pushed"
  "${G[@]}" push -q origin "HEAD:refs/heads/$BRANCH" 2>"$TMP/push.err" \
    || fail "push rejected again: $(tr '\n' ' ' <"$TMP/push.err")"
fi
remote_sha="$("${G[@]}" ls-remote origin "refs/heads/$BRANCH" | cut -f1)"
[ "$remote_sha" = "$SHA" ] || fail "after the push the remote ($remote_sha) differs from the new commit ($SHA)"
echo "PASS $SHA"
echo "Undo: in a clone of $REPO run: git revert $SHA && git push origin $BRANCH"
