#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

INPUT="$1"
DIFFICULTY_ARG="$2"

if [ -z "$INPUT" ]; then
  echo -e "${RED}Error: No input given.${NC}"
  echo ""
  echo -e "${BOLD}Usage examples:${NC}"
  echo '  ./leet-push.sh "[3940. Limit Occurrences](https://leetcode.com/problems/limit-occurrences-in-sorted-array/)"'
  echo '  ./leet-push.sh 42'
  echo '  ./leet-push.sh 42 hard'
  echo '  ./leet-push.sh "42 trapping rain water"'
  exit 1
fi

PROBLEM_NUM=""
PROBLEM_NAME=""
PROBLEM_SLUG=""
DIFFICULTY=""

if echo "$INPUT" | grep -qE '^\[.*\]\(https://leetcode\.com'; then
  PROBLEM_NUM=$(echo "$INPUT" | grep -oE '^\[[0-9]+' | grep -oE '[0-9]+')
  PROBLEM_NAME=$(echo "$INPUT" | sed 's/^\[//' | sed 's/\](.*$//' | sed "s/^${PROBLEM_NUM}\. //")
  PROBLEM_SLUG=$(echo "$INPUT" | grep -oE 'problems/[^/]+' | sed 's/problems\///')

  if [ -z "$PROBLEM_SLUG" ]; then
    PROBLEM_SLUG=$(echo "$PROBLEM_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
  fi

  echo -e "${CYAN}${BOLD}Detected from LeetCode link${NC}"

elif echo "$INPUT" | grep -qE '^[0-9]+$'; then
  PROBLEM_NUM="$INPUT"
  PROBLEM_NAME=""
  PROBLEM_SLUG=""
  echo -e "${CYAN}${BOLD}Searching by problem number: ${PROBLEM_NUM}${NC}"

else
  PROBLEM_NUM=$(echo "$INPUT" | grep -oE '^[0-9]+')
  PROBLEM_NAME=$(echo "$INPUT" | sed "s/^${PROBLEM_NUM}[[:space:]]*//" | sed 's/^[ -]*//')
  PROBLEM_SLUG=$(echo "$PROBLEM_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
  echo -e "${CYAN}${BOLD}Manual input mode${NC}"
fi

if [ -n "$DIFFICULTY_ARG" ]; then
  DIFFICULTY=$(echo "$DIFFICULTY_ARG" | tr '[:upper:]' '[:lower:]')
else
  DIFFICULTY="medium"
fi

if [[ ! "$DIFFICULTY" =~ ^(easy|medium|hard)$ ]]; then
  echo -e "${YELLOW}Warning: Unknown difficulty '${DIFFICULTY}', defaulting to medium${NC}"
  DIFFICULTY="medium"
fi

FOUND_FILE=""

for pattern in \
  "${PROBLEM_NUM}-"* \
  "${PROBLEM_NUM}_"* \
  "${PROBLEM_NUM}."* \
  "${PROBLEM_NUM} "*; do
  for f in $pattern; do
    if [ -f "$f" ]; then
      case "$f" in
        *.md|*.sh|*.txt) continue ;;
      esac
      FOUND_FILE="$f"
      break 2
    fi
  done
done

if [ -z "$FOUND_FILE" ]; then
  echo -e "${RED}Error: No solution file found for problem #${PROBLEM_NUM}${NC}"
  echo ""
  echo -e "  Create your file as any of:"
  echo -e "  ${BOLD}${PROBLEM_NUM}-problem-name.py${NC}"
  echo -e "  ${BOLD}${PROBLEM_NUM}.py${NC}"
  echo -e "  ${BOLD}${PROBLEM_NUM}.cpp${NC}"
  echo -e "  ${BOLD}${PROBLEM_NUM}.java${NC}  etc."
  exit 1
fi

EXT="${FOUND_FILE##*.}"
EXT=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')

case "$EXT" in
  py)   LANG="Python" ;;
  cpp)  LANG="C++" ;;
  java) LANG="Java" ;;
  js)   LANG="JavaScript" ;;
  ts)   LANG="TypeScript" ;;
  go)   LANG="Go" ;;
  rs)   LANG="Rust" ;;
  c)    LANG="C" ;;
  cs)   LANG="C#" ;;
  rb)   LANG="Ruby" ;;
  kt)   LANG="Kotlin" ;;
  swift)LANG="Swift" ;;
  *)    LANG="$EXT" ;;
esac

