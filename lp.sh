#!/bin/bash

# ================================================================
#  lp.sh — LeetCode Auto-Organizer & GitHub Pusher (Mac)
#
#  USAGE:
#    ./lp.sh 851              → fetches name from LeetCode API
#    ./lp.sh 851 hard         → with difficulty
# ================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

uppercase_first() {
  echo "$1" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}'
}

INPUT="$1"
DIFFICULTY_ARG="$2"

if [ -z "$INPUT" ]; then
  echo -e "${RED}Error: No input given.${NC}"
  echo ""
  echo "Usage:"
  echo "  ./lp.sh 851"
  echo "  ./lp.sh 851 hard"
  exit 1
fi

# ── Only mode: just a number ─────────────────────────────────
PROBLEM_NUM=$(echo "$INPUT" | grep -oE '^[0-9]+')

if [ -z "$PROBLEM_NUM" ]; then
  echo -e "${RED}Error: Please give a problem number. Example: ./lp.sh 851${NC}"
  exit 1
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

# ── Fetch problem name from LeetCode API ─────────────────────
echo -e "${CYAN}${BOLD}Fetching problem #${PROBLEM_NUM} from LeetCode...${NC}"

PROBLEM_SLUG=""
PROBLEM_NAME=""
API_DIFFICULTY=""

# Try the public LeetCode API
API_RESPONSE=$(curl -s --max-time 5 "https://leetcode-api-pied.vercel.app/problem/${PROBLEM_NUM}" 2>/dev/null || echo "")

if echo "$API_RESPONSE" | grep -q "titleSlug"; then
  PROBLEM_SLUG=$(echo "$API_RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('titleSlug',''))" 2>/dev/null || echo "")
  PROBLEM_NAME=$(echo "$API_RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('title',''))" 2>/dev/null || echo "")
  API_DIFFICULTY=$(echo "$API_RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('difficulty','').lower())" 2>/dev/null || echo "")
fi

