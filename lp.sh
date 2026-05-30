#!/bin/bash

# ================================================================
#  lp.sh — LeetCode Auto-Organizer & GitHub Pusher (Mac compatible)
#  Usage:
#    ./lp.sh 42
#    ./lp.sh 42 hard
#    ./lp.sh "42 trapping rain water"
#    ./lp.sh "[3940. Limit Occurrences](https://leetcode.com/problems/limit-occurrences-in-sorted-array/)"
# ================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Mac-compatible uppercase function (no ${VAR^} syntax)
uppercase_first() {
  echo "$1" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}'
}

INPUT="$1"
DIFFICULTY_ARG="$2"

if [ -z "$INPUT" ]; then
  echo -e "${RED}Error: No input given.${NC}"
  echo ""
  echo "Usage:"
  echo "  ./lp.sh 42"
  echo "  ./lp.sh 42 hard"
  echo "  ./lp.sh \"42 trapping rain water\""
  exit 1
fi

PROBLEM_NUM=""
PROBLEM_NAME=""
PROBLEM_SLUG=""

# ── Detect input mode ────────────────────────────────────────
if echo "$INPUT" | grep -qE '^\[.*\]\(https://leetcode\.com'; then
  # Mode 1: Markdown link [3940. Name](url)
  PROBLEM_NUM=$(echo "$INPUT" | grep -oE '^\[[0-9]+' | grep -oE '[0-9]+')
  PROBLEM_NAME=$(echo "$INPUT" | sed 's/^\[//' | sed 's/\](.*$//' | sed "s/^${PROBLEM_NUM}\. //")
  PROBLEM_SLUG=$(echo "$INPUT" | grep -oE 'problems/[^/)]+' | sed 's/problems\///')
  if [ -z "$PROBLEM_SLUG" ]; then
    PROBLEM_SLUG=$(echo "$PROBLEM_NAME" | awk '{print tolower($0)}' | sed 's/ /-/g' | sed 's/[^a-z0-9-]//g')
  fi
  echo -e "${CYAN}${BOLD}Detected from LeetCode link${NC}"

elif echo "$INPUT" | grep -qE '^[0-9]+$'; then
  # Mode 2: Just a number
  PROBLEM_NUM="$INPUT"
  echo -e "${CYAN}${BOLD}Searching by problem number: ${PROBLEM_NUM}${NC}"

else
  # Mode 3: "42 problem name"
  PROBLEM_NUM=$(echo "$INPUT" | grep -oE '^[0-9]+')
  PROBLEM_NAME=$(echo "$INPUT" | sed "s/^${PROBLEM_NUM}[[:space:]]*//" | sed 's/^[ -]*//')
  PROBLEM_SLUG=$(echo "$PROBLEM_NAME" | awk '{print tolower($0)}' | sed 's/ /-/g' | sed 's/[^a-z0-9-]//g')
  echo -e "${CYAN}${BOLD}Manual input mode${NC}"
fi

# ── Difficulty ───────────────────────────────────────────────
if [ -n "$DIFFICULTY_ARG" ]; then
  DIFFICULTY=$(echo "$DIFFICULTY_ARG" | awk '{print tolower($0)}')
else
  DIFFICULTY="medium"
fi

if [[ ! "$DIFFICULTY" =~ ^(easy|medium|hard)$ ]]; then
  echo -e "${YELLOW}Unknown difficulty, defaulting to medium${NC}"
  DIFFICULTY="medium"
fi

# ── Find solution file by problem number ─────────────────────
FOUND_FILE=""

for f in "${PROBLEM_NUM}"-* "${PROBLEM_NUM}"_* "${PROBLEM_NUM}".* ; do
  [ -f "$f" ] || continue
  case "$f" in
    *.md|*.sh|*.txt|*.py[co]) continue ;;
    *.) continue ;;  # skip files with no extension like "802."
  esac
  # Make sure it has a real extension
  EXT_CHECK="${f##*.}"
  if [ "$EXT_CHECK" = "$f" ] || [ -z "$EXT_CHECK" ]; then
    continue
  fi
  FOUND_FILE="$f"
  break