if [ -z "$PROBLEM_NAME" ]; then
  RAW=$(basename "$FOUND_FILE")
  RAW=$(echo "$RAW" | sed "s/^${PROBLEM_NUM}[-_. ]*//" | sed "s/\.${EXT}$//")
  if [ -n "$RAW" ]; then
    PROBLEM_NAME=$(echo "$RAW" | tr '-_' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')
    PROBLEM_SLUG=$(echo "$RAW" | tr '[:upper:]' '[:lower:]' | tr '_' '-')
  else
    PROBLEM_NAME="Problem ${PROBLEM_NUM}"
    PROBLEM_SLUG="problem-${PROBLEM_NUM}"
  fi
fi

DATE=$(date +%Y-%m-%d)
FILE_CONTENT=$(cat "$FOUND_FILE" | tr '[:upper:]' '[:lower:]')

detect_topic() {
  local content="$1"

  EXPLICIT=$(echo "$content" | grep -oE 'topic\s*:\s*[a-z]+' | head -1 | grep -oE '[a-z]+$')
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
  echo "$content" | grep -qE '\b dp\b|\bdp\[' "$FOUND_FILE" 2>/dev/null && D=$((D+3))
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

echo ""
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}${BOLD}  LeetCode Auto-Push${NC}"
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Problem #  : ${BOLD}${PROBLEM_NUM}${NC}"
echo -e "  Name       : ${BOLD}${PROBLEM_NAME}${NC}"
echo -e "  File found : ${BOLD}${FOUND_FILE}${NC}"
echo -e "  Language   : ${BOLD}${LANG}${NC}"
echo -e "  Topic      : ${BOLD}${TOPIC}${NC}"
echo -e "  Difficulty : ${BOLD}${DIFFICULTY}${NC}"
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

DEST_DIR="solutions/${TOPIC}/${PROBLEM_SLUG}"
mkdir -p "$DEST_DIR"

DEST_FILE="${DEST_DIR}/solution.${EXT}"
cp "$FOUND_FILE" "$DEST_FILE"
echo -e "\n  Saved -> ${BOLD}${DEST_FILE}${NC}"

PROBLEM_README="${DEST_DIR}/README.md"
if [ ! -f "$PROBLEM_README" ]; then
  LEETCODE_URL="https://leetcode.com/problems/${PROBLEM_SLUG}/"
  cat > "$PROBLEM_README" << EOF
# #${PROBLEM_NUM} — ${PROBLEM_NAME}

| Field      | Detail |
|------------|--------|
| Difficulty | ${DIFFICULTY^} |
| Topic      | ${TOPIC^} |
| Language   | ${LANG} |
| Date       | ${DATE} |
| Link       | [LeetCode](${LEETCODE_URL}) |

## Problem

> [View on LeetCode](${LEETCODE_URL})

## Approach

_Describe your approach here._

## Complexity

| | |
|---|---|
| Time  | O(?) |
| Space | O(?) |
EOF
  echo -e "  Created -> ${BOLD}${PROBLEM_README}${NC}"
fi

ROOT_README="README.md"
if [ ! -f "$ROOT_README" ]; then
  cat > "$ROOT_README" << 'EOF'
# LeetCode Solutions

Auto-organized and pushed using [leet-push.sh](./leet-push.sh).

## Progress

| # | Problem | Topic | Difficulty | Language | Date |
|---|---------|-------|------------|----------|------|
EOF
fi

if grep -q "| #${PROBLEM_NUM} |" "$ROOT_README"; then
  echo -e "  Info: Problem #${PROBLEM_NUM} already in README — skipping."
else
  PROBLEM_LINK="[${PROBLEM_NAME}](./${DEST_DIR}/solution.${EXT})"
  echo "| #${PROBLEM_NUM} | ${PROBLEM_LINK} | ${TOPIC^} | ${DIFFICULTY^} | \`${LANG}\` | ${DATE} |" >> "$ROOT_README"
  echo -e "  Updated -> ${BOLD}README.md${NC}"
fi

echo ""
echo -e "  Pushing to GitHub..."
git add .
git commit -m "#${PROBLEM_NUM}: ${PROBLEM_NAME} [${TOPIC}/${LANG}/${DIFFICULTY}]"
git push origin main

echo ""
echo -e "${GREEN}${BOLD}  Done! Pushed to GitHub.${NC}"
echo -e "  Location: ${BOLD}solutions/${TOPIC}/${PROBLEM_SLUG}/solution.${EXT}${NC}"
echo ""#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

INPUT="$1"
DIFFICULTY_ARG="$2"

if [ -z "$INPUT" ]; then
  echo -e "${RED}Error: No input given.${NC}"
  echo ""
  echo -e "${BOLD}Usage examples:${NC}"
  echo '  ./leet-push.sh "[3940. Limit Occurrences](https://leetcode.com/problems/limit-occurrences-in-sorted-array/)"'
  echo '  ./leet-push.sh 42'
  echo '  ./leet-push.sh 42 hard'
  echo '  ./leet-push.sh "42 trapping rain water"'
  exit 1
fi

PROBLEM_NUM=""
PROBLEM_NAME=""
PROBLEM_SLUG=""
DIFFICULTY=""

if echo "$INPUT" | grep -qE '^\[.*\]\(https://leetcode\.com'; then
  PROBLEM_NUM=$(echo "$INPUT" | grep -oE '^\[[0-9]+' | grep -oE '[0-9]+')
  PROBLEM_NAME=$(echo "$INPUT" | sed 's/^\[//' | sed 's/\](.*$//' | sed "s/^${PROBLEM_NUM}\. //")
  PROBLEM_SLUG=$(echo "$INPUT" | grep -oE 'problems/[^/]+' | sed 's/problems\///')

  if [ -z "$PROBLEM_SLUG" ]; then
    PROBLEM_SLUG=$(echo "$PROBLEM_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
  fi

  echo -e "${CYAN}${BOLD}Detected from LeetCode link${NC}"

elif echo "$INPUT" | grep -qE '^[0-9]+$'; then
  PROBLEM_NUM="$INPUT"
  PROBLEM_NAME=""
  PROBLEM_SLUG=""
  echo -e "${CYAN}${BOLD}Searching by problem number: ${PROBLEM_NUM}${NC}"

else
  PROBLEM_NUM=$(echo "$INPUT" | grep -oE '^[0-9]+')
  PROBLEM_NAME=$(echo "$INPUT" | sed "s/^${PROBLEM_NUM}[[:space:]]*//" | sed 's/^[ -]*//')
  PROBLEM_SLUG=$(echo "$PROBLEM_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
  echo -e "${CYAN}${BOLD}Manual input mode${NC}"
fi

if [ -n "$DIFFICULTY_ARG" ]; then
  DIFFICULTY=$(echo "$DIFFICULTY_ARG" | tr '[:upper:]' '[:lower:]')
else
  DIFFICULTY="medium"
fi

if [[ ! "$DIFFICULTY" =~ ^(easy|medium|hard)$ ]]; then
  echo -e "${YELLOW}Warning: Unknown difficulty '${DIFFICULTY}', defaulting to medium${NC}"
  DIFFICULTY="medium"
fi

FOUND_FILE=""

for pattern in \
  "${PROBLEM_NUM}-"* \
  "${PROBLEM_NUM}_"* \
  "${PROBLEM_NUM}."* \
  "${PROBLEM_NUM} "*; do
  for f in $pattern; do
    if [ -f "$f" ]; then
      case "$f" in
        *.md|*.sh|*.txt) continue ;;
      esac
      FOUND_FILE="$f"
      break 2
    fi
  done
done

if [ -z "$FOUND_FILE" ]; then
  echo -e "${RED}Error: No solution file found for problem #${PROBLEM_NUM}${NC}"
  echo ""
  echo -e "  Create your file as any of:"
  echo -e "  ${BOLD}${PROBLEM_NUM}-problem-name.py${NC}"
  echo -e "  ${BOLD}${PROBLEM_NUM}.py${NC}"
  echo -e "  ${BOLD}${PROBLEM_NUM}.cpp${NC}"
  echo -e "  ${BOLD}${PROBLEM_NUM}.java${NC}  etc."
  exit 1
fi

EXT="${FOUND_FILE##*.}"
EXT=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')

case "$EXT" in
  py)   LANG="Python" ;;
  cpp)  LANG="C++" ;;
  java) LANG="Java" ;;
  js)   LANG="JavaScript" ;;
  ts)   LANG="TypeScript" ;;
  go)   LANG="Go" ;;
  rs)   LANG="Rust" ;;
  c)    LANG="C" ;;
  cs)   LANG="C#" ;;
  rb)   LANG="Ruby" ;;
  kt)   LANG="Kotlin" ;;
  swift)LANG="Swift" ;;
  *)    LANG="$EXT" ;;
