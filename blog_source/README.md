# 个人博客

这是一个基于 [Hugo](https://gohugo.io/) 静态网站生成器的个人博客源码，使用 [Even](https://github.com/olOwOlo/hugo-theme-even) 主题。

## 快速开始

### 安装 Hugo

请参考 [Hugo 官方文档](https://gohugo.io/getting-started/installing/) 安装 Hugo。

### 安装主题

```bash
git clone https://github.com/olOwOlo/hugo-theme-even.git themes/even
```

### 本地预览

```bash
# 启动本地服务器
hugo server -D
```

访问 http://localhost:1313 预览。

### 创建新文章

```bash
# 创建新文章
hugo new post/my-new-post.md
```

### 构建网站

```bash
# 构建静态网站
./build.sh
```

构建脚本会生成静态网站并将文件复制到上级目录，用于部署到 GitHub Pages。

## 部署

本博客部署在 GitHub Pages 上，网址：[https://mrzhang123.github.io/](https://mrzhang123.github.io/)

## 配置

主要配置文件为 `config.toml`，可以根据需要修改博客标题、作者信息、主题设置等。