done

# Also try plain "NUMBER.ext" pattern
if [ -z "$FOUND_FILE" ]; then
  for f in "${PROBLEM_NUM}".*; do
    [ -f "$f" ] || continue
    case "$f" in
      *.md|*.sh|*.txt) continue ;;
    esac
    EXT_CHECK="${f##*.}"
    if [ -n "$EXT_CHECK" ] && [ "$EXT_CHECK" != "$f" ]; then
      FOUND_FILE="$f"
      break
    fi
  done
fi

if [ -z "$FOUND_FILE" ]; then
  echo -e "${RED}Error: No solution file found for problem #${PROBLEM_NUM}${NC}"
  echo ""
  echo "Create your file first:"
  echo "  nano ${PROBLEM_NUM}.py    (Python)"
  echo "  nano ${PROBLEM_NUM}.java  (Java)"
  echo "  nano ${PROBLEM_NUM}.cpp   (C++)"
  exit 1
fi

# ── Detect language ──────────────────────────────────────────
EXT="${FOUND_FILE##*.}"
EXT=$(echo "$EXT" | awk '{print tolower($0)}')

case "$EXT" in
  py)    LANG="Python" ;;
  cpp)   LANG="C++" ;;
  java)  LANG="Java" ;;
  js)    LANG="JavaScript" ;;
  ts)    LANG="TypeScript" ;;
  go)    LANG="Go" ;;
  rs)    LANG="Rust" ;;
  c)     LANG="C" ;;
  cs)    LANG="C#" ;;
  rb)    LANG="Ruby" ;;
  kt)    LANG="Kotlin" ;;
  swift) LANG="Swift" ;;
  *)     LANG="$EXT" ;;
esac

# ── Extract problem name from filename if not set ────────────
if [ -z "$PROBLEM_NAME" ]; then
  RAW=$(basename "$FOUND_FILE")
  RAW=$(echo "$RAW" | sed "s/^${PROBLEM_NUM}[-_. ]*//" | sed "s/\.${EXT}$//")
  if [ -n "$RAW" ]; then
    PROBLEM_NAME=$(echo "$RAW" | sed 's/-/ /g' | sed 's/_/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')
    PROBLEM_SLUG=$(echo "$RAW" | awk '{print tolower($0)}' | sed 's/_/-/g')
  else
    PROBLEM_NAME="Problem ${PROBLEM_NUM}"
    PROBLEM_SLUG="problem-${PROBLEM_NUM}"
  fi
fi

# Fallback slug if still empty
if [ -z "$PROBLEM_SLUG" ]; then
  PROBLEM_SLUG=$(echo "$PROBLEM_NAME" | awk '{print tolower($0)}' | sed 's/ /-/g' | sed 's/[^a-z0-9-]//g')
fi

DATE=$(date +%Y-%m-%d)
FILE_CONTENT=$(cat "$FOUND_FILE" | awk '{print tolower($0)}')

