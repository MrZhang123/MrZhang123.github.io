---
title: Go 并发编程初识
date: 2022-06-11
tags: 
- golang
- 并发
categories: 
- 并发
series:
- golang 
draft: false
---

Go 有两种并发编程的风格：
* 通讯顺序进程（Communicating Sequential Process，CSP），主要使用 goroutine和通道（channel）。CSP是一个并发的模式，在不同的执行体（goroutine）之间传递至，但是变量本身局限局限于单一的执行体。
* 传统的共享内存多线程。

# goroutine 和通道

## goroutine

> 在 Go 里，每一个并发执行的活动称为 goroutine。

当一个程序启动时，只有一个 goroutine 来调用 `main` 函数，它被称为 main goroutine。新的 goroutine 通过 go 语句进行创建。

停止 goroutine 的方式：

* 从 `main` 函数返回
* 退出程序
* 和 goroutine 通信来要求它自己停止

## 通道

如果说 goroutine 是 Go 程序并发的执行体，通道就是它们之间的连接。通道是可以让一个 goroutine 发送特定值到另一个 goroutine 的通信机制。每一个通道是一个具体类型的导管，叫做通道的元素类型。

### 创建

使用内置的 `make` 函数可以创建一个通道：

```go
ch := make(chan int)
```

与 `map` 一样，通道也是一个使用 `make` 创建的数据结构的**引用**，所以通道的零值是 `nil`。

### 通道的操作

通道主要有两个操作：发送（send）和接收（receive），二者统称为通信。发送语句中，通道和值分别在 `<-` 的左右两边。接收表达式中，`<-` 放在通道操作数前面。

```go
ch <- x // 发送语句
x = <- ch // 赋值语句中的接收表达式
<- ch // 接收语句，丢弃结果
```
通道支持的第三个操作：关闭（close），它设置一个标志位来指示值当前已经发送完毕，这个通道后面没有值了。

```go
close(ch)
```
关闭后的发送操作将导致 panic。在一个已经关闭的通道上进行接收操作，将获取所有已发送的值，直到通道为空，这时任何接收操作会立即完成，同时获取到一个通道元素类型对应的零值。

### 无缓冲通道与缓冲通道

简单`make`调用创建的通道是无缓冲通道（unbuffered），`make`还可以接受第二个可选参数，表示通道容量。如果容量是0，`make`创建的就是一个无缓冲通道。

```go
ch = make(chan int) // 无缓冲通道
ch = make(chan int, 0) // 无缓冲通道
ch = make(chan int, 3) // 容量为3的缓冲通道
```

使用无缓冲通道进行通信导致发送和接收 goroutine 同步化。

### 管道

通道可以用来连接 goroutine ，这样一个输出是另一个的输入。这就叫做管道（pipeline）。当关闭的通道被读完后，后续所有的接收操作接收到的都是零值。

判断一个通道是否关闭

接收操作会产生两个结果：接收到的通道元素，以及一个布尔值，它为`true`则表示接收成功，`false`表示当前的接收操作在一个关闭的并且读完的通道上。

```go
go func () {
  for {
    x, ok := <- naturals
    if !ok {
      break
    }
    squares <- x * x
  }
  close(squares)
}()
```
通道也可以通过`range`进行遍历。

```go
func main() {
	naturals := make(chan int)
	squares := make(chan int)

	// counter
	go func() {
		for x := 0; x < 100; x++ {
			naturals <- x
		}
		close(naturals)
	}()

	// squares
	go func() {
		for x := range naturals {
			squares <- x * x
		}
		close(squares)
	}()

	for x := range squares {
		fmt.Println(x)
	}
}
```
通道用完后，不是一定要有`close`操作，只有在通知接收方 goroutine 所有数据都发送完毕时才需要显式关闭。垃圾回收器根据通道是否可以被访问来确定通道是否要被回收，跟是否关闭无关。

### 单向通道

通道默认是既可以入也可以出，但是在开发过程中，当一个通道用作函数行参的时，一般都会有意地限制不能发送或不能接收。虽然可以做约定，但是还是可能会出现误用，因此 Go 类型系统提供了单向通道类型，仅仅到处发送或接收操作。

```go
// 只能发送的通道类型
chan <- int
// 只能接收到通道类型
<- chan int
```


```go
func counter(out chan<- int) {
  for x:= 0; x<100; x++ {
    out <- x
  }
  close(out)
}

func main() {
  naturals := make(chan int)
  go counter(naturals)
}
```

这里`counter(naturals)`的调用**隐式**地将`chan int`类型转换为参数要求的`chan <- int`类型。在任何赋值操作中将**双向通道转换为单项通道都是允许的**，但是反过来是不行的。

### 缓冲通道

