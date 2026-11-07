#!/usr/bin/env bash
# selftest-external-commit.sh - end-to-end test of build-external-commit.sh and
# apply-external-commit.sh in a throwaway directory. It uses only local bare
# repositories under a temporary directory; nothing is sent to any network.
# Usage: ./selftest-external-commit.sh [--keep]
set -u
TOOLS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEEP=0; [ "${1:-}" = "--keep" ] && KEEP=1
T="$(mktemp -d "${TMPDIR:-/tmp}/ext-selftest.XXXXXX")"
trap '[ "$KEEP" = 1 ] || rm -rf -- "$T"' EXIT
export HOME="$T/home"; mkdir -p "$HOME"
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
export GIT_AUTHOR_NAME=selftest GIT_AUTHOR_EMAIL=selftest@example.invalid
export GIT_COMMITTER_NAME=selftest GIT_COMMITTER_EMAIL=selftest@example.invalid
PASS=0; FAILS=0
ok()  { PASS=$((PASS + 1)); echo "  ok   $1"; }
bad() { FAILS=$((FAILS + 1)); echo "  FAIL $1"; }
check() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then ok "$d"; else bad "$d"; fi; }
expect_rc() { local d="$1" want="$2"; shift 2; local out rc; out="$("$@" 2>&1)"; rc=$?; LAST="$out"
  if [ "$rc" = "$want" ]; then ok "$d (exit $rc)"; else bad "$d (exit $rc, wanted $want): $out"; fi; }
G() { git -C "$1" "${@:2}"; }

# --- fixture: origin (bare), seed clone, three byte-identical copies of the origin
git init -q --bare -b master "$T/o/ar-skills.git"
git clone -q "$T/o/ar-skills.git" "$T/work" 2>/dev/null
cd "$T/work" || exit 1
git checkout -q -b master
mkdir -p dir
printf 'alpha\n' >a.txt; printf 'bravo\n' >dir/b.txt; printf '#!/bin/sh\necho run\n' >run.sh; chmod 755 run.sh
printf 'old\n' >old.txt; printf '#!/bin/sh\n' >modeonly.sh; printf 'other\n' >other.txt
git add -A; git commit -q -m seed; git push -q origin master
for n in A B C W; do git clone -q --bare "$T/o/ar-skills.git" "$T/$n/ar-skills.git"; done 2>/dev/null
BASE="$(G "$T/work" rev-parse HEAD)"
# --- the change: modify, add (executable and with a space), delete, mode-only change
printf 'alpha changed\n' >a.txt
printf '#!/bin/sh\necho new\n' >dir/new.sh; chmod 755 dir/new.sh
printf 'with space\n' >"dir/with space.txt"
rm old.txt; chmod 755 modeonly.sh

echo "== build"
OUT="$T/out"
LAST="$(EXTERNAL_COMMIT_TIMESTAMP= "$TOOLS/build-external-commit.sh" --repo-dir "$T/work" --out-dir "$OUT" --remote-url "$T/o/ar-skills.git" --message "Selftest change" --trailer "Co-Authored-By: Test <t@example.invalid>" 2>&1)"; rc=$?
[ "$rc" = 0 ] && ok "builder exit 0" || bad "builder exit $rc: $LAST"
echo "$LAST" | sed 's/^/       /'
ZIP="$(ls "$OUT"/*.zip 2>/dev/null | head -1)"; BN="$(basename "$ZIP" .zip)"
[[ "$(basename "$ZIP")" =~ ^external-commit-ar-skills-[0-9]{14}\.zip$ ]] && ok "zip name matches external-commit-<repo>-<YYYYMMDDHHMMSS>.zip" || bad "zip name: $ZIP"
python3 -I - "$ZIP" "$BN" <<'PY' && ok "zip stores unix mode 755 for apply-external-commit.sh" || bad "zip mode"
import sys, zipfile
z = zipfile.ZipFile(sys.argv[1]); n = sys.argv[2]
m = z.getinfo(n + "/apply-external-commit.sh").external_attr >> 16
print("    mode %o" % (m & 0o7777)); sys.exit(0 if (m & 0o7777) == 0o755 else 1)
PY
python3 -I - "$ZIP" "$BN" <<'PY' && ok "zip stores mode 755 for dir/new.sh and 644 for dir/with space.txt" || bad "payload modes in zip"
import sys, zipfile
z = zipfile.ZipFile(sys.argv[1]); n = sys.argv[2]
a = z.getinfo(n + "/files/dir/new.sh").external_attr >> 16 & 0o7777
b = z.getinfo(n + "/files/dir/with space.txt").external_attr >> 16 & 0o7777
sys.exit(0 if (a, b) == (0o755, 0o644) else 1)
PY
for f in apply-external-commit.sh REPORT.md PROMPT.txt SHA256SUMS MANIFEST.tsv COMMIT_MESSAGE.txt; do
  check "zip contains $f" python3 -I -c "import sys,zipfile;zipfile.ZipFile(sys.argv[1]).getinfo(sys.argv[2])" "$ZIP" "$BN/$f"