# ── Topic Detection ──────────────────────────────────────────
detect_topic() {
  local content="$1"

  # Check for explicit hint comment: # topic: graph
  EXPLICIT=$(echo "$content" | grep -oE 'topic[[:space:]]*:[[:space:]]*[a-z]+' | head -1 | grep -oE '[a-z]+$')
  if [ -n "$EXPLICIT" ]; then
    case "$EXPLICIT" in
      graph|graphs)        echo "graph";      return ;;
      tree|trees|bst|trie) echo "tree";       return ;;
      linkedlist|linked)   echo "linkedlist"; return ;;
      array|arrays)        echo "arrays";     return ;;
      dp|dynamic)          echo "dp";         return ;;
    esac
  fi

  G=0; T=0; L=0; A=0; D=0

  echo "$content" | grep -qE '\bgraph\b'       && G=$((G+3))
  echo "$content" | grep -qE '\bbfs\b'         && G=$((G+3))
  echo "$content" | grep -qE '\bdfs\b'         && G=$((G+3))
  echo "$content" | grep -qE '\badjacency\b'   && G=$((G+3))
  echo "$content" | grep -qE '\btopological\b' && G=$((G+3))
  echo "$content" | grep -qE '\bdijkstra\b'    && G=$((G+3))
  echo "$content" | grep -qE '\bunion.find\b'  && G=$((G+2))
  echo "$content" | grep -qE '\bvisited\b'     && G=$((G+1))
  echo "$content" | grep -qE '\bneighbor\b'    && G=$((G+2))

  echo "$content" | grep -qE '\btreenode\b'    && T=$((T+4))
  echo "$content" | grep -qE '\btree\b'        && T=$((T+2))
  echo "$content" | grep -qE '\broot\b'        && T=$((T+3))
  echo "$content" | grep -qE '\binorder\b'     && T=$((T+3))
  echo "$content" | grep -qE '\bpreorder\b'    && T=$((T+3))
  echo "$content" | grep -qE '\bpostorder\b'   && T=$((T+3))
  echo "$content" | grep -qE '\bheap\b'        && T=$((T+2))
  echo "$content" | grep -qE '\btrie\b'        && T=$((T+3))

  echo "$content" | grep -qE '\blistnode\b'    && L=$((L+4))
  echo "$content" | grep -qE '\blinkedlist\b'  && L=$((L+3))
  echo "$content" | grep -qE '\bnext\b'        && L=$((L+2))
  echo "$content" | grep -qE '\bhead\b'        && L=$((L+2))
  echo "$content" | grep -qE '\bdummy\b'       && L=$((L+2))
  echo "$content" | grep -qE '\bslow\b'        && L=$((L+1))
  echo "$content" | grep -qE '\bfast\b'        && L=$((L+1))

  echo "$content" | grep -qE '\bsliding.window\b' && A=$((A+4))
  echo "$content" | grep -qE '\btwo.pointer\b'    && A=$((A+4))
  echo "$content" | grep -qE '\bprefix.sum\b'     && A=$((A+4))
  echo "$content" | grep -qE '\bsubarray\b'       && A=$((A+3))
  echo "$content" | grep -qE '\barray\b'          && A=$((A+2))
  echo "$content" | grep -qE '\bnums\b'           && A=$((A+2))
  echo "$content" | grep -qE '\bbinary.search\b'  && A=$((A+2))

  echo "$content" | grep -qE '\bmemoization\b' && D=$((D+4))
  echo "$content" | grep -qE '\btabulation\b'  && D=$((D+4))
  echo "$content" | grep -qE '\bknapsack\b'    && D=$((D+4))
  echo "$content" | grep -qE '\bsubproblem\b'  && D=$((D+3))
  echo "$content" | grep -qE '\bmemo\b'        && D=$((D+2))
  echo "$content" | grep -qE '\bcache\b'       && D=$((D+2))
  echo "$content" | grep -qE '\blongest\b'     && D=$((D+1))
  echo "$content" | grep -qE '\bfibonacci\b'   && D=$((D+2))
  echo "$content" | grep -qE '\bdp\b'          && D=$((D+3))

  MAX=2; TOPIC="other"
  [ $G -gt $MAX ] && { MAX=$G; TOPIC="graph"; }
  [ $T -gt $MAX ] && { MAX=$T; TOPIC="tree"; }
  [ $L -gt $MAX ] && { MAX=$L; TOPIC="linkedlist"; }
  [ $A -gt $MAX ] && { MAX=$A; TOPIC="arrays"; }
  [ $D -gt $MAX ] && { MAX=$D; TOPIC="dp"; }

  echo "$TOPIC"
}

TOPIC=$(detect_topic "$FILE_CONTENT")