缓冲通道有一个**元素队列**，队列的长度在创建的时候通过`make`的容量参数来设置。

```go
ch := make(chan string, 3)
```

如果通道满了，发送操作会阻塞所在的 goroutine 直到另一个 goroutine 对通道内的数据进行了接收，有可用空间。反过来，如果通道是空，则执行接受操作的 goroutine 阻塞。

通过`cap`函数可以获取通道缓冲区的容量大小。通过`len`函数获取当前通道内的元素个数。

>将缓冲通道作为队列在单个 goroutine 中使用是错误的。通道和 goroutine 的调度深度关联，如果没有另一个 goroutine 从通道进行接收，发送者（也许是整个程序）有被永久阻塞的风险。如果仅仅需要一个简单队列，应该使用`slice`。

## 并行循环

根据图像文件生成缩略图：

```go
// makeThumbanils 生成指定文件的缩略图
func makeThumbanils(filenames []string) {
  for _,f := range filenames {
    if _, err := imageFiles(f); err != nil {
      log.Println(err)
    }
  }
}
```

由于以上生成缩略图和顺序并无关系，所以可以使用`go`来实现并行。但是直接使用`go imageFiles(f)`会导致不等缩略图生成就返回。所以需要让函数等待缩略图生成完成，可以通过使用通道在生成完成后通知发送一个完成的消息。改造方式如下：

```go
func makeThumbanils(filenames []string) {
  ch := make(chan struct{})
  for _,f := range filenames {
    go func(f string) {
      imageFiles(f)
      ch <- struct{}{}
    }(f) // 显式传入参数f
  }
  for range filenames {
    <- ch
  }
}
```

{{< admonition info >}}
这里需要注意一点，上面的变量`f`的值被所有的匿名函数值共享并且被后续的迭代所更新。这时新的 goroutine 执行字面量函数，for 循环可能已经更新`f`，并且开始另一个迭代或者已经完成结束，所有当这些 goroutine 读取 f 的值时，它们所看到的都是`slice`的最后一个元素。通过添加显式参数，可以确保当`go`语句执行的时候，`f`是当前值。
{{< /admonition >}}

以上就是使用`chan`让 goroutine 进行等待。但其实在实践中`chan`更多的用于 goroutine 之间的通信，如果只是单纯的等待任务执行完成，更常用的是`WaitGroup`并发原语。具体操作如下：

```go
var filenames = []string{"a", "b", "c", "d"}

func waitFunc(f string) {
	rand.Seed(time.Now().UnixNano())
	sleepTime := rand.Intn(10) * 100
	time.Sleep(time.Duration(sleepTime) * time.Millisecond)
	fmt.Printf("f=%s, sleepTime=%d\n", f, sleepTime)
}

func waitGroupFunc() {
	var wg sync.WaitGroup
	for _, f := range filenames {
		wg.Add(1)
		go func(f string) {
			defer wg.Done()
			waitFunc(f)
		}(f)
	}
	wg.Wait()
}

func main() {
	waitGroupFunc()
}

```

* `Add`：用来设置`WaitGroup`的计数值；
* `Done`："用来将`WaitGroup`的计数值减少1，其实就是调用了`Add(-1)`；
* `Wait`：调用这个方法的 goroutine 会一直阻塞，直到`WaitGroup`的计数值变为0。

## 使用 Select 多路复用

`select`语句的基本形式如下：

```go
select {
case <-ch1:
	//...
case x := <-ch2:
	//...
case ch3 <- y:
	//...
default:
	//...
}
```
`select`语句和`switch`语句一样，它有一系列的情况和一个**可选**的默认分支。每一个情况指定一次通行和关联的一段代码块。接收表达式操作可能像第一种情况那样出现在它本身上，或者像第二种情况那样出现在短变量声明中；第二种情况可以引用所接收的值。

`select`会一直等待，直到一次通信告知有一些情况可以执行。

**如果多个情况同时满足，`select`会随机选择一个，这样保证每一个通道都有相同的机会被选中。**

```go 
ch := make(chan int, 1)
for i := 0; i < 10; i++ {
  select {
  case x := <-ch:
    fmt.Println(x) // 0,2,4,6,8
  case ch <- i:
  }
}
```

# 使用共享变量实现并发

## 竞态

当一个程序有两个或多个 goroutine 时，每个 goroutine 内部的各个步骤也是顺序执行的，但我们无法知道一个 goroutine 中的事件 x 和另外一个 goroutine 中的事件 y 的先后顺序。如果无法肯定的说一个事件肯定先于另一个事件，那么这两个事件就是**并发**的。

如果一个能在串行程序中执行正确的函数，在并发调用时仍然执行正确，，那么就说这个函数是**并发安全的**(concurrency-safe)。如果一个类型的所有可访问方法和操作都是并发安全的，则它可称为并发安全的类型。