esac

if [ -z "$PROBLEM_NAME" ]; then
  RAW=$(basename "$FOUND_FILE")
  RAW=$(echo "$RAW" | sed "s/^${PROBLEM_NUM}[-_. ]*//" | sed "s/\.${EXT}$//")
  if [ -n "$RAW" ]; then
    PROBLEM_NAME=$(echo "$RAW" | tr '-_' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')
    PROBLEM_SLUG=$(echo "$RAW" | tr '[:upper:]' '[:lower:]' | tr '_' '-')
  else
    PROBLEM_NAME="Problem ${PROBLEM_NUM}"
    PROBLEM_SLUG="problem-${PROBLEM_NUM}"
  fi
fi

DATE=$(date +%Y-%m-%d)
FILE_CONTENT=$(cat "$FOUND_FILE" | tr '[:upper:]' '[:lower:]')

detect_topic() {
  local content="$1"

  EXPLICIT=$(echo "$content" | grep -oE 'topic\s*:\s*[a-z]+' | head -1 | grep -oE '[a-z]+$')
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
  echo "$content" | grep -qE '\b dp\b|\bdp\[' "$FOUND_FILE" 2>/dev/null && D=$((D+3))
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

echo ""
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}${BOLD}  LeetCode Auto-Push${NC}"
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Problem #  : ${BOLD}${PROBLEM_NUM}${NC}"
echo -e "  Name       : ${BOLD}${PROBLEM_NAME}${NC}"
echo -e "  File found : ${BOLD}${FOUND_FILE}${NC}"
echo -e "  Language   : ${BOLD}${LANG}${NC}"
echo -e "  Topic      : ${BOLD}${TOPIC}${NC}"
echo -e "  Difficulty : ${BOLD}${DIFFICULTY}${NC}"
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

DEST_DIR="solutions/${TOPIC}/${PROBLEM_SLUG}"
mkdir -p "$DEST_DIR"

DEST_FILE="${DEST_DIR}/solution.${EXT}"
cp "$FOUND_FILE" "$DEST_FILE"
echo -e "\n  Saved -> ${BOLD}${DEST_FILE}${NC}"

PROBLEM_README="${DEST_DIR}/README.md"
if [ ! -f "$PROBLEM_README" ]; then
  LEETCODE_URL="https://leetcode.com/problems/${PROBLEM_SLUG}/"
  cat > "$PROBLEM_README" << EOF
# #${PROBLEM_NUM} — ${PROBLEM_NAME}

| Field      | Detail |
|------------|--------|
| Difficulty | ${DIFFICULTY^} |
| Topic      | ${TOPIC^} |
| Language   | ${LANG} |
| Date       | ${DATE} |
| Link       | [LeetCode](${LEETCODE_URL}) |

## Problem

> [View on LeetCode](${LEETCODE_URL})

## Approach

_Describe your approach here._

## Complexity

| | |
|---|---|
| Time  | O(?) |
| Space | O(?) |
EOF
  echo -e "  Created -> ${BOLD}${PROBLEM_README}${NC}"
fi

ROOT_README="README.md"
if [ ! -f "$ROOT_README" ]; then
  cat > "$ROOT_README" << 'EOF'
# LeetCode Solutions

Auto-organized and pushed using [leet-push.sh](./leet-push.sh).

## Progress

| # | Problem | Topic | Difficulty | Language | Date |
|---|---------|-------|------------|----------|------|
EOF
fi

if grep -q "| #${PROBLEM_NUM} |" "$ROOT_README"; then
  echo -e "  Info: Problem #${PROBLEM_NUM} already in README — skipping."
else
  PROBLEM_LINK="[${PROBLEM_NAME}](./${DEST_DIR}/solution.${EXT})"
  echo "| #${PROBLEM_NUM} | ${PROBLEM_LINK} | ${TOPIC^} | ${DIFFICULTY^} | \`${LANG}\` | ${DATE} |" >> "$ROOT_README"
  echo -e "  Updated -> ${BOLD}README.md${NC}"
fi

echo ""
echo -e "  Pushing to GitHub..."
git add .
git commit -m "#${PROBLEM_NUM}: ${PROBLEM_NAME} [${TOPIC}/${LANG}/${DIFFICULTY}]"
git push origin main

echo ""
echo -e "${GREEN}${BOLD}  Done! Pushed to GitHub.${NC}"
echo -e "  Location: ${BOLD}solutions/${TOPIC}/${PROBLEM_SLUG}/solution.${EXT}${NC}"
echo ""