TOPIC_DISPLAY=$(uppercase_first "$TOPIC")
DIFF_DISPLAY=$(uppercase_first "$DIFFICULTY")

# ── Print summary ────────────────────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}${BOLD}  LeetCode Auto-Push${NC}"
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Problem #  : ${BOLD}${PROBLEM_NUM}${NC}"
echo -e "  Name       : ${BOLD}${PROBLEM_NAME}${NC}"
echo -e "  File       : ${BOLD}${FOUND_FILE}${NC}"
echo -e "  Language   : ${BOLD}${LANG}${NC}"
echo -e "  Topic      : ${BOLD}${TOPIC}${NC}"
echo -e "  Difficulty : ${BOLD}${DIFFICULTY}${NC}"
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# ── Copy to solutions/topic/problem-slug/solution.ext ────────
DEST_DIR="solutions/${TOPIC}/${PROBLEM_SLUG}"
mkdir -p "$DEST_DIR"
DEST_FILE="${DEST_DIR}/solution.${EXT}"
cp "$FOUND_FILE" "$DEST_FILE"
echo -e "\n  Saved -> ${BOLD}${DEST_FILE}${NC}"

# ── Delete original file (keep repo clean) ───────────────────
rm -f "$FOUND_FILE"
echo -e "  Cleaned  -> removed ${BOLD}${FOUND_FILE}${NC} (copy is in solutions/)"

# ── Per-problem README ───────────────────────────────────────
PROBLEM_README="${DEST_DIR}/README.md"
if [ ! -f "$PROBLEM_README" ]; then
  LEETCODE_URL="https://leetcode.com/problems/${PROBLEM_SLUG}/"
  cat > "$PROBLEM_README" << EOF
# #${PROBLEM_NUM} — ${PROBLEM_NAME}

| Field      | Detail |
|------------|--------|
| Difficulty | ${DIFF_DISPLAY} |
| Topic      | ${TOPIC_DISPLAY} |
| Language   | ${LANG} |
| Date       | ${DATE} |
| Link       | [LeetCode](${LEETCODE_URL}) |

## Approach

_Describe your approach here._

## Complexity

| | |
|---|---|
| Time  | O(?) |
| Space | O(?) |
EOF
  echo -e "  Created  -> ${BOLD}${PROBLEM_README}${NC}"
fi

# ── Root README progress table ───────────────────────────────
ROOT_README="README.md"
if [ ! -f "$ROOT_README" ]; then
  cat > "$ROOT_README" << 'EOF'
# LeetCode Solutions

Auto-organized using [lp.sh](./lp.sh).

## Progress

| # | Problem | Topic | Difficulty | Language | Date |
|---|---------|-------|------------|----------|------|
EOF
fi

if grep -q "| #${PROBLEM_NUM} |" "$ROOT_README"; then
  echo -e "  Info: #${PROBLEM_NUM} already in README, skipping."
else
  PROBLEM_LINK="[${PROBLEM_NAME}](./${DEST_FILE})"
  printf "| #%s | %s | %s | %s | \`%s\` | %s |\n" \
    "$PROBLEM_NUM" "$PROBLEM_LINK" "$TOPIC_DISPLAY" "$DIFF_DISPLAY" "$LANG" "$DATE" >> "$ROOT_README"
  echo -e "  Updated  -> ${BOLD}README.md${NC}"
fi

# ── Git push ─────────────────────────────────────────────────
echo ""
echo -e "  Pushing to GitHub..."
git add .
git commit -m "#${PROBLEM_NUM}: ${PROBLEM_NAME} [${TOPIC}/${LANG}/${DIFFICULTY}]"
git push origin main

echo ""
echo -e "${GREEN}${BOLD}  Done! Pushed to GitHub.${NC}"
echo -e "  ${BOLD}solutions/${TOPIC}/${PROBLEM_SLUG}/solution.${EXT}${NC}"
echo ""
