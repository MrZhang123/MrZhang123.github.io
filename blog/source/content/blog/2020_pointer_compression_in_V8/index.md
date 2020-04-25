---
title: 「译」V8中的指针压缩
date: 2020-04-23 17:08:00
tags: 翻译,JavaScript
comments: true
categories: "翻译,JavaScript"
---

原文链接：https://v8.dev/blog/pointer-compression

内存和性能之间始终存在着斗争。作为用户，我们希望速度又快占用内存又少。不幸的是，通常情况下，提高性能需要消耗更多的内存（反之亦然）。

时间回到2014年，那时Chrome从32位切换到64位。这个变化带给了Chrome更好的[安全性、稳定性和性能](https://blog.chromium.org/2014/08/64-bits-of-awesome-64-bit-windows_26.html)，但同时也带来了更多内存的消耗，因为之前每个指针占用4个字节而现在占用是8个字节。我们面临在V8中尽可能减少这种多出来4个字节开销的挑战。


在实施改进之前，我们需要知道我们目前的状况以正确的评估如何改进。为了测量当前的内存和性能，我们使用一组可以代表目前流行站点的[页面](https://v8.dev/blog/optimizing-v8-memory)。数据显示在桌面端Chrome[渲染进程](https://www.chromium.org/developers/design-documents/multi-process-architecture)内存占用中V8贡献了60%的占用，平均为40%。

<!---在Chrome渲染进程内存占用中V8的内存消耗百分比-->
![OKR流程图1](./img/memory-chrome.svg)

指针压缩是改进V8内存占用的多项工作之一。想法很简单：我们可以存储一些“基”地址的32位偏移量而不是存储64位指针。如此简单的想法，在V8中这种压缩可以给我们带来多少收益？

V8的堆包含大量的项目（items），例如浮点值（floating point values），字符串字符（string characters），解析器字节码（interpreter bytecode）和标记值（tagged values）。在检查堆时，我们发现在现实使用网站中，这些标记值占了V8堆的70%！

下面我们具体看看这些标记值是什么。

## V8中的标记值

在V8中JavaScript的的对象，数组，数字或者字符串都都用对象表示，分配在V8堆上。这使得我们可以用一个指向对象的指针表示任何值。

许多JavaScript程序都会对整数进行计算，例如在循环中增加索引。为了避免每次整数递增的时候重新分配一个新的number对象，V8使用著名的[指针标记技术(pointer tagging)](https://en.wikipedia.org/wiki/Tagged_pointer)在V8的堆指针中存储附加的或替代的数据。（V8 uses the well-known pointer tagging technique to store additional or alternative data in V8 heap pointers.）

标签位（tag bits）有双重作用：（they signal either strong/weak pointers to objects located in V8 heap, or a small integer）。



















```
                        |----- 32 bits -----|
Pointer:                |_____address_____w1|
Smi:                    |___int31_value____0|
```