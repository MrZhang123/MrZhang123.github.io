---
title: 「译」JS新特性“可选链式调用”
date: 2019-09-03
tags:
  - JavaScript
categories:
  - JavaScript
draft: false
---

在JavaScript中长的链式调用可能容易出错，因为任何一步都可能出现`null`或`undefined`（也被称为“无效”值）。检查每个步骤的属性是否存在很容易变成深层次嵌套的`if`声明或者复制属性访问链的长的`if`条件：
<!--more-->
```JavaScript
// 容易出错的版本，可能抛出错误
const nameLength = db.user.name.length;

// 不容易出错，但是难以阅读
let nameLength;
if (db && db.user && db.user.name)
  nameLength = db.user.name.length;
```

以上还可以使用三元表达式，但是同样难以阅读：

```javascript
const nameLength =
  (db
    ? (db.user
      ? (db.user.name
        ? db.user.name.length
        : undefined)
      : undefined)
    : undefined);
```

## 介绍可选调用链

我们并不想写出这样的代码，所以有一些代替方案是可取的。一些语言（例如swift，具体查看https://www.jianshu.com/p/5599b422afb0）针对这个问题提供了优雅的解决方案——可选调用链。
根据[最近的规范](https://github.com/tc39/proposal-optional-chaining)，“可选调用链是一个或多个属性访问和函数调用的链，以`?.`开头”。

使用新的可选调用链，我们可以重写上面的demo：

```JavaScript
// 依然检查错误，但是可读性更高
const nameLength = db?.user?.name?.length;
```

使用可选调用链，当`db`，`user`，或`name`是`undefined`或者`null`的时候，`nameLength`被初始化为`undefined`，而不是像之前那样抛出错误。

**Note：**可选调用链比我们自己用`if(db && db.user && db.user.name)`检查更加健壮，例如，如果`name`是一个空字符串，可选字符串会将`name?.length`改为`name.length`然后得到正确的长度`0`，但是如果像我们之前那样做判断，不会得到正确的值，因为在if语句中空字符和`false`的行为相同。可选调用链修复了这个常见的bug。

## 其他的语法形式：调用和动态属性

还有一个用于调用可选方法的运算符：

```JavaScript
// 使用可选方法扩展接口，仅适用于管理员用户
const adminOption = db?.user?.validateAdminAndGetPrefs?.().option;
```

这个语法可能有点儿出乎意料，因为这里的运算符是`?.()`，该运算符适用于之前的表达式。

可选调用链还有第三种用法，即可选动态属性访问`?.[]`。如果对象中有该key对应的value，则返回value，否则返回`undefined`。demo如下：

```JavaScript
// 使用动态属性名访问属性对应的值
const optionName = 'optional setting';
const optionLength = db?.user?.preferences?.[optionName].length;
```

该用法同样适用于可选索引数组，例如：

```javascript
// 如果`userArray`是`null`或`undefined`，则`userName`被优雅的赋值为`undefined`
const userIndex = 42;
const userName = usersArray?.[userIndex].name;
```

可选调用链可以和[nullish coalescing ?? 操作符](https://github.com/tc39/proposal-nullish-coalescing)结合使用，返回一个非`undefined`的默认值。这样可以使用指定的默认值安全的进行深层属性访问，解决了之前用户需要JavaScript库才能解决的问题，例如[lodash的_.get](https://lodash.dev/docs/4.17.15#get)：

```JavaScript
const object = { id: 123, names: { first: 'Alice', last: 'Smith' }};

{ // With lodash:
  const firstName = _.get(object, 'names.first');
  // → 'Alice'

  const middleName = _.get(object, 'names.middle', '(no middle name)');
  // → '(no middle name)'
}

{ // With optional chaining and nullish coalescing:
  const firstName = object?.names?.first ?? '(no first name)';
  // → 'Alice'

  const middleName = object?.names?.middle ?? '(no middle name)';
  // → '(no middle name)'
}
```

## 可选调用链的属性

可选调用链有一些有趣的属性：*短路（short-circuiting）*，*堆叠（stacking）*和*可选删除（optonal deletion）*。下面通过例子来了解这些属性。

*短路（short-circuiting）*即如果可选调用链提前返回则不计算表达式的其余部分：

```JavaScript
// 只有在`db`和`user`不是`undefined`的情况下`age`才会+1
db?.user?.grow(++age);
```

*堆叠（stacking）*意味着可以在一系列属性访问中应用多个可选调用运算符：

```JavaScript
// 一个可选链可以跟随另一个可选链
const firstNameLength = db.users?.[42]?.names.first.length;
```

但是，考虑在一个链中使用多个可选调用运算符。如果一个value保证是有效的，那么不鼓励使用`?.`去访问属性。像在之前的例子中，`db`必然是定义的，但是`db.users`和`db.users[42]`可能是未定义的。如果数据库中有这样的用户，那么`name.first.length`也是始终被定义的。

*可选删除（optonal deletion）*就是`delete`操作符可以和可选链一起使用：

```JavaScript
// 当且仅当`db`是定义过的时候删除`db.user`
delete db?.user;
```

更多细节可以访问[该提案的语义部分](https://github.com/tc39/proposal-optional-chaining#semantics)。

原文链接：https://v8.dev/features/optional-chaining