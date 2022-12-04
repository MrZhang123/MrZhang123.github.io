---
title: 认识文件系统
date: 2022-11-27
tags:
- 操作系统
- 文件系统
categories:
- 操作系统
draft: false
---
我们平时使用计算机时，创建目录、更新目录、创建文件、编辑文件几乎是我们每天在计算机上做的事情。那么你是否深入思考过，为什么计算机能对目录和文件进行操作？为什么计算机能存储这些文件？其实完成这些工作的背后就是我们今天要介绍的主角——文件系统。

本文将介绍什么是文件系统，同时会基于一个简单的文件系统，介绍它的基本结构，它做了什么，以及当我们读取、写入文件时背后发生了什么。

## 什么是文件系统

究竟什么是文件系统呢？其实文件系统是一套实现了数据的存储、分级组织、访问和获取等操作的**抽象数据类型**。文件系统使用文件和树行目录的抽象概念代替了磁盘等物理设备，文件系统使用数据块的概念。它使得用户不必关心数据实际保存在地址为多少的硬盘数据块上，只需要记住文件所属的目录和文件名即可。

考虑文件系统时，我们通常考虑以下两个方面：
1. **文件系统数据结构**：文件系统在磁盘上使用哪些类型的结构来组织其数据和元数据？
2. **文件系统的访问方法**：如何将进程发出的调用，如 `open()`、`read()` 、`write()` 等，映射到它的结构上？在执行特定系统调用期间读取哪些数据结构？改写哪些数据结构？所有这些步骤的执行效率如何？

## 文件系统的组织

### 整体结构

对简单的文件系统来说，磁盘被划分成一系列相等的块，假设整个磁盘很小，每个块 4KB，共 32 块。划分如下：

{{< figure src="img/磁盘划分.png" >}}

为了构建文件系统，这些块中首先会存储用户数据。任何文件系统中的大多数空间都是用户数据。我们将用于存放用户数据的磁盘区称为 **数据区域**。在图中以 **D 表示**。

文件系统会记录每个文件的信息。该信息是**元数据**的关键部分，并且记录文件在数据区域包含哪些数据块、文件大小，其所有者和访问权限、访问和修改时间以及其他类似信息。为了存储这些信息，文件系统通常有一个名为 **inode** 的结构。

为了存放 inode，还需要在磁盘上留出空间。我们将这部分磁盘称为 **inode 表**，它保存了一个磁盘上 inode 的数组。在图中以 **I 表示**。