竟态是指在多个 goroutine 按照某些交错的顺序执行时程序无法给出正确的结果。

两个 goroutine 并发读写同一个变量并且至少其中一个写入时可能会发生数据竞态(data race)。

下面一个例子：

```go
var balance int

func Deposite(amount int) { balance = balance + amount }
func Balance() int        { return balance }

func main() {
  // A
	go func() {
		Deposite(200) // A1
		fmt.Println("=", Balance()) // A2
	}()
  // B
	go Deposite(100)
}
```
直接告诉我们，可能有以下三种情况：

| A先       | B先       | A / B / A |
| --------- | --------- | --------- |
| 0         | 0         | 0         |
| A1: 200   | B:  200   | A1: 200   |
| A2: = 200 | A1: 300   | B:  300   |
| B: = 300  | A2: = 300 | A2: = 300 |

但其实还有第四种情况——数据竞态，B 的操作在 A 操作中间执行，晚于数据读取 A1 read `balance + amount`，早于数据更新 A1 write `balance = `，这会导致 B 的操作消失，具体过程如下：

| 操作     | 值   |
| -------- | ---- |
| A1 read  | 0    |
| B        | 100  |
| A1 write | 200  |
| A2       | =200 |

当发生数据竞态的变量类型是大于一个机器字长的类型（如接口、字符串或slice）时，会出现更复杂的情况：

```go
func main() {
	var x []int
	go func() {
		x = make([]int, 10)
	}()
	go func() {
		x = make([]int, 100000)
	}()
	time.Sleep(1 * time.Millisecond)
	x[99999] = 1
}
```
可能出现运行结果如下：

```bash
panic: runtime error: index out of range [99999] with length 10

goroutine 1 [running]:
main.main()
        /go_practice/main.go:25 +0x13c
exit status 2
```

但是还有一种更诡异的情况是：由于`slice`是由指针、长度和容量三部分组成的，如果指针来自第一个`make`而长度来自第二个`make`，那么变量x会变成一个嵌合体，它名义上长度是100000，但实际上底层数组只有10个元素。

有三种方式可以避免数据竞态：
1. 不要修改变量。
2. 避免多个 goroutine 访问同一个变量

即只允许唯一一个 goroutine 访问该变量，其他 goroutine 想要访问，必须使用通道来向受限 goroutine 发送查询请求或更新变量。

>Go 箴言：“不要通过共享内存来通信，而应该通信来共享内存”。

看下面这个例子：
```go
var deposites = make(chan int)
var balances = make(chan int)

func Deposite(amount int) { deposites <- amount }
func Balance() int        { return <-balances }

func teller() {
	var balance int
	for {
		select {
		case amount := <-deposites:
			balance += amount
		case balances <- balance:
		}
	}
}

func init() {
	go teller()
}
```

3. 允许多个 goroutine 访问同一个变量，但是在同一时间只有一个 goroutine 可以访问。这种方法称为互斥机制。即使用互斥锁`sync.Mutex`。

## 互斥锁`sync.Mutex`

```go
var (
	mu       sync.Mutex
	balances int
)

func Deposite(amount int) {
	mu.Lock()
	defer mu.Unlock()
	balance += amount
}

func Balance() int {
	mu.Lock()
	defer mu.Unlock()
	return balance
}
```

在`Lock`和`Unlock`之间的代码，可以自由地读取和修改共享变量，这一部分称为*临界区域*。

>虽然`defer`的执行成本比显式调用`Unlock`的略大，但是在处理并发时，永远应当优先考虑清晰度，拒绝过早优化。在可以使用的地方，就尽量使用`defer`来让临界区扩展到函数结尾处。

**Go 的互斥锁是不能再入的，即无法对一个已经上锁的互斥量再上锁，这会导致死锁。**

## 读写互斥锁：`sync.RWMutex`

有时候我们允许读并发进行而写则需要完全独享，这时候就可以使用读写互斥锁`sync.RWMutex`，它允许只读操作并发执行而写操作需要获得完全独享的访问权限。`RLock`和`RUnlock`方法分别用来获取和释放一个**读锁（也称共享锁）**。`Lock`和`Unlock`来分别获取和释放一个**写锁（互斥锁）**。

>仅在绝大部分 goroutine 都在获取读锁并且写锁竞争比较激烈时（即 goroutine 一般都需要等待后才能获取到锁），`RWMutex`才有优势。因为`RWMutex`需要复杂的内部工作，所以在竞争不激烈时它比普通锁慢。

## 内存同步

需要互斥锁的原因有两个：
1. 防止某个操作插入到其他操作中间；
2. 同步不仅涉及多个 goroutine 的执行顺序问题，还会影响到内存。

