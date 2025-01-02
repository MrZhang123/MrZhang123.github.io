---
title: 记一次vim性能优化
date: 2019-09-01 16:15:00
tags:
  - Vim
categories:
  - Vim
draft: false
---

### 关键点

* `vim -u NONE -N`可以不加载vim配置和插件打开vim
* `vim --startuptime vim.log`可以生成vim启动的log
* 使用`vim-plug`插件管理工具，给插件配置`for` or `on`可以实现插件懒加载
* 设置`foldmethod=syntax`会导致vim插入模式下卡顿
<!--more-->
![vim](./img/vim.jpg)

>用vim已经一年了，之前虽然知道vim会有性能问题，但是之前从来没遇到过，也许也遇到过？貌似把问题推给电脑了，因为印象中，电脑用一天，内存占用会达到80%以上，那时候，vim也会卡，所以一直是想办法把内存降下来。直到最近...

最近用vim打开一个2000多行代码的js文件，发现打开文件时候有一些卡顿，在输入的时候发现，卡到爆炸💥，无法正常输入，但是如果不加载`.vimrc`和插件，即用`vim -u NONE -N`打开，完全不会卡，至此确定我遇到了vim性能问题，需要优化我的vim配置。

一般情况下，vim的性能问题都是由于我们装插件太多导致的，本质上是因为vim不支持异步，但是现在（vim8+）支持异步了，所以很多插件都开始转向使用异步API实现自己的功能，比如大名鼎鼎的`YouCompleteMe`，不过也不是所有的插件都会做支持，毕竟vim好多年了，也许我们用的一些插件都停更好久了。

### vim启动优化

为了优化vim启动，首先可以做的一点是将**插件懒加载**，即用到哪个插件再加载哪个插件，通过`vim-plug`插件管理工具可以非常方便的做到，配置方式如下：

```sh
Plug 'mattn/emmet-vim', { 'for': ['html', 'javascript.jsx'] }
Plug 'mxw/vim-jsx', { 'for': 'javascript.jsx' }
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
```

`on`表示在某个条件下加载，例如上面的配置表示在输入命令`NERDTreeToggle`的时候加载`nerdtree`插件，`for`表示该插件针对某一类文件加载，例如`vim-jsx`插件只有在文件类型为`javascript.jsx`的时候加载。

这样就可以让vim在启动的时候，不加载不必要的插件。

### vim输入性能优化

启动快了，但是输入还是很卡，所以开始寻找是哪个插件的问题。

为了找到具体是哪个插件导致的卡顿，首先可以通过生成的vim.log文件查看vim启动以及使用的时候每一步的时间，具体启动方式如下：

```sh
# 启动vim并生成vim启动时候的日志
$ vim --startuptime vim.log
```

这样就可以拿到具体vim启动时候的各个步骤的启动时间，但是查看了日志并没看看出明显的问题🤔，所以开始尝试第二种方法，逐个注销vim的插件，看哪个插件注销后，卡顿会消失。

发现注释掉`vim-javascript`后，输入变得流畅，所以可以确定是这个插件导致的问题，但是这个插件是用来支持js语法的，不应该出现这么严重的性能问题啊，去GitHub vim-javascript 的 issues中搜索关于`performance`的帖子，最终找到一篇关于打开大的js文件严重卡顿的原因：[Very slow performance in large Js files](https://github.com/pangloss/vim-javascript/issues/140)，在帖子中插件的作者回复到，**出现卡顿的原因是设置了`foldmethod=syntax`**（该设置项本来是让vim基于语法进行折叠），作者强调给vim设置该选项本身就会导致插入时候速度变慢，具体原因以及解决方法（文中的解决方案尝试了，但是没有效果😅）可以查看：[Keep folds closed while inserting text](https://vim.fandom.com/wiki/Keep_folds_closed_while_inserting_text)。

**解决方案：**

1. 可以给foldmethod设置其他选项（manual，indent，marker）
2. 直接使用vim的一个插件——[FastFold](https://github.com/Konfekt/FastFold)实现代码折叠
3. 去掉代码折叠设置

总的来说就是不要在插入模式下使用`foldmethod=syntax`。

基于以上优化，再打开大型文件，vim不再卡顿，又可以流畅的使用vim编写代码了😁。