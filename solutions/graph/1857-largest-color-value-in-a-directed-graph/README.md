# 1857. Largest Color Value in a Directed Graph

**Difficulty:** Hard &nbsp; | &nbsp; **Topic:** Graph &nbsp; | &nbsp; **Language:** Java &nbsp; | &nbsp; **Date:** 2026-05-30

[View problem on LeetCode](https://leetcode.com/problems/largest-color-value-in-a-directed-graph/)

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

```java
import java.util.*;

class Solution{
    ArrayList<ArrayList<Integer>>graph;
    int[][]dp;
    int[]vis;
    String colors;
    int n,ans=0;

    public int largestPathValue(String colors,int[][]edges){
        this.colors=colors;
        n=colors.length();

        graph=new ArrayList<>();
        for(int i=0;i<n;i++)graph.add(new ArrayList<>());

        for(int[]e:edges)graph.get(e[0]).add(e[1]);

        dp=new int[n][26];
        vis=new int[n];

        for(int i=0;i<n;i++){
            if(vis[i]==0){
                if(dfs(i))return-1;
            }
        }
        return ans;
    }

    boolean dfs(int node){
        vis[node]=1;

        for(int nbr:graph.get(node)){
            if(vis[nbr]==1)return true;

            if(vis[nbr]==0){
                if(dfs(nbr))return true;
            }

            for(int c=0;c<26;c++){
                dp[node][c]=Math.max(dp[node][c],dp[nbr][c]);
            }
        }

        int col=colors.charAt(node)-'a';
        dp[node][col]++;
        ans=Math.max(ans,dp[node][col]);

        vis[node]=2;
        return false;
    }
}
```