现代的计算机一般都会有多个处理器，每个处理器都有内存的本地缓存。 **为了提高效率，对内存的写入是缓存在每个处理中的，只有在必要时才刷回内存。甚至刷回内存的顺序都可能和 goroutine 的写入顺序不一致。** 同步元语（例如通道通信或互斥锁操作）会导致处理器把积累的写操作刷回内存并提交。

```go
var x, y int

go func() {
  x = 1
  fmt.Println("y=", y)
}()

go func() {
  y = 2
  fmt.Println("x=", x)
}()
```

由于以上操作存在数据竞态，所以直觉告诉我们，上面的代码可能产生以下四种结果：

```sh
y=0, x=1
x=0, y=1
x=1, y=1
y=1, x=1
```

但事实上，除了以上四种结果外，还可能产生如下两种结果：

```
x=0, y=0
y=0, x=0
```

原因在于，在单个 goroutine 内，每个语句的效果保证按照执行的顺序发生，也就是说，**goroutine 是串行一致的**，但是 **在缺乏使用通道或者互斥量来显式同步的情况下，并不能保证所有的 goroutine 看到的事件都是一致的。** 所以尽管 goroutineA 肯定能在读取 y 之前观察到 x=1 的效果，但是它不一定能观察到 goroutineB 对 y 的写入效果。

{{< admonition tip >}}
这里解释一下【串行一致】的含义，所谓串行一致，指的是在程序执行过程中，因为一些优化，可能会修改指令的执行顺序，但是这些修改不应该改变程序运行的结果。此处关键在于为了优化修改执行顺序，但是不影响运行结果。
{{< /admonition >}}

尽管很容易把并发简单理解成多个 goroutine 中语句的某种交错执行方式，但是现代 CPU 并不是这样工作的。因为赋值和`Print`对应不同的变量，所以编译器可能会认为两个语句的执行顺序不会影响结果，然后交换了两个语句的执行顺序。CPU 也有类似的问题，如果两个 goroutine 在不同的 CPU 上执行，每个 CPU 都有自己的缓存，那么一个 goroutine 的写入操作在同步到内存之前对另外一个 goroutine 的 `Print` 语句是不可见的。

## 延迟初始化：sync.Once

很多时候，延迟一个昂贵的初始化操作是很有必要的，例如下面这个例子：

```go
var icons map[string]int

func loadIcons() {
	icons = map[string]int{
		"speed": 1,
		"sleep": 2,
		"data":  3,
	}
}

func Icon(name string) int {
	if icons == nil {
		loadIcons()
	}
	return icons[name]
}
```

但是上面这个例子中 icons 方法是并发不安全的。直觉告诉我们是因为 Icon 方法在并发的时候可能会导致多次调用 loadIcons 方法。但是这个直觉是错误的，在缺乏明显同步的情况下，**编译器和 CPU 在能保证每个 goroutine 都满足串行的一致性的基础上可以自由地重排访问内存的顺序**。因此 loadIcons 一个可能的语句重排结果如下，它在填充数据之前把一个空 map 赋给 icons：

```go
func loadIcons() {
  icons = make(map[string]int)
  icons["speed"] = 1
  icons["sleep"] = 2
  icons["data"] = 3
}
```

{{< admonition tip >}}
这里再解释一下为什么会先创建一个空 map，然后再调用。由于初始化资源成本比较高，所以会在使用的时候才初始化，所以上面的代码只是为了优化性能而做的可能的重排结果。
{{< /admonition >}}

如果是按照上面的重排运行 loadIcons 函数，则一个 goroutine 发现 icons 不是 nil 并不意味着变量的初始化已经完成。因此需要加锁来保证同步，可以使用 sync 包提供的 `sync.Once` 方法解决。`Once` 包含一个布尔变量和一个互斥量，布尔变量记录初始化是否已完成，互斥量则负责保护这个布尔变量和客户端的数据结构。`Once` 的唯一方法 `Do` 以初始化函数为它的参数。具体修改如下：

```go
var loadIconOnce sync.Once
var icons map[string]int

func loadIcons() {
	icons = map[string]int{
		"speed": 1,
		"sleep": 2,
		"data":  3,
	}
}

func icon(name string) int {
	loadIconOnce.Do(loadIcons)
	return icons[name]
}
```
每次调用`Do(loadIcons)` 时会先锁定互斥量并检查里面的布尔变量。第一次调用时，布尔值为 `false` ，`Do` 会调用 loadIcons 然后将布尔值设置为 `true`。后续的调用相当于空操作，只是通过互斥量的同步来保证 loadIcons 对内存产生的效果对所有 goroutine 都是可见的。

以上就是 Go 中并发的总结。