done

echo "== unpack and run directly (no chmod)"
mkdir "$T/x" && unzip -q "$ZIP" -d "$T/x" && ok "unzip works on Linux" || bad "unzip"
P="$T/x/$BN"
check "apply script is executable after unzip" test -x "$P/apply-external-commit.sh"
check "SHA256SUMS verifies" bash -c "cd '$P' && sha256sum -c --quiet SHA256SUMS"
cd "$P" || exit 1
expect_rc "dry run" 0 ./apply-external-commit.sh --dry-run --remote "$T/A/ar-skills.git"
echo "$LAST" | grep -q "DRY RUN OK" && ok "dry run says DRY RUN OK" || bad "dry run text"
[ "$(G "$T/A/ar-skills.git" rev-parse master)" = "$BASE" ] && ok "dry run left the remote unchanged" || bad "dry run changed the remote"

echo "== --no-push: real commit in a temporary clone"
expect_rc "no-push run" 0 ./apply-external-commit.sh --no-push --remote "$T/A/ar-skills.git"
CL="$(echo "$LAST" | sed -n 's/^Clone kept at: //p')"
NEW="$(echo "$LAST" | sed -n 's/^PASS \([0-9a-f]\{40\}\).*/\1/p')"
[ -n "$NEW" ] && [ "$(G "$CL" rev-parse HEAD)" = "$NEW" ] && ok "a real Git commit exists in the clone ($NEW)" || bad "no commit in the clone"
[ "$(G "$CL" rev-parse HEAD~1)" = "$BASE" ] && ok "the commit sits on the base commit" || bad "parent differs"
[ "$(G "$CL" diff-tree -r --no-commit-id --name-status HEAD | LC_ALL=C sort | tr '\n\t' ' |')" = "A|dir/new.sh A|dir/with space.txt D|old.txt M|a.txt M|modeonly.sh " ] \
  && ok "commit has exactly the expected file changes" || bad "commit file set: $(G "$CL" diff-tree -r --no-commit-id --name-status HEAD | tr '\n' ' ')"
[ "$(G "$CL" ls-tree HEAD dir/new.sh | cut -d' ' -f1)" = 100755 ] && ok "dir/new.sh is 100755 in the commit" || bad "new.sh mode"
[ "$(G "$CL" ls-tree HEAD modeonly.sh | cut -d' ' -f1)" = 100755 ] && ok "mode-only change recorded (modeonly.sh 100755)" || bad "modeonly mode"
[ "$(G "$CL" ls-tree HEAD a.txt | cut -d' ' -f1)" = 100644 ] && ok "a.txt stays 100644" || bad "a.txt mode"
[ "$(G "$CL" show HEAD:a.txt)" = "alpha changed" ] && ok "a.txt content applied" || bad "a.txt content"
[ -z "$(G "$CL" ls-tree HEAD old.txt)" ] && ok "old.txt deleted" || bad "old.txt still there"
G "$CL" log -1 --format=%B | grep -q "^Co-Authored-By: Test" && ok "commit message carries the trailer" || bad "trailer missing"
[ "$(G "$T/A/ar-skills.git" rev-parse master)" = "$BASE" ] && ok "--no-push left the remote unchanged" || bad "--no-push pushed"
rm -rf -- "$(dirname "$CL")"

echo "== push to a local throwaway bare repository"
expect_rc "apply with push" 0 ./apply-external-commit.sh --remote "$T/A/ar-skills.git"
NEW="$(echo "$LAST" | sed -n 's/^PASS \([0-9a-f]\{40\}\).*/\1/p')"
[ -n "$NEW" ] && [ "$(G "$T/A/ar-skills.git" rev-parse master)" = "$NEW" ] && ok "remote equals the reported SHA" || bad "remote differs"
echo "$LAST" | grep -q "git revert $NEW" && ok "undo command is printed" || bad "no undo command"
[ "$(G "$T/A/ar-skills.git" ls-tree master dir/new.sh | cut -d' ' -f1)" = 100755 ] && ok "pushed tree keeps 100755" || bad "pushed mode"
expect_rc "second run is idempotent" 0 ./apply-external-commit.sh --remote "$T/A/ar-skills.git"
echo "$LAST" | grep -q "nothing to do" && ok "second run says nothing to do" || bad "idempotence text"

echo "== guard: the remote changed a file the package changes"
W="$T/g"; git clone -q "$T/B/ar-skills.git" "$W" 2>/dev/null; printf 'someone else\n' >"$W/a.txt"; G "$W" commit -qam other; G "$W" push -q origin master
HB="$(G "$T/B/ar-skills.git" rev-parse master)"
expect_rc "guard blocks a changed preimage" 2 ./apply-external-commit.sh --remote "$T/B/ar-skills.git"
echo "$LAST" | grep -q "GUARD a.txt" && ok "guard names the file" || bad "guard text"
[ "$(G "$T/B/ar-skills.git" rev-parse master)" = "$HB" ] && ok "nothing changed on the remote" || bad "remote changed"