除了 D 和 I，我们还需要记录 inode 或数据块是空闲还是已分配。这也是所有文件系统中必需的部分。记录是否分配比较流行的方法是使用 [位图（bitmap）](https://en.wikipedia.org/wiki/Bitmap)，一种用于数据区域（数据位图，data bitmap），另一种用于 inode 表（inode 位图，inode bitmap）。位图的每个位用于指示相应的对象/块是空闲（0）还是正在使用。inode 位图用 **i 表示**，数据位图用 **d 表示**。

最后还剩余一块，用于保存**超级块（superblock）**，用 **S 表示**。超级块包含关于该特定文件系统的信息，例如文件系统有多少个 inode 和数据块、inode 表的开始位置等等。它可能还包含一些[Magic number](https://en.wikipedia.org/wiki/Magic_number_(programming))  ，来标识文件系统类型。

所以完整的一个文件系统结构如下：

{{< figure src="img/文件系统.png" >}}

在挂载文件系统时，操作系统会首先读取超级块，初始化各种参数，然后将该卷添加到文件树中。当卷中的文件被访问时，系统就会知道在哪里查找所需的磁盘上的结构。

### inode

inode 是文件系统最重要的磁盘结构之一。每个 inode 都由一个数字（称为 i-number 或 inode 号）隐式引用，我们可以将 inode 号称之为低级文件名称。

使用命令 [stat](https://wangchujiang.com/linux-command/c/stat.html) 可以查看 inode：

{{< figure src="img/文件.jpeg" >}}

在每个 inode 中包含的是所有关于文件的信息：
- 文件类型（例如，常规文件、目录等）
- 文件大小
- 分配给文件的块数
- 保护信息（如谁拥有该文件以及谁可以访问该文件）
- 时间信息（例如文件创建、修改或上次访问的时间）
- 文件的数据块驻留在磁盘上的位置的信息（例如某种类型的指针）

所有关于文件的信息称为**元数据**。实际上，文件系统中除了纯粹的用户数据外，其他任何信息都被称为元数据。

设计 inode 时最重要的就是如何引用数据块的位置。一种简单的方法就是在 inode 中有一个或多个直接指针（磁盘地址）。每个指针指向该文件的一个磁盘块。但是这样的设计会导致无法支持非常大的文件（大于块大小乘以直接指针数）。为了支持更大的文件，我们可以引入多级索引。

#### 多级索引

为了支持更大的文件，文件系统引入了**间接指针**。它不是指向包含用户数据的块，而是**指向包含更多指针的块，每个指针指向用户数据**。因此 inode 可以有一些固定数量直接指针和一个间接指针。如果文件变得足够大，则会分配一个来自磁盘数据块区域的间接块，并将 inode 的间接指针指向它。

{{< admonition info >}}
基于范围支持大文件

支持大文件的另一种方法是使用范围（extent）而不是指针。范围是一个磁盘指针加一个以块为单位的长度。因此，不需要指向文件的每个块的指针，只需要指针和长度来指定文件的磁盘位置。但只有一个范围是有局限的，因为分配文件时可能无法找到连续的磁盘可用空间。因此，基于范围的文件系统通常允许**多个范围**，从而在文件分配期间给予文件系统更多的自由。
{{< /admonition >}}

如果想要支持更大的文件，只需添加另一个指向 inode 的指针：双重间接指针。该指针指向一个包含间接块指针的块。

{{< figure src="img/多级索引.png" >}}

{{< admonition info >}}
**基于链接的方法**

设计 inode 的另一种更简单的方法是使用链表。这时在一个 inode 中就只需要一个指针，指向文件的第一个块。要支持较大的文件，就在该数据块的末尾添加另一个指针。

链式文件分配对于读取最后一个块或进行随机访问时表现不佳。因此，为了使链式分配更好的工作，一些系统在内存中保留链接信息表，而不是将下一个指针与数据块本身一起存储。该表用数据块 D 的地址来索引，一个条目的内容就是 D 的下一个指针，即 D 后面的文件中下一个块的地址。它也可以是空值（表示文件结束），或用其他标记来标识一个特定的块是空闲的。这就是所谓的文件分配表（File Allocation Table，FAT）。
{{< /admonition >}}

#### 文件名与 inode

文件与 inode 是一一对应的。对于计算机来说，通过 inode 号可以找到对应的文件，那我们是否可以用 inode 号来直接作为文件名呢？答案是否定的。原因有两个：

- 首先，inode 号是一个数字，对用户来说是很难记忆的。想象一下，如果把你电脑里的所有文件都命名成数字，那基本上想找什么都很难找到。
- 其次，将 inode 号作为文件名意味着期望 inode 号不会变更，而 inode 号与文件的存储相关，所以这相当于将用户文件名与文件存储位置强绑定。

为了解决上述问题，文件系统使用字符串形式的文件名，这其实就是增加了一层从字符串文件名到 inode 号之间的映射。

{{< figure src="img/文件名与inode映射.png" >}}

当我们创建一个文件时，其实做了两件事：
1. 首先构建一个inode，它将跟踪几乎所有关于文件的信息，包括大小、文件在磁盘上的位置等；
2. 其次将人类可读的名称链接到该文件，然后将该链接放入目录中。

## 目录组织

目录其实是一种特殊的文件，它具有一个 inode，它的文件类型为目录。目录记录了从文件名到 inode 号的映射。由于目录本身也是文件，所以可以通过递归来组织文件系统中的文件。

目录与常规文件有差别：常规文件保存的是我们的数据，而**目录文件保存的是目录项，每个目录项代表一条文件信息，记录了文件的文件名及对应的 inode 号**。

{{< figure src="img/目录文件中的内容：目录项.png" >}}

## 文件的读取和写入

上面就是关于文件系统，文件及目录的介绍，接下来介绍一下文件读取和写入的过程。

### 从磁盘读取文件

要读取一个文件的内容，首先需要打开文件，然后再读取文件内容。打开文件调用 `open` 系统调用，具体用法查看：[open(2) - Linux manual page](https://man7.org/linux/man-pages/man2/open.2.html)。

```c
#include <fcntl.h>
int open(const char *pathname, int flags);
```

当调用`open("foo/bar", O_RDONLY)`打开文件时，文件系统首先要找到文件 bar 的 inode，从而获取该文件的基本信息（如权限信息、文件大小等）。为此，文件系统需要找到 inode，但是我们传给 `open()` 函数的参数只有路径名，所以文件系统需要遍历文件路径，从而找到目标文件的 inode。所有遍历都是从系统的根目录（/）开始，所以文件系统第一次读取的是根目录的 inode。

要找到 inode，首先要知道它的inode 号。**通常在父目录中找到文件或子目录的 inode 号**。根没有父目录，所以根的 inode 号必须是“众所周知的”。在挂载文件系统时，文件系统必须知道它是什么。在大多数 UNIX 文件系统中，**根目录的 inode 号是 2**。因此开始遍历文件路径的时候，文件系统第一个读入的 inode 号是 2。

{{< admonition question >}}
为什么根目录的 inode 号是 2，inode 号是否有 0 和 1？

根目录的 inode 号是 2，因为 inode 0 和 1 已经被占用了：
- inode 0 用于表示一个 NULL 值，表示没有 inode。
- inode 1 用于跟踪磁盘上的坏块，它本质上是一个包含坏块的隐藏文件。使用`e2fsck-c`记录的那些坏块。
{{< /admonition >}}

所以调用 `oepn()` 打开文件时，实际上进行了如下操作：
1. **读入根目录 inode**：一旦根目录的 inode 被读入，文件系统可以在其中查找指向数据块的指针，数据块包含根目录的内容。
2. **读取根目录内容**：文件系统使用磁盘上的指针来读取目录内容。
3. **递归遍历路径名**：通过不断读入 inode，读取目录内容，直到找到目标的 inode。
4. **打开目标文件**：最后一步是将目标文件的 inode 读入内存。然后文件系统进行最后的权限检查，在每个进程的打开文件中，为其分配一个文件描述符，并将它返回给用户。

打开文件后，程序可以发出 `read()` 系统调用，从文件中读取内容。第一次读取将在文件中的第一个块中读取，同时也会用新的最后访问时间更新 inode。读取将进一步更新此文件描述符在内存中的打开文件表，更新文件偏移量，以便下一次从第二个文件块读取。

从上面可以看出，打开文件时为了找到文件的 inode 会发生多次读取。读取每个块需要文件系统首先查询 inode，然后读取该块，再使用写入更新 inode 的最后访问时间等字段。所以 `open` 导致的 I/O 量与路径名长度成正比。对于路径中的每个增加的目录，都必须读取它的 inode 及其数据。

### 写入文件

写入文件和读取文件类似，首先要打开文件，然后发出  `write`  调用以新内容更新文件，最后关闭文件。但写入文件可能会分配一个块。当写入一个新文件时，每次写入操作在将需要写入磁盘的数据写入之前，需要先决定将哪个块儿分配给文件，从而相应的更新磁盘的其他结构（数据位图和 inode）。

每次写入文件在逻辑上会导致 5 个 I/O：
- 读取数据位图，然后更新以标记新分配的块儿；
- 写入位图，将它的新状态写入磁盘；
- 读取 inode；
- 写入 inode，更新块的位置；
- 写入真正的数据本身。

而创建一个文件的工作量更大，要创建一个文件，文件系统不仅要分配一个 inode，还要在包含新文件的目录中分配空间：
- 读取 inode 位图，查找空闲 inode；
- 写入 inode 位图，将其标记为已分配；
- 写入新的 inode 本身；
- 写入目录的数据，将文件的高级名称链接到它的 inode 号；
- 读写目录的 inode。
如果目录为了容纳新的条目而增长，则还需要额外的 I/O （即数据位图和新目录块）。

基于以上，我们分析一个在目录 `foo` 下创建 `bar` 文件，然后再更新 `bar` 文件的例子。

创建  `bar` 文件：
1. **读取根目录的 inode**；
2. **读取根目录的内容**：根据根目录的 inode 找到对应的根目录内容，并读取；
3. **读取 foo 目录的 inode**：根据根目录的内容找到 foo 目录的 inode；
4. **读取 foo 目录的内容**：根据 inode 读取相应的目录内容；
5. **读取 inode 位图，查找空闲 inode**；
6. **写入 inode 位图，将其标记为已分配**；
7. **写入 foo 目录内容**：将文件 bar 的高级名称链接到它的 inode 号；
8. **读取 bar 的 inode**：找到 bar 文件；
9. **写入 bar 的 inode**：将 bar 文件的创建时间等写入 inode；
10. **写入 foo 目录的 inode**：将 foo 目录的更新时间等写入 inode；

更新 `bar` 文件：
1. **读取 bar 的 inode**：找到 bar 文件；
2. **读取数据位图**：查找空闲的数据块；
3. **写入数据位图**：标记数据块已经被分配；
4. **写入 bar 新增的数据**：将新增的数据写入到可用的空闲数据块；
5. 写**入 bar 的 inode**：写入 inode，记录更新时间、访问时间等基本信息。

可以看到，创建文件、更新文件会伴随着大量的 I/O 操作，要知道 I/O 操作的成本是很高的，那么文件系统如何减少这些 I/O 操作呢？

## 缓存和缓冲

既然有很多次读取和写入，那么如果我们将常用的块缓存到内存中，就可以减少读取了，所以很多文件系统采用了系统内存（DRAM）来缓存重要的块。

早期的文件系统引入固定大小的缓存来保存常用的块。采用 [LRU（最近最少使用）](https://en.wikipedia.org/wiki/Cache_replacement_policies#Least_recently_used_(LRU)) 策略来决定哪些块保留在缓存中。但是这种静态内存划分可能带来内存的浪费。所以现代文件系统采用动态划分。具体来说，许多现代操作系统**将虚拟内存页面和文件系统页面集成到同一页面缓存中**。通过这种方式，可以在虚拟内存和文件系统之间灵活地分配内存。

有了缓存后，我们第一次打开文件时需要走上面的打开流程，但是第二次再打开同样文件时就会命中缓存，减少很多 I/O。而对于写入操作，由于必须写入到磁盘才算是实现持久。所以，**高速缓存不能减少写入流量**。

但是加入缓存后，延迟写入（写缓冲）还是有意义的：
- 通过延迟写入，系统可以将一些更新编成一批，放入一组较小的 I/O 中，这可以减少写入 I/O。
- 通过将一些写入缓冲在内存中，系统可以调度后续的 I/O ，从而提高性能。
- 一些写入可以通过延迟来完全避免，例如写入临时文件随后删除的操作。

## 总结

以上就是关于文件系统的简单介绍，我们再回顾一下：

- 文件系统由超级块、数据位图、inode 位图、inode、数据区域这几个基本结构组成。
- inode 中包含文件的基础信息，是文件系统找到对应文件的重要结构。通过将 inode 与字符串文件名连接，方便我们识别计算机中的文件。
- 目录是一种特殊的文件，它的本质上记录了文件名到 inode 号的映射，我们可以通过读取目录内容来找到对应目录中包含的文件。
- 文件的读取和写入需要多次读取和写入位图，inode，数据块等，即多次 I/O 操作。
- 由于文件的读取和写入涉及多次 I/O 操作，所以引入缓存来减少 I/O 操作，缓存的引入可以减少读的 I/O，但是无法减少写的 I/O，但是依然对写入有好处。