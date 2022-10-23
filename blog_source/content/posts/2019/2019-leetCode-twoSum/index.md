---
title: Two Sum
date: 2019-07-16
tags:
  - leetCode
categories:
  - leetCode
draft: false
---
### 题目

给定一个整数数组，返回两个数的索引，这两个数相加等于特定的目标。

你可以假定每次输入只有一个解决方案，并且你不会使用相同的元素两次。
<!--more-->
Example：

```js
Given nums = [2, 7, 11, 15], target = 9,

Because nums[0] + nums[1] = 2 + 7 = 9,
return [0, 1].
```

**难度：Easy**

### 思路

题目要求在数组中寻找两个数A和B，相加等于一个特定的数traget，返回A和B的索引，**我们可以用给定的数traget减去A，看B是否存在于数组中即可**。

### 代码实现

```js
/**
 * @param {number[]} nums
 * @param {number} target
 * @return {number[]}
 */
var twoSum = function(nums, target) {
    for(let i = 0; i < nums.length; i++) {
        let result = target - nums[i];
        let key = nums.indexOf(result);
        if (key !== -1 && i !== key) {
            return [i, key];
        }
    }
};
```