# If API failed, try backup API
if [ -z "$PROBLEM_SLUG" ]; then
  API_RESPONSE2=$(curl -s --max-time 5 "https://alfa-leetcode-api.onrender.com/select?titleSlug=" 2>/dev/null || echo "")
  # Try fetching from problems list
  API_RESPONSE3=$(curl -s --max-time 8 "https://leetcode.com/api/problems/all/" 2>/dev/null || echo "")
  if echo "$API_RESPONSE3" | grep -q "question__title"; then
    PROBLEM_SLUG=$(echo "$API_RESPONSE3" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for p in data.get('stat_status_pairs', []):
    if str(p['stat']['frontend_question_id']) == '${PROBLEM_NUM}':
        print(p['stat']['question__title_slug'])
        break
" 2>/dev/null || echo "")
    PROBLEM_NAME=$(echo "$API_RESPONSE3" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for p in data.get('stat_status_pairs', []):
    if str(p['stat']['frontend_question_id']) == '${PROBLEM_NUM}':
        print(p['stat']['question__title'])
        break
" 2>/dev/null || echo "")
    API_DIFFICULTY=$(echo "$API_RESPONSE3" | python3 -c "
import sys, json
data = json.load(sys.stdin)
levels = {1:'easy', 2:'medium', 3:'hard'}
for p in data.get('stat_status_pairs', []):
    if str(p['stat']['frontend_question_id']) == '${PROBLEM_NUM}':
        print(levels.get(p['difficulty']['level'], 'medium'))
        break
" 2>/dev/null || echo "")
  fi
fi

# Use API difficulty only if user didn't provide one
if [ -n "$API_DIFFICULTY" ] && [ -z "$DIFFICULTY_ARG" ]; then
  DIFFICULTY="$API_DIFFICULTY"
fi

# If still no name, fallback to "problem-NUMBER"
if [ -z "$PROBLEM_SLUG" ]; then
  echo -e "${YELLOW}⚠️  Could not fetch from LeetCode API. Using problem number as name.${NC}"
  PROBLEM_SLUG="problem-${PROBLEM_NUM}"
  PROBLEM_NAME="Problem ${PROBLEM_NUM}"
else
  echo -e "${GREEN}✓ Found: ${PROBLEM_NAME}${NC}"
fi

# ── Find solution file by number ─────────────────────────────
FOUND_FILE=""

# Search for any file starting with the problem number
for f in "${PROBLEM_NUM}".* "${PROBLEM_NUM}"-* "${PROBLEM_NUM}"_*; do
  [ -f "$f" ] || continue
  # Skip non-code files and files with no/empty extension
  case "$f" in
    *.md|*.sh|*.txt) continue ;;
  esac
  EXT_CHECK="${f##*.}"
  # Skip if no real extension (e.g. "851." has empty ext)
  if [ -z "$EXT_CHECK" ] || [ "$EXT_CHECK" = "$f" ] || [ ${#EXT_CHECK} -gt 10 ]; then
    continue
  fi
  FOUND_FILE="$f"
  break
done

if [ -z "$FOUND_FILE" ]; then
  echo -e "${RED}Error: No solution file found for problem #${PROBLEM_NUM}${NC}"
  echo ""
  echo -e "Create your file first (just number + extension):"
  echo -e "  ${BOLD}nano ${PROBLEM_NUM}.java${NC}"
  echo -e "  ${BOLD}nano ${PROBLEM_NUM}.py${NC}"
  echo -e "  ${BOLD}nano ${PROBLEM_NUM}.cpp${NC}"
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
  *)     LANG=$(echo "$EXT" | awk '{print toupper($0)}') ;;
esac

DATE=$(date +%Y-%m-%d)
FILE_CONTENT=$(cat "$FOUND_FILE" | awk '{print tolower($0)}')

# ── Topic Detection ──────────────────────────────────────────
detect_topic() {
  local content="$1"

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

  echo "$content" | grep -qE '\bgraph\b'          && G=$((G+3))
  echo "$content" | grep -qE '\bbfs\b'            && G=$((G+3))
  echo "$content" | grep -qE '\bdfs\b'            && G=$((G+3))
  echo "$content" | grep -qE '\badjacency\b'      && G=$((G+3))
  echo "$content" | grep -qE '\btopological\b'    && G=$((G+3))
  echo "$content" | grep -qE '\bdijkstra\b'       && G=$((G+3))
  echo "$content" | grep -qE '\bunion.find\b'     && G=$((G+2))
  echo "$content" | grep -qE '\bvisited\b'        && G=$((G+1))
  echo "$content" | grep -qE '\bneighbor\b'       && G=$((G+2))

  echo "$content" | grep -qE '\btreenode\b'       && T=$((T+4))
  echo "$content" | grep -qE '\btree\b'           && T=$((T+2))
  echo "$content" | grep -qE '\broot\b'           && T=$((T+3))
  echo "$content" | grep -qE '\binorder\b'        && T=$((T+3))
  echo "$content" | grep -qE '\bpreorder\b'       && T=$((T+3))
  echo "$content" | grep -qE '\bpostorder\b'      && T=$((T+3))
  echo "$content" | grep -qE '\bheap\b'           && T=$((T+2))
  echo "$content" | grep -qE '\btrie\b'           && T=$((T+3))

  echo "$content" | grep -qE '\blistnode\b'       && L=$((L+4))
  echo "$content" | grep -qE '\blinkedlist\b'     && L=$((L+3))
  echo "$content" | grep -qE '\bnext\b'           && L=$((L+2))
  echo "$content" | grep -qE '\bhead\b'           && L=$((L+2))
  echo "$content" | grep -qE '\bdummy\b'          && L=$((L+2))
  echo "$content" | grep -qE '\bslow\b'           && L=$((L+1))
  echo "$content" | grep -qE '\bfast\b'           && L=$((L+1))

  echo "$content" | grep -qE '\bsliding.window\b' && A=$((A+4))
  echo "$content" | grep -qE '\btwo.pointer\b'    && A=$((A+4))
  echo "$content" | grep -qE '\bprefix.sum\b'     && A=$((A+4))
  echo "$content" | grep -qE '\bsubarray\b'       && A=$((A+3))
  echo "$content" | grep -qE '\barray\b'          && A=$((A+2))
  echo "$content" | grep -qE '\bnums\b'           && A=$((A+2))
  echo "$content" | grep -qE '\bbinary.search\b'  && A=$((A+2))

  echo "$content" | grep -qE '\bmemoization\b'    && D=$((D+4))
  echo "$content" | grep -qE '\btabulation\b'     && D=$((D+4))
  echo "$content" | grep -qE '\bknapsack\b'       && D=$((D+4))
  echo "$content" | grep -qE '\bsubproblem\b'     && D=$((D+3))
  echo "$content" | grep -qE '\bdp\b'             && D=$((D+3))
  echo "$content" | grep -qE '\bmemo\b'           && D=$((D+2))
  echo "$content" | grep -qE '\bcache\b'          && D=$((D+2))
  echo "$content" | grep -qE '\blongest\b'        && D=$((D+1))
  echo "$content" | grep -qE '\bfibonacci\b'      && D=$((D+2))

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

# ── Destination: solutions/topic/851-loud-and-rich/ ──────────
FOLDER_NAME="${PROBLEM_NUM}-${PROBLEM_SLUG}"
DEST_DIR="solutions/${TOPIC}/${FOLDER_NAME}"
mkdir -p "$DEST_DIR"

# Save as original filename e.g. 851-loud-and-rich.java
DEST_FILE="${DEST_DIR}/${FOLDER_NAME}.${EXT}"
cp "$FOUND_FILE" "$DEST_FILE"
echo -e "\n  Saved   -> ${BOLD}${DEST_FILE}${NC}"

# Delete original loose file from root
rm -f "$FOUND_FILE"
echo -e "  Cleaned -> removed ${BOLD}${FOUND_FILE}${NC}"

# ── Per-problem README ───────────────────────────────────────
PROBLEM_README="${DEST_DIR}/README.md"
if [ ! -f "$PROBLEM_README" ]; then
  LEETCODE_URL="https://leetcode.com/problems/${PROBLEM_SLUG}/"
  cat > "$PROBLEM_README" << EOF
# ${PROBLEM_NUM}. ${PROBLEM_NAME}

**Difficulty:** ${DIFF_DISPLAY} &nbsp; | &nbsp; **Topic:** ${TOPIC_DISPLAY} &nbsp; | &nbsp; **Language:** ${LANG} &nbsp; | &nbsp; **Date:** ${DATE}

[View problem on LeetCode](${LEETCODE_URL})

---

## Problem Summary

<!-- Paste a short description of the problem here -->

---

## Approach

<!-- Explain your thinking:
     - What data structure or algorithm did you use?
     - Why did you choose this approach?
     - Any edge cases to watch out for? -->

---

## Complexity

| | Complexity | Notes |
|---|---|---|
| Time  | O(?) | |
| Space | O(?) | |

---

## Code

\`\`\`${EXT}
$(cat "$FOUND_FILE" 2>/dev/null || cat "${DEST_DIR}/${FOLDER_NAME}.${EXT}")
\`\`\`
EOF
  echo -e "  Created -> ${BOLD}${PROBLEM_README}${NC}"
fi

# ── Root README ──────────────────────────────────────────────
ROOT_README="README.md"
if [ ! -f "$ROOT_README" ]; then
  cat > "$ROOT_README" << 'EOF'
# LeetCode Solutions

A personal collection of LeetCode solutions, auto-organized by topic using [lp.sh](./lp.sh).

---

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
  echo -e "  Updated -> ${BOLD}README.md${NC}"
fi

# ── Git push ─────────────────────────────────────────────────
echo ""
echo -e "  Pushing to GitHub..."
git add .
git commit -m "#${PROBLEM_NUM}: ${PROBLEM_NAME} [${TOPIC}/${LANG}/${DIFFICULTY}]"
git push origin main

echo ""
echo -e "${GREEN}${BOLD}  Done! Pushed to GitHub.${NC}"
echo -e "  ${BOLD}${DEST_FILE}${NC}"
echo ""
