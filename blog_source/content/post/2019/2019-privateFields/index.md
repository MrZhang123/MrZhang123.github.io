---
title: 「译」ES 草案：class私有属性
date: 2019-07-21
tags:
  - JavaScript
categories:
  - JavaScript
draft: false
---

> 原文链接：https://2ality.com/2019/07/private-class-fields.html

class属性是关于直接在类体内创建属性和类似构造，这篇播客文章是关于它们的系列文章的一部分：

1. [公有class属性](https://2ality.com/2019/07/public-class-fields.html)
2. 私有class属性
<!--more-->
在这篇文章中，我们看看*私有属性*，在类和实例中的一种新的私有插槽。这个功能是ES草案[“JavaScript类属性声明”](https://github.com/tc39/proposal-class-fields)的一部分。

## 1.概览

Private fields是一种与属性不同的新的数据插槽。它们只能在它们声明的class body内直接访问。

### 1.1 静态私有属性

```js
class MyClass {
  // 声明并初始化静态私有属性
  static #privateStaticField = 1;
  static getPrivateStaticField() {
    return MyClass.#privateStaticField; // (A)
  }
}
assert.throws(
  () => eval('MyClass.#privateStaticField'),
  {
    name: 'SyntaxError',
    message: 'Undefined private field undefined:' +
      ' must be declared in an enclosing class',
  }
);
assert.equal(MyClass.getPrivateStaticField(), 1);
```

小窍门：永远不要用`this`来访问一个静态私有属性，直接使用类名访问即可（就像A行那样）。为什么会在本文后面解释。

### 1.2 实例私有属性

使用带有初始值的私有属性（等号后面跟值）。

```js
class MyClass {
  // 声明并初始化
  #privateInstanceField = 2;
  getPrivateInstanceField() {
    return this.#privateInstanceField;
  }
}
assert.throws(
  () => eval('new MyClass().#privateInstanceField'),
  {
    name: 'SyntaxError',
    message: 'Undefined private field undefined:' +
      ' must be declared in an enclosing class',
  }
);
assert.equal(new MyClass().getPrivateInstanceField(), 2);
```

使用未初始化的实例私有属性：

```js
class DataStore {
  #data; // 必须声明
  constructor(data) {
    this.#data = data;
  }
  getData() {
    return this.#data;
  }
}
assert.deepEqual(
  Reflect.ownKeys(new DataStore()),
  []);
```

## 2. 从下划线到实例私有属性

在JavaScript中保持数据私有的公共约定是使用带有下划线的属性名。在这个部分，我们从使用这个约定的代码开始，然后更改它，到使用实例私有属性。

### 2.1 从下划线开始

```js
class Countdown {
  constructor(counter, action) {
    this._counter = counter; // private
    this._action = action; // private
  }
  dec() {
    if (this._counter < 1) return;
    this._counter--;
    if (this._counter === 0) {
      this._action();
    }
  }
}
// 变量并非真正的私有
assert.deepEqual(
  Reflect.ownKeys(new Countdown(5, () => {})),
  ['_counter', '_action']);
```

这个约定并没有给我们任何保护；它仅仅建议使用这个类的用户：不要使用这些属性，它们是私有的。

### 2.2 切换到实例私有属性

我们可以用实例私有属性代替下划线：

1. 我们用哈希符`#`替换每一个下划线`_`。
2. 我们在类的顶部声明所有的私有属性。

```js
class Countdown {
  #counter;
  #action;

  constructor(counter, action) {
    this.#counter = counter;
    this.#action = action;
  }
  dec() {
    if (this.#counter < 1) return;
    this.#counter--;
    if (this.#counter === 0) {
      this.#action();
    }
  }
}
// The data is now private:
assert.deepEqual(
  Reflect.ownKeys(new Countdown(5, () => {})),
  []);
```

## 3. 类主体内的所有代码都可以访问私有属性

例如，实例方法可以访问静态私有属性：

```js
class MyClass {
  static #privateStaticField = 1;
  getPrivateFieldOfClass(theClass) {
    return theClass.#privateStaticField;
  }
}
assert.equal(
  new MyClass().getPrivateFieldOfClass(MyClass), 1);
```

一个静态方法可以访问实例私有属性：

```js
class MyClass {
  #privateInstanceField = 2;
  static getPrivateFieldOfInstance(theInstance) {
    return theInstance.#privateInstanceField;
  }
}
assert.equal(
  MyClass.getPrivateFieldOfInstance(new MyClass()), 2);
```

## 4.（高级）

剩余部分是关于类的私有属性的高级用法

## 5. 深入理解私有属性

在规范中，私有属性通过附加到对象上的数据结构进行管理。私有属性的大致处理过程如下：

```js
{
  // Private names
  const _counter = {
    __Description__: 'counter',
    __Kind__: 'field',
  };
  const _action = {
    __Description__: 'action',
    __Kind__: 'field',
  };

  class Object {
    // Maps private names to values
    __PrivateFieldValues__ = new Map();
  }

  class Countdown {
    constructor(counter, action) {
      this.__PrivateFieldValues__.set(_counter, counter);
      this.__PrivateFieldValues__.set(_action, action);
    }
    dec() {
      if (this.__PrivateFieldValues__.get(_counter) < 1) return;
      this.__PrivateFieldValues__.set(
        _counter, this.__PrivateFieldValues__.get(_counter) - 1);
      
      if (this.__PrivateFieldValues__.get(_counter) === 0) {
        this.__PrivateFieldValues__.get(_action)();
      }
    }
  }
}
```

这里有两点很重要：

* *私有名称*是唯一的key。它们只能在class内访问。
* *私有属性的值*是一个**私有名称(key)=>值(value)的字典**。每个拥有私有属性的实例都有这样一个字典。只能通过私有变量的key访问其value。

意义：

* 在类`Countdown`中，只能访问存储在`.#counter` 和 `#action` 的私有数据——因为在这个类中你只有这两个私有变量。
* 私有属性不能被子类访问。

## 6. 陷阱：使用`this`访问私有静态属性

**你可以使用`this`访问公有静态属性，但是你不应该使用它访问私有静态属性。**

### 6.1 `this`和静态公有变量

```js
class SuperClass {
  static publicData = 1;
  
  static getPublicViaThis() {
    return this.publicData;
  }
}
class SubClass extends SuperClass {
}
```

公有静态属性（Public static fields）是属性。如果我们用一个方法调用：

```js
assert.equal(SuperClass.getPublicViaThis(), 1);
```

`this`指向`SuperClass`，一切都按照我们预想的那样工作。我们也可以通过子类调用`.getPublicViaThis()`。

```js
assert.equal(SubClass.getPublicViaThis(), 1);
```

`SubClass`继承了`.getPublicViaThis()`方法，`this`指向`SubClass`，代码依旧可以运用，因为`SubClass`也继承了`.publicData`。

（注：在这种情况下设置`.publicData`会在`SubClass`上创建新的属性，这个属性不会覆盖在`SuperClass`上定义的属性）

### 6.2 `this`和私有静态属性

考虑这段代码：

```js
class SuperClass {
  static #privateData = 2;
  static getPrivateViaThis() {
    return this.#privateData;
  }
  static getPrivateViaClassName() {
    return SuperClass.#privateData;
  }
}
class SubClass extends SuperClass {
}
```

通过`SuperClass`可以调用`.getPrivateViaThis()`，因为`this`指向`SuperClass`：

```js
assert.equal(SuperClass.getPrivateViaThis(), 2);
```

然而，通过`SubClass`无法调用`.getPrivateViaThis()`，因为此时`this`指向`SubClass`，而`SubClass`没有私有静态变量`.#privateData`：

```js
assert.throws(
  () => SubClass.getPrivateViaThis(),
  {
    name: 'TypeError',
    message: 'Read of private field #privateData from' +
      ' an object which did not contain the field',
  }
);
```

解决办法是直接通过`SuperClass`访问`.#privateData`，就像`SuperClass`中的`getPrivateViaClassName`方法。

```js
assert.equal(SubClass.getPrivateViaClassName(), 2);
```

## 7. “友好”和“被保护的”隐私

有时候我们想要某些实体成为某一类的“朋友”。这个朋友应该可以访问calss的私有数据（译者注：这里其实就是想控制哪些可以访问私有属性，哪些不可以）。在以下代码中，函数`getCounter()`是类`Countdown`的朋友。我们通过使用`WeakMaps`生成私有数据，这样`Countdown`就允许朋友们访问该数据。

```js
const _counter = new WeakMap();
const _action = new WeakMap();

class Countdown {
  constructor(counter, action) {
    _counter.set(this, counter);
    _action.set(this, action);
  }
  dec() {
    let counter = _counter.get(this);
    if (counter < 1) return;
    counter--;
    _counter.set(this, counter);
    if (counter === 0) {
      _action.get(this)();
    }
  }
}
function getCounter(countdown) {
  return counter.get(countdown);
}
```

这样就很容易控制哪些可以访问私有数据：如果它们可以使用`_counter`和`_action`，它们就可以访问私有数据。如果我们将前面的代码片段放到一个模块中，那么数据在整个模块中是私有的。

有关此技术的更多信息，可以查看Sect的“[使用`WeakMaps`保持私有数据](https://exploringjs.com/impatient-js/ch_weakmaps.html#private-data-in-weakmaps)”。这同样适用于在superclass和subclass之间共享私有数据（“被保护”的可见度）。

## 8. FAQ

### 8.1 为什么是`#`？为什么不通过`private`属性声明私有属性？

原则上，私有属性应该用如下方式声明：

```js
class MyClass {
  private value;
  compare(other) {
    return this.value === other.value;
  }
}
```

但是我们不能在整个class内的任何地方使用属性名值——它们总是被解释为私有变量。

静态类型语言，例如TypeScript在这方面具有更多的灵活性：它们在编译的时候就知道是否是MyClass的一个实例并且可以是否将`.value`作为一个私有变量对待。

## key word

* class私有属性（private class fields）
* 静态私有属性（private static fields）
* 实例私有属性（private instance fields）
