# 787. Cheapest Flights Within K Stops

**Difficulty:** Medium &nbsp; | &nbsp; **Topic:** Graph &nbsp; | &nbsp; **Language:** Java &nbsp; | &nbsp; **Date:** 2026-05-30

[View problem on LeetCode](https://leetcode.com/problems/cheapest-flights-within-k-stops/)

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

class Solution {
    public int findCheapestPrice(int n, int[][] flights, int src, int dst, int k) {
        List<List<int[]>> graph = new ArrayList<>();
        for (int i = 0; i < n; i++) graph.add(new ArrayList<>());
        for (int[] f : flights) {
            int from = f[0], to = f[1], wt = f[2];
            graph.get(from).add(new int[]{to, wt});
        }

        // stops, node, cost
        Queue<int[]> q = new LinkedList<>();
        q.offer(new int[]{0, src, 0});
        int[] dist = new int[n];
        Arrays.fill(dist, Integer.MAX_VALUE);
        dist[src] = 0;
        // bfs + relaxation
        while (!q.isEmpty()) {
            int[] curr = q.poll();

            int stops = curr[0];
            int node = curr[1];
            int cost = curr[2];

            //  skip (not break)
            if (stops > k) continue;

            for (int[] nbr : graph.get(node)) {
                int nextNode = nbr[0];
                int wt = nbr[1];

                int newCost = cost + wt;

                if (newCost < dist[nextNode]) {
                    dist[nextNode] = newCost;
                    q.offer(new int[]{stops + 1, nextNode, newCost});
                }
            }
        }

        return dist[dst] == Integer.MAX_VALUE ? -1 : dist[dst];
    }
}
```
