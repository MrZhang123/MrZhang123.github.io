---
title: Roman To Int
date: 2019-07-16
tags: leetCode
comments: true
categories: "leetCode"
---
### 题目

罗马数字使用七个不同的符号表示：`I`，`V`，`X`，`L`，`C`，`D`和`M`。

```
Symbol     Value
I          1
V          5
X          10
L          50
C          100
D          500
M          1000
```
例如，罗马数字`II`表示2，就是将两个1加在一起。12被写作`XII`。27被写作`XXVII`，就是`XX`+`V`+`II`。

罗马数字通常从左到右，从最大到最小。然而，数字4不是`IIII`。而是`IV`。因为1写到5前面得到4，相同的原理，9被表示成`IX`。这里有6个使用剑法的例子🌰：

* `I`放在`V`(5)和`X`(10)前面表示4和9
* `X`放在`L`(50)和`C`(100)前面表示40和90
* `I`放在`V`(500)和`X`(1000)前面表示400和900

给定一个罗马数字，转换成整数。输入保证在1到3999。

Example1

```
Input: "III"
Output: 3

Input: "IV"
Output: 4

Input: "IX"
Output: 9

Input: "LVIII"
Output: 58
Explanation: L = 50, V= 5, III = 3.

Input: "MCMXCIV"
Output: 1994
Explanation: M = 1000, CM = 900, XC = 90 and IV = 4.
```
**难度：Easy**

### 思路

1. 使用了JS的Map，生成有序的罗马数字和整数的对应关系
2. 将输入的字符串使用`String.prototype.split()`将每个字母转换成数组的元素。
3. 遍历数组，从Map中拿对应关系，这里使用两个相邻元素A,B对应的数字NA和NB比较，如果`NA<NB`小，`result - NA`，否则`result + NB`。

### 代码实现

```js
/**
 * @param {string} s
 * @return {number}
 */
/*
{
    'I' => 1,
    'V' => 5,
    'X' => 10,
    'L' => 50,
    'C' => 100,
    'D' => 500,
    'M' => 1000
}
*/
var romanList = [
    {name: 'M', value: 1000},
    {name: 'D', value: 500},
    {name: 'C', value: 100},
    {name: 'L', value: 50},
    {name: 'X', value: 10},
    {name: 'V', value: 5},
    {name: 'I', value: 1}
]
var getRomanMap = (s) => {
    const mapData = new Map();
    romanList.forEach(v => {
        mapData.set(v.name, v.value);
    });
    console.log(mapData);
    return mapData;
}
var romanToInt = function(s) {
    const romanMap = getRomanMap(s);
    const strArr = s.split('');
    let result = 0;
    let nowData = 0;
    let next = 0;
    for(let i = 0; i < strArr.length; i++) {
        nowData = romanMap.get(strArr[i]);
        next = romanMap.get(strArr[i + 1]);
        if (nowData < next) {
            result -= nowData;
        } else {
            result += nowData;
        }
    }
    console.log(result);
    return result;
};
```
