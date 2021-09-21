---
title: 使用Axios请求时如何传递数组？
date: 2019-05-18 16:40:00
tags:
  - Javascript
categories:
  - Javascript
draft: false
---

>最近在项目开发中使用Axios请求，API层使用**Node**，在GET请求传递数组参数时候遇到了一些问题，这里总结一下。

在开发中经常会使用axios作为请求库，在请求过程中，经常会传递数组作为参数，在实际开发过程中发现，如果在POST请求中，直接传递数组即可，但是在GET请求中，本质上是将参数拼接到url后面，作为参数，即`http://xx.xx.com?a=1&b=2`这样的形式，如果直接传递数组，则在API层拿到的数据就是一个数组样式的字符串，这并不符合我们的要求。那么，如何传递数组呢？
<!--more-->
### 使用JSON.stringify/parse

既然我们传递的只能是一个字符串，最直接的办法就是先把数组变成字符串，然后在API层再做解析。我们可以在前端使用`JSON.stringify`将数组变成字符串，传递到API层，然后再用`JSON.parse`做解析，这样就可以成功的将数组从前端传递到API层。

但是，这样做有一个问题，就是如果我们传递太多的数组，会导致前端传递数据的时候有很多`JSON.stringify`同样的，在Node这边会有很多的`JSON.parse`导致代码很不美观，那么如何更优雅的处理呢？

### 使用qs库和axios的参数处理函数

[qs](https://github.com/ljharb/qs)是一个用于解析嵌套字符串的库，使用这个库，可以在前端发出请求前，将参数统一`stringify`，然后在node层也使用qs将参数进行`pase`，具体处理方式如下：

首先将参数做统一处理：

```js
paramsSerializer: function (params) {
    return qs.stringify(params, {arrayFormat: 'indices'})
}
```

然后在API层，引入`qs`库，直接将整个参数进行`qs.parse`，即可还原传递过来的参数。

**这里需要特别说明一下：**

qs库对数组的format有以下几种形式：

```js
qs.stringify({ids: [1, 2, 3]}, { indices: false })
// 形式： ids=1&ids=2&id=3

qs.stringify({ids: [1, 2, 3]}, {arrayFormat: 'indices'})
// 形式： ids[0]=1&aids1]=2&ids[2]=3

qs.stringify({ids: [1, 2, 3]}, {arrayFormat: 'brackets'})
// 形式：ids[]=1&ids[]=2&ids[]=3

qs.stringify({ids: [1, 2, 3]}, {arrayFormat: 'repeat'}) 
// 形式： ids=1&ids=2&id=3
```

使用第一种方式传递数组，如果数组元素不止一个，则在API层不用`parse`直接就可以拿到数组，**但是，如果是数组只有一个元素，则拿到的就是一个字符串**，所以，最后的办法就是在前端进行`stringify`，在API层进行`parse`。

以上就是大概的一个总结，一个小小的坑，总结一下，后面方便查询
