# 3940. Problem 3940

**Difficulty:** Medium &nbsp; | &nbsp; **Topic:** Other &nbsp; | &nbsp; **Language:** Java &nbsp; | &nbsp; **Date:** 2026-05-30

[View problem on LeetCode](https://leetcode.com/problems/problem-3940/)

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
class Solution {
    public int[] limitOccurrences(int[] nums, int k) {

        ArrayList<Integer> list = new ArrayList<>();

        int count = 1;

        list.add(nums[0]);

        for(int i=1;i<nums.length;i++){

            if(nums[i]==nums[i-1]){
                count++;
            }else{
                count=1;
            }
            if(count<=k){
                list.add(nums[i]);
            }
        }

        int[] ans=new int[list.size()];

        for(int i=0; i<list.size();i++){
            ans[i]=list.get(i);
        }
        return ans;
    }
}
```
