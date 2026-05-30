import java.util.*;

public class Solution {
    public List<Integer> eventualSafeNodes(int[][] graph) {
        int n = graph.length;

        // Step 1: Build Reverse Graph
        List<List<Integer>> rev = new ArrayList<>();
        for (int i = 0; i < n; i++) rev.add(new ArrayList<>());

        int[] indegree = new int[n];

        for (int u = 0; u < n; u++) {
            for (int v : graph[u]) {
                rev.get(v).add(u);  // reverse edge v -> u
            }
            indegree[u] = graph[u].length; // outgoing edges count
        }

        // Step 2: Kahn’s BFS Queue (start with terminal nodes)
        Queue<Integer> q = new LinkedList<>();
        for (int i = 0; i < n; i++) {
            if (indegree[i] == 0) {
                q.add(i);
            }
        }

        boolean[] safe = new boolean[n];

        // Step 3: BFS processing
        while (!q.isEmpty()) {
            int x = q.poll();
            safe[x] = true;

            for (int parent : rev.get(x)) {// mtlb ye wo node h jispe koi aaye h so jo kewal usi pe aaya h wo node
                indegree[parent]--;
                if (indegree[parent] == 0) {
                    q.add(parent);
                }
            }
        }

        // Step 4: collect safe nodes
        List<Integer> ans = new ArrayList<>();
        for (int i = 0; i < n; i++) {
            if (safe[i]) ans.add(i);
        }

        return ans;
    }
}
