#!/usr/bin/env bash
# Run a command and mirror its output into a PR comment while it runs.
#
# Usage: live-comment.sh <title> <output-file> <command...>
# Env:   GH_TOKEN, REPO (owner/name), PR_NUMBER (optional; no PR => just run the command)
set -uo pipefail

TITLE="$1"
OUT="$2"
shift 2

MARKER="<!-- live-comment:${TITLE} -->"
: > "$OUT"

render() {
  {
    echo "$MARKER"
    echo "### ${TITLE}: $1"
    echo '```diff'
    # Move +/-/~ to column 0 so GitHub's diff block colors them like the terminal.
    sed -E 's/^( *)\+/+\1/; s/^( *)-/-\1/; s/^( *)~/!\1/' "$OUT" | tail -c 60000
    echo
    echo '```'
  } > "${OUT}.md"
}

post() {
  if [ -n "${COMMENT_ID:-}" ]; then
    gh api -X PATCH "repos/${REPO}/issues/comments/${COMMENT_ID}" -F "body=@${OUT}.md" > /dev/null || true
  fi
}

UPDATER=""
if [ -n "${PR_NUMBER:-}" ]; then
  render "running"
  # Reuse this title's comment if it already exists, otherwise create one.
  COMMENT_ID=$(gh api --paginate "repos/${REPO}/issues/${PR_NUMBER}/comments" \
    --jq ".[] | select(.body | contains(\"${MARKER}\")) | .id" | head -n1)
  if [ -n "$COMMENT_ID" ]; then
    post
  else
    COMMENT_ID=$(gh api "repos/${REPO}/issues/${PR_NUMBER}/comments" -F "body=@${OUT}.md" --jq .id) || COMMENT_ID=""
  fi
  # Refresh the comment every few seconds while the command runs.
  ( while true; do sleep 8; render "running"; post; done ) &
  UPDATER=$!
fi

"$@" 2>&1 | tee "$OUT"
RC=${PIPESTATUS[0]}

if [ -n "$UPDATER" ]; then
  kill "$UPDATER" 2>/dev/null
  wait "$UPDATER" 2>/dev/null
  if [ "$RC" -eq 0 ]; then render "succeeded"; else render "failed"; fi
  post
fi

exit "$RC"
