---
title: 聊一聊 JS 中的二进制
date: 2023-02-18
tags:  ["Node.js", "二进制"]
categories:  ["Node.js"]
draft: false
featuredImage: "../../../image/logo/nodejs.png"
---

在 JavaScript 中，有很多跟二进制相关的概念，例如 `Buffer`，`TypedArray`，`ArrayBuffer`，`Blob`，`Stream` 等等。那么这些概念彼此之间的关系是什么？各自的使用场景是什么？这将是本文内容的重点。

## 定型数组（TypedArray）

首先介绍下定型数组。定型数组是一种用于处理 **数值** 类型（注意不是所有类型）数据的 **专用数组**，`ArrayBuffer`（数组缓冲区） 只是其中的一个概念。

### 定型数组的历史

定型数组最早是在 [WebGL](https://zh.wikipedia.org/wiki/WebGL)  中使用的，WebGL 是 OpenGL ES 2.0 的移植版，在 WebGL 早期的版本中，因为 JavaScript 数组与原生数组之间不匹配，所以出现了性能问题。

JavaScript 数组在内存中的格式是双精度浮点格式（IEEE 754 64位），但图形驱动程序 API 通常不需要以 JavaScript 默认的双精度浮点格式传递给它们的数值。所以每次 WebGL 与 JavaScript 运行时之间传递数组时，WebGL 都需要在目标环境重新分配数组，以其当前格式迭代数组，然后将数值转换成新数组中的适当格式，这需要花费很多时间。

为了解决上面的问题，Mozilla 实现了 `CanvasFloatArray`。它提供了 JavaScript 接口的、C语言风格的浮点值数组。最终该类型成为了 `Float32Array`，即定型数组的其中一个类型。

### 数组缓冲区（ArrayBuffer）

`ArrayBuffer` 是所有定型数组的基础，它是一段 **可以包含特定数量字节的内存地址**，这在其他语言中被称为“Byte Array”。创建 `ArrayBuffer` 的过程类似于在 C 中调用 `malloc()` 来分配内存，只不过不需要指明内存块所包含的数据类型。

```js
let buffer = new ArrayBuffer(10); // 在内存中分配 10 字节
```

>需要注意一点：ArrayBuffer 一旦创建就不能改变大小。

当然，仅创建存储单元没什么用，我们需要将数据写入到存储单元中，所以还需要创建一个视图来实现写入功能。

数组缓冲区是内存中的一段地址，视图是用来操作内存中的接口。视图可以操作数组缓冲区或缓冲区的子集，并按照其中一种数值型数据类型来读取和写入数据。

### DataView

第一种允许读写 `ArrayBuffer` 的视图是 `DataView`，它是一种 **通用的** 数组缓冲区视图 。该视图专为文件 I/O 和网络 I/O 设计，其 API 支持对缓冲数据的高度控制，但相比于其他类型的视图性能要差一些。

使用示例如下：

```js
let buffer = new ArrayBuffer(10)
let view = new DataView(buffer)
```

DataView 有以下几个属性：
- buffer：视图绑定的数组缓冲区；
- byteOffset：DataView 构造函数的第二个参数，默认是 0，只有传入参数时才有值；
- byteLength：DataView 构造函数的第三个参数，默认是缓冲区的长度的 bytelength。

DataView 对存储在缓冲内的数据类型没有预设值，它的 API 强制开发者在读、写时指定一个 ElementType，然后 DataView 就会按照指定的类型做相应转换。DataView 支持的 ElementType 有如下 8 种：

| 类型 | 字节 | 说明                  |
| ----------- | ---- | --------------------- |
| Int8        | 1    | 8 位有符号整数        |
| Uint8       | 1    | 8 位无符号整数        |
| Int16       | 2    | 16 位有符号整数       |
| Uint16      | 2    | 16 位无符号整数       |
| Int32       | 4    | 32 位有符号整数       |
| Uint32      | 4    | 32 位无符号整数       |
| Float32     | 4    | 32 位 IEEE-754 浮点数 |
| Float64     | 8    | 64 位 IEEE-754 浮点数 | 

以上每种类型都暴露了 `get` 和 `set` 方法，例如 `getInt8(byteOffset, littleEndian)`，`setFloat32(byteOffset, value ,littleEndian)` 。更详细的介绍查看：[DataView](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/DataView) 。

### 定型数组

定型数组是另一种形式的 `ArrayBuffer` 视图，它是用于数组缓冲区的 **特定类型** 的视图，可以直接强制使用特定的数据类型而不是通用的 `DataView` 对象来操作数组的缓冲区，定型数组遵循原生的字节序。

定型数组的类型有如下几种：

| 构造函数名        | 字节 | 说明                       |
| ----------------- | ---- | -------------------------- |
| Int8Array         | 1    | 8 位有符号整数             |
| Uint8Array        | 1    | 8 位无符号整数             |
| Uint8ClampedArray | 1    | 8 位无符号整数（强制转换） |
| Int16Array        | 2    | 16 位有符号整数            |
| Uint16Array       | 2    | 16 位无符号整数            |
| Int32Array        | 4    | 32 位有符号整数            |
| Uint32Array       | 4    | 32 位无符号整数            |
| Float32Array      | 4    | 32 位 IEEE 浮点数          |
| Float64Array      | 8    | 64 位 IEEE 浮点数          |

上面的 `Uint8ClampedArray` 和 `Uint8Array` 大致相同，唯一的区别在于数组缓冲区中的值如果小于 0 或大于 255，`Uint8ClampedArray` 会将其分别转换成 0 或者 255。例如，-1 会变成0，300 会变成 255。

按照 JavaScript 之父 Brendan Eich 的说法：” `Uint8ClampedArray` 完全是 HTML5 `canvas` 元素的历史遗留。除非真的做跟 `canvas` 相关的开发，否则不要使用它。“

关于定型数组更详细的用法查看文档：[TypedArray](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/TypedArray)

### 字节序

使用定型数组可以查看相同字节序列的8、16、32或64位视图。这里就涉及到“字节序”的问题。所谓“字节序”指的是计算机系统维护的一种字节顺序的约定。它分为两种：大端字节序（big endian）和小端字节序（little endian）：
-   **大端字节序**：高位字节在前，低位字节在后，这是人类读写数值的方法。
-   **小端字节序**：低位字节在前，高位字节在后。
例如数值 `0x2211` 使用两个字节储存：高位字节是`0x22`，低位字节是`0x11`，所以对应的小端字节序为`0x1122`。

可以使用以下代码确定底层平台的字节序：

```js
// 如果整数 0x00000001 在内存中的排列为 01 00 00 00
// 则底层使用小端字节序。在大端字节序平台中应该是 00 00 00 01
let littleEndian = new Int8Array(new Int32Array([1]).buffer)[0] === 1
```

目前市面上常见的 CPU 都是小端字节序。而很多网络协议及某些二进制文件格式则要求使用大端字节序。

为了考虑效率，定型数组使用底层硬件的原生字节序。上面提到的 `DataView` 并不遵守这个约定。对一段内存而言，`DataView` 是一个中立接口，它会遵循你指定的字节序。`DataView` 所有 API 方法都以大端字节序为默认值，但可以通过接收一个 `true` 开启小端字节序。

```js
const buf = new ArrayBuffer(2)
const view = new DataView(buf)

// 按小端字节序读取 Uint16
view.getUint16(0, true)
```

## Stream

Steam API 是为了解决 Web 应用有序消费小信息块而不是大信息块的问题的。这种能力的应用场景如下：
- 大信息块可能不会一次性都可用：网路请求的响应就是一个典型的例子。网路负载以连续信息包的形式交付，而流式处理可以让应用在数据一到达就能使用，而不必等到所有数据都加载完毕。
- 大数据块可能需要分小部分处理。例如视频处理、数据压缩等。

Stream API 直接解决的问题是处理 **网络请求** 和 **读写磁盘**，它定义了三种流：
- **可读流**：通过某个公共接口读取数据块的流。数据在内部从底层源进入流，然后由消费者（consumer）进行处理；
- **可写流**：通过某个公共接口写入数据块的流。生产者（producer）将数据写入流，数据在内部传入底层数据槽（sink）；
- **转换流**：由两种流组成，可写流用于接收数据（可写端），可读流用于输出数据（可读端）。这两个流之间是转换程序（transformer），可以根据需要检查和修改流内容。

流的基本单位是块（chunk）。**块可以是任意数据类型，但通常是定型数组**。每个块都是离散的流片段，可以作为一个整体来处理。块的大小不固定，也不一定按固定时间间隔到达。

## Blob

**Blob 和文件读取有关**。某些情况下，我们需要读取部分文件而不是整个文件。为此，File 对象提供了名为 `slice()` 的方法。`slice()` 方法返回一个 Blob 实例。File 接口基于 Blob，继承了 blob 的功能并将其扩展以支持用户系统上的文件。

blob 表示二进制大对象（binary larget object），是 JavaScript 对不可修改二进制数据的封装类型。包含字符串的数组、`ArrayBuffer`、`ArrayBufferView`，甚至其他 Blob 都可以用来创建 blob。它的数据可以按文本或二进制的格式进行读取，也可以转换成 [ReadableStream](https://developer.mozilla.org/zh-CN/docs/Web/API/ReadableStream) 来用于数据操作。

Blob 有两个属性：
- `Blob.prototype.size`：表示 Blob 对象所包含的**数据的大小（字节）**；
- `Blob.prototype.type`：一个字符串，表明该 Blob 对象所包含的 MIME 类型。如果类型未知，则该值为空。

Blob 的实例方法如下：
- `Blob.prototype.arrayBuffer()`：返回一个 promise，resolve 后结果包含 Blob 所有内容的二进制格式的 `ArrayBuffer`；
- `Blob.prototype.slice()`：返回一个新的 Blob 对象，包含了源 Blob 对象中指定范围内的数据；
- `Blob.prototype.stream()`：返回一个能读取 Blob 内容的 ReadableStream；
- `Blob.prototype.text()`：返回一个 promise，resolve 后结果包含 Blob 所有内容的 UTF-8 格式的字符串。

## Buffer

最后我们再来聊一下 Buffer，和上面的几个不同的是，Buffer 是 Node.js 中特有的，但是实际上 `Buffer` 类是 JavaScript 中 `Uint8Array` 的子类，并且对其进行了扩展。

Buffer 的实例也就是 JavaScript Uint8Array 和 TypedArray 的实例，所有 TypedArray 的方法在 Buffer 中都支持。然而 Buffer API 和 TypedArray API 有些许的不同：
- `TypedArray.prototype.slice()`  复制调用数组的一部分并返回一个新数组，而 `Buffer.prototype.slice()` 在不复制的情况下在现有缓冲区创建视图。`TypedArray.prototype.subarray()` 可以实现和 `Buffer.prototype.slice()` 相同的行为，它在 Buffer 和 TypedArray 中没有区别；
- `buf.toString()` 与 `TypedArray.prototype.toString()` 不兼容；
- Buffer 中的很多方法例如 `buf.indexOf()` 支持附加参数。

所以我们可以认为 Buffer 和 TypedArray 是为了处理一类问题而存在的，但是在实际使用过程中还是要注意兼容性问题。

## 总结

以上就是 JS 中和二进制相关的一些概念。最后，用一张图总结一下上面提到的这些概念的关系：

{{< figure src="img/JS二进制概念的关系.png" >}}


## 参考
- [Blob - Web APIs | MDN (mozilla.org)](https://developer.mozilla.org/en-US/docs/Web/API/Blob)
- [ArrayBuffer - JavaScript | MDN (mozilla.org)](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/ArrayBuffer)
- [Streams API - Web APIs | MDN (mozilla.org)](https://developer.mozilla.org/en-US/docs/Web/API/Streams_API)
- [Buffer | Node.js v18.14.0 Documentation (nodejs.org)](https://nodejs.org/dist/latest-v18.x/docs/api/buffer.html)
- [Stream | Node.js v18.14.1 Documentation (nodejs.org)](https://nodejs.org/dist/latest-v18.x/docs/api/stream.html)
- [Web Streams API | Node.js v18.14.1 Documentation (nodejs.org)](https://nodejs.org/dist/latest-v18.x/docs/api/webstreams.html)
- [Previous Releases | Node.js (nodejs.org)](https://nodejs.org/en/download/releases/)