echo "== remote moved, other file only"
W="$T/g2"; git clone -q "$T/C/ar-skills.git" "$W" 2>/dev/null; printf 'other2\n' >"$W/other.txt"; G "$W" commit -qam other; G "$W" push -q origin master
expect_rc "applies on a newer remote" 0 ./apply-external-commit.sh --remote "$T/C/ar-skills.git"
echo "$LAST" | grep -q "NOTE the remote has 1 newer" && ok "reports that the remote moved" || bad "move note"

echo "== wrong repository"
git init -q --bare -b master "$T/other/ar-skills.git"; W="$T/g3"; git clone -q "$T/other/ar-skills.git" "$W" 2>/dev/null; G "$W" checkout -q -b master; echo x >"$W/x"; G "$W" add x; G "$W" commit -qm x; G "$W" push -q origin master
expect_rc "different history is refused" 2 ./apply-external-commit.sh --remote "$T/other/ar-skills.git"
echo "$LAST" | grep -q "base commit" && ok "message mentions the base commit" || bad "wrong repo text"
cp -a "$P" "$T/t4"; sed -i "s|^remote_url=.*|remote_url=https://github.com/someone/not-ar-skills.git|" "$T/t4/external-commit.meta"
(cd "$T/t4" && find . -type f ! -name SHA256SUMS -print0 | LC_ALL=C sort -z | xargs -0 sha256sum | sed -E 's|^([0-9a-f]{64})  \./|\1  |' >SHA256SUMS)
expect_rc "recorded URL of another repository is refused" 2 "$T/t4/apply-external-commit.sh" --dry-run
echo "$LAST" | grep -q "is not the repository" && ok "message names the repository mismatch" || bad "name mismatch text"

echo "== tampered packages"
cp -a "$P" "$T/t1"; printf 'x' >>"$T/t1/files/a.txt"
expect_rc "changed payload file" 2 "$T/t1/apply-external-commit.sh" --dry-run --remote "$T/W/ar-skills.git"
cp -a "$P" "$T/t2"; echo extra >"$T/t2/extra.txt"
expect_rc "extra file in the package" 2 "$T/t2/apply-external-commit.sh" --dry-run --remote "$T/W/ar-skills.git"
cp -a "$P" "$T/t3"; sed -i 's|\ta.txt$|\t../evil|' "$T/t3/MANIFEST.tsv"; (cd "$T/t3" && find . -type f ! -name SHA256SUMS -print0 | LC_ALL=C sort -z | xargs -0 sha256sum | sed -E 's|^([0-9a-f]{64})  \./|\1  |' >SHA256SUMS)
expect_rc "unsafe path in the manifest (checksums valid)" 2 "$T/t3/apply-external-commit.sh" --dry-run --remote "$T/W/ar-skills.git"
echo "$LAST" | grep -q "unsafe path" && ok "unsafe path is named" || bad "unsafe path text"
expect_rc "unknown option" 1 ./apply-external-commit.sh --bogus

echo "== inline prompt form and unpushed commits"
cd "$T/work" || exit 1; git add -A; git commit -q -m "local commit one"; printf 'more\n' >>dir/b.txt
LAST="$(EXTERNAL_COMMIT_TIMESTAMP=20260101000000 "$TOOLS/build-external-commit.sh" --repo-dir "$T/work" --out-dir "$T/out2" --message "Second" 2>&1)"
echo "$LAST" | grep -q "prompt form: inline" && ok "small text change gets the inline prompt" || bad "prompt form: $LAST"
[ -f "$T/out2/external-commit-ar-skills-20260101000000.zip" ] && ok "timestamp override gives the expected name" || bad "override name"
mkdir "$T/x2" && unzip -q "$T/out2"/*.zip -d "$T/x2"
grep -q "^=====FILE: dir/b.txt=====" "$T/x2"/*/PROMPT.txt && ok "inline prompt has FILE blocks" || bad "no file blocks"
grep -q "Original commits not yet on master" "$T/x2"/*/COMMIT_MESSAGE.txt && ok "unpushed commits are listed in the message body" || bad "no original commits"
head -c 50000 /dev/zero | tr '\0' 'x' | fold -w 80 >big.txt
LAST="$(EXTERNAL_COMMIT_TIMESTAMP=20260101000001 "$TOOLS/build-external-commit.sh" --repo-dir "$T/work" --out-dir "$T/out3" --message "Big" 2>&1)"
echo "$LAST" | grep -q "prompt form: zip" && ok "large change gets the zip-form prompt" || bad "zip form: $LAST"

echo
echo "RESULT: $PASS passed, $FAILS failed"
[ "$FAILS" = 0 ]
