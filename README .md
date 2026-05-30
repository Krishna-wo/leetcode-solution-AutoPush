# LeetCode Solutions

A personal collection of LeetCode solutions, auto-organized by topic and pushed to GitHub using a shell script.

---

## How it works

Every time a problem is solved, one command handles everything:

```bash
./lp.sh 851
```

The script fetches the problem name from the LeetCode API, detects the topic from the code, organizes it into the right folder, generates a README for that problem, and pushes it to GitHub — all automatically.

---

## Setup (for first-time use or forking)

### 1. Fork this repository

Click **Fork** at the top right of this page. This creates your own copy under your GitHub account.

### 2. Clone your fork

```bash
git clone git@github.com:YOUR_USERNAME/leetcode-solution-AutoPush.git
cd leetcode-solution-AutoPush
```

### 3. Make the script executable

```bash
chmod +x lp.sh
```

### 4. Set up SSH authentication with GitHub (one time only)

```bash
# Generate an SSH key
ssh-keygen -t ed25519 -C "your@email.com"
# Press Enter three times to accept defaults

# Copy your public key
cat ~/.ssh/id_ed25519.pub
```

Go to GitHub → Settings → SSH and GPG Keys → New SSH key → paste it in.

Test it:
```bash
ssh -T git@github.com
# Expected: Hi YOUR_USERNAME! You've successfully authenticated...
```

Point your local repo to SSH:
```bash
git remote set-url origin git@github.com:YOUR_USERNAME/leetcode-solution-AutoPush.git
```

### 5. Solve a problem and push

```bash
# Create your solution file (just number + extension, no spaces)
nano 851.java

# Paste your code, then: Ctrl+X → Y → Enter

# Run the script
./lp.sh 851
```

That is the entire workflow.

---

## Naming your solution file

Always use: `PROBLEM_NUMBER.EXTENSION`

```
851.java
42.py
200.cpp
1.js
```

No spaces, no problem name needed in the filename. The script fetches the name automatically.

---

## Supported languages

| Extension | Language   |
|-----------|------------|
| .py       | Python     |
| .java     | Java       |
| .cpp      | C++        |
| .js       | JavaScript |
| .ts       | TypeScript |
| .go       | Go         |
| .rs       | Rust       |
| .c        | C          |
| .cs       | C#         |
| .kt       | Kotlin     |
| .swift    | Swift      |

---

## Folder structure

```
solutions/
    graph/
        851-loud-and-rich/
            851-loud-and-rich.java
            README.md
    tree/
        104-maximum-depth-of-binary-tree/
            104-maximum-depth-of-binary-tree.java
            README.md
    arrays/
    linkedlist/
    dp/
    other/
```

Each problem gets its own folder named `NUMBER-problem-slug` containing the solution file and a README with the problem details.

---

## Topic detection

The script reads your code and scores keywords to pick the right folder:

| Folder      | Detected from                                              |
|-------------|------------------------------------------------------------|
| graph       | bfs, dfs, graph, adjacency, topological, dijkstra          |
| tree        | TreeNode, root, inorder, preorder, postorder, trie, heap   |
| linkedlist  | ListNode, next, head, dummy, slow/fast pointer             |
| arrays      | sliding window, two pointer, prefix sum, subarray, nums    |
| dp          | dp, memo, cache, tabulation, knapsack, memoization         |
| other       | anything that does not match above                         |

To override auto-detection, add a comment anywhere in your solution:

```java
// topic: graph
```
```python
# topic: dp
```

---

## Difficulty

Difficulty is optional. The script fetches it from the LeetCode API automatically. You can override it:

```bash
./lp.sh 42 hard
./lp.sh 1 easy
```

---

## Progress

| # | Problem | Topic | Difficulty | Language | Date |
|---|---------|-------|------------|----------|------|
