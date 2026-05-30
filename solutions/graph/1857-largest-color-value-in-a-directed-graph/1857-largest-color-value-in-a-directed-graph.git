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
