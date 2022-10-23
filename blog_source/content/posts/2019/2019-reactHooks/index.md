---
title: 简述 React Hooks 特征和使用方式
date: 2019-03-24
tags:
  - React
categories:
  - React
draft: false
---

>学习React Hooks简单记录一下官方文档关于Hooks的一些特征和使用方式，摘录自官方文档。后续使用后，再做总结
<!--more-->
### Basic React Hooks

#### useState

```js
const [data, setData] = useState(initData);
```

useState返回一个数组，数组内第一个元素是state的值，初始值为initState，利用js的结构将该数组解构赋值，如果设置多个state可以多次调用useState，但是useState也可以传入一个数组，数组内的项为多个initState，是否可以声明多个state的时候使用一个useState有待研究，后续看下项目

#### useEffect

用于写有副作用的代码，可以实现生命周期中的`componentDidMount`，`componentUpdate`，`componentWillUnmount`。

```js
useEffect(() => {
    effect code...
    return () => {
        cleanup code
    }
})
```

`useEffect`可以添加回调，在effect code执行完成后执行，在`useEffect`中的代码React每次渲染，都会执行，这也意味着性能的损耗（无论是否真的需要执行，state跟之前是否一样），在class组件中可以使用`componentDidUpdate`：

```js
componentDidUpdate(prevProps, prevState) {
if (prevState.count !== this.state.count) {
    document.title = `You clicked ${this.state.count} times`;
}
```

在hooks中可以使用`useEffect`的第二个参数

```js
useEffect(() => {
  document.title = `You clicked ${count} times`;
}, [count]); // Only re-run the effect if count changes
```

如果使用该优化，确保数组包含了来自组件的所有随着时间会变化的value，但是这样实现的是类似于`componentDidUpdate`，如果想实现`componentDidMount`和`componentWillUnmount`，需要给`useEffect`第二个参数添加空数组`[]`，这相当于告诉React当前`useEffect`中的代码不依赖任何来自`state`或`props`的值，所以不需要re-render。

#### useContext

```js
const value = useContext(MyContext);
```

### Additional Hooks

#### useReducer

```js
const [state, dispatch] = useReducer(reducer, initialArg, init);
```

使用demo

```js
const initialState = {count: 0};

function reducer(state, action) {
  switch (action.type) {
    case 'increment':
      return {count: state.count + 1};
    case 'decrement':
      return {count: state.count - 1};
    default:
      throw new Error();
  }
}

function Counter({initialState}) {
  const [state, dispatch] = useReducer(reducer, initialState);
  return (
    <>
      Count: {state.count}
      <button onClick={() => dispatch({type: 'increment'})}>+</button>
      <button onClick={() => dispatch({type: 'decrement'})}>-</button>
    </>
  );
}
```

React可以确保`dispatch`函数功能的稳定并且在re-render时候不会改变

##### 懒初始化initState

使用`useReducer`的第三个参数，demo如下

```js
function init(initialCount) {
  return {count: initialCount};
}

function reducer(state, action) {
  switch (action.type) {
    case 'increment':
      return {count: state.count + 1};
    case 'decrement':
      return {count: state.count - 1};
    case 'reset':
      return init(action.payload);
    default:
      throw new Error();
  }
}

function Counter({initialCount}) {
  const [state, dispatch] = useReducer(reducer, initialCount, init);
  return (
    <>
      Count: {state.count}
      <button
        onClick={() => dispatch({type: 'reset', payload: initialCount})}>

        Reset
      </button>
      <button onClick={() => dispatch({type: 'increment'})}>+</button>
      <button onClick={() => dispatch({type: 'decrement'})}>-</button>
    </>
  );
}
```

#### useCallback

```js
const memoizedCallback = useCallback(
  () => {
    doSomething(a, b);
  },
  [a, b],
);
```

返回记忆化的回调。

该hooks用于实现类似于`shouldComponentUpdate`的功能。 用于防止不必要的渲染

`useCallback(fn, deps)`相当于`useMemo(() => fn, deps)`

#### useMemo

```js
const memoizedValue = useMemo(() => computeExpensiveValue(a, b), [a, b]);
```

返回一个记忆化的值。

>在计算机科学中，记忆化（英语：memoization而非memorization）是一种提高程序运行速度的优化技术。通过储存大计算量函数的返回值，当这个结果再次被需要时将其从缓存提取，而不用再次计算来节省计算时间。 记忆化是一种典型的时间存储平衡方案。

传递“create”函数和依赖项数组。`useMemo`只会重新计算那些依赖发生变化的记忆化的值。这种优化避免了每次渲染的昂贵计算。

传递给`useMemo`的函数在渲染期间运行，所以不能传递带有副作用的函数。

如果没有数组提供，在每次渲染都会计算新值。

#### useRef

```js
const refContainer = useRef(initialValue);
```

`useRef`返回值的`.current`属性就是给`useRef`传递个初始value。返回的object将可以在整个生命周期使用。

使用demo

```js
function TextInputWithFocusButton() {
  const inputEl = useRef(null);
  const onButtonClick = () => {
    // `current` points to the mounted text input element
    inputEl.current.focus();
  };
  return (
    <>
      <input ref={inputEl} type="text" />
      <button onClick={onButtonClick}>Focus the input</button>
    </>
  );
}
```

`useRef`在内容变更时不会通知你，`.current`变化不会导致re-render。

#### useImperativeHandle

```js
useImperativeHandle(ref, createHandle, [deps])
```

`useImperativeHandle`自定义使用ref时公开给父组件的实例值，和通常一样，应该避免使用refs的命令式代码，`useImperativeHandle`应该使用`forwardRef`。

```js
function FancyInput(props, ref) {
  const inputRef = useRef();
  useImperativeHandle(ref, () => ({
    focus: () => {
      inputRef.current.focus();
    }
  }));
  return <input ref={inputRef} ... />;
}
FancyInput = forwardRef(FancyInput);
```

#### useLayoutEffect

与`useEffect`相同，但是是在所有的DOM变化完成后同步触发。在浏览器绘制之前，将在`useLayoutEffect`内部计划的更新将同步刷新，该方法会组织views的更新，但是`useEffect`是异步的，所以不会阻止。