---
title: 「译」稳定的Array.prototype.sort
date: 2019-07-08 23:10:00
tags:
  - JavaScript
categories:
  - JavaScript
draft: false
---

原文链接：https://v8.dev/features/stable-sort#support

假设你有一系列的狗狗，每个狗狗有名字和评分。（如果这个例子看起来很奇怪，你应该知道有一个专门针对这个的Twitter账户...别问为什么！）
<!--more-->
```js
// Note:按字母顺序进行预排序
const doggos = [
  { name: 'Abby',   rating: 12 },
  { name: 'Bandit', rating: 13 },
  { name: 'Choco',  rating: 14 },
  { name: 'Daisy',  rating: 12 },
  { name: 'Elmo',   rating: 12 },
  { name: 'Falco',  rating: 13 },
  { name: 'Ghost',  rating: 14 },
];
// 按照`rating`把狗狗进行降序排序
// （这会更新doggos）
doggos.sort((a, b) => b.rating - a.rating);
```
数据按照字母顺序与排序。为了按照评分排序（所以我们首先得到评分最高的狗狗），我们使用`Array#sort`，传递一个比较评分的自定义回调。排序后的结果如下：

```js
[
  { name: 'Choco',  rating: 14 },
  { name: 'Ghost',  rating: 14 },
  { name: 'Bandit', rating: 13 },
  { name: 'Falco',  rating: 13 },
  { name: 'Abby',   rating: 12 },
  { name: 'Daisy',  rating: 12 },
  { name: 'Elmo',   rating: 12 },
]
```
狗狗按照评分排序，但是在每个评分内，它们依然按照名字的字母的顺序排序。例如，Choco和Ghost的评分都是14，但是在排序结果中Choco在Ghost的前面，因为这也是它们在原始数据中的顺序。

但是要得到这个结果，JavaScript引擎不能只使用任何排序算法——排序算法必须是“稳定的排序”。很长时间里，JavaScript规范并不要求`Array#sort`进行排序的稳定性，而是将其留给实现过程。因为这种行为没有具体说明，所以你可能得到的Ghost排在Choco前面的排序结果。

```js
[
  { name: 'Ghost',  rating: 14 }, // 😢
  { name: 'Choco',  rating: 14 }, // 😢
  { name: 'Bandit', rating: 13 },
  { name: 'Falco',  rating: 13 },
  { name: 'Abby',   rating: 12 },
  { name: 'Daisy',  rating: 12 },
  { name: 'Elmo',   rating: 12 },
]
```

换句话说，JavaScript开发者不能依赖排序的稳定性。在实践中，情况可能更令人愤怒，因为有些JavaScript引擎对短数组进行稳定排序而对长数组进行不稳定排序。这让人非常困惑，开发者在测试他们的代码时候，看到的是稳定的排序，但是当数组略大的时候，突然在生产环境中获得不稳定排序的结果。

但是有一些好消息。我们[提出规范变更](https://github.com/tc39/ecma262/pull/1340)，让`Array#sort`变得稳定，并且被接受。现在，所有的JavaScript主流引擎都实现了稳定的`Array#sort`。作为开发人员，只需要担心一件事情，太好了！

（我们做了同样的事情为`TypedArrays`：它的sort现在也稳定了）

>尽管现在每个规范都要求稳定，JavaScript引擎依然可以自由的实现它们想要的排序算法。例如[V8使用的Timsort](https://v8.dev/blog/array-sort#timsort)。该规范并不要求任何特定的排序算法。

译者注：
Timsort算法是非常有名的一个算法，在保证高性能的同时还能保证性能稳定。
TimSort的设计思路很新颖（当然也可能借鉴了其他算法）：既然单个算法会遇到最好情况和最差情况导致性能不稳定，那么是不是可以先分析数组特征，然后扬长避短在多种算法中选取合适的算法进行排序呢？
所以实际上TimSort是多种排序算法+分块算法+翻转，是一种“混合排序算法调度算法”。
有很多语言引擎默认使用TimSort作为原生排序算法，如Python（2.3开始）、Java SE 7、Android platform、GNU Octave。

## 特性支持

### 稳定的`Array.prototype.sort`

* [Chrome 70+](https://v8.dev/blog/v8-release-70#javascript-language-features)
* Firefox混合支持
* Safari混合支持
* [Node 12+](https://twitter.com/mathias/status/1120700101637353473)
* ~~Babel~~

### 稳定的`%TypedArray%.prototype.sort`

* [Chrome 74+](https://bugs.chromium.org/p/v8/issues/detail?id=8567)
* [Firefox 67+](https://bugzilla.mozilla.org/show_bug.cgi?id=1290554)
* Safari混合支持
* [Node 12+](https://twitter.com/mathias/status/1120700101637353473)
* ~~Babel~~
