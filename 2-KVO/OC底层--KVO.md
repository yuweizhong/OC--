# OC底层--KVO
KVO对于我们iOS开发，大家应该并不陌生。那么，我们平时在使用KVO时候有没有考虑过这些问题呢
> 1. KVO底层是怎么实现的呢，如何实现监听的呢？
> 2. 我们修改监听对象的成员变量，会有效果吗？
> 3. 我们能否自己手动来实现KVO呢？


## KVO概述
KVO(即Key-Value Observing)，俗称键值监听，可用用来监听某个对象属性值的改变。这是iOS观察者模式的一种实现，和NSNotification不同的是，KVO是一对一的监听，即一个观察者对应一个被观察者

## KVO使用
参见demo，具体不做赘述... 主要涉及以下两个方法 添加监听和通知监听者


```
- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(nullable void *)context;

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change context:(nullable void *)context;

```

## KVO底层实现
想要窥探KVO的底层实现，我们先来看看 添加监听后的对象和原来的对象有什么区别?
初始化了两个Person对象 person1 添加了监听，我们先来看看两个对象的isa指针有什么区别？

```
    self.person1 = [[Person alloc] init];
    self.person1.name = @"yuweizhong";
    self.person2 = [[Person alloc] init];
    self.person2.name = @"dog";
    [self.person1 addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
```
![](https://github.com/yuweizhong/OC--/blob/master/2-KVO/kvo_pic_1.png)

我们可以看到person1 的isa指针指向的是 NSKVONotifying_Person，看到这里，嗯？上次说过实例对象的isa指针应该是指向对应类对象，讲道理应该是Person类的？？？person2 正常... 我们猜想，是不是苹果在中间做了什么？这个NSKVONotifying_Person 又是什么类呢？其次，我们知道修改属性值相当于调用了set方法修改成员变量，我们来看下添加监听后的set方法...

![](https://github.com/yuweizhong/OC--/blob/master/2-KVO/kvo_pic_2.png)

我们可看到 person2 对象的setName:方法还是调用了Person类的setName:方法，也可以看到在Person.m的第22行;再看person1，实现是调用了Foundation框架的C函数 _NSSetObjectValueAndNotify.

由于是Foundation框架，我们无法查看其内部实现(感兴趣的可以去搜索下GNUStep，重新实现了cocoa库的OC源码，有一定参考价值)。所以，我们尝试在Person类中手动实现willChangeValueForKey:和didChangeValueForKey:者两个方法并打印，看看有什么信息可以窥探...

![](https://github.com/yuweizhong/OC--/blob/master/2-KVO/kvo_pic_3.png)

敲黑板...Summary
> 综上所述，我们可以发现当我们为一个对象添加监听者时，Runtime会动态生成类对象 NSKVONotifying_XXX(原来XXX的子类)，将原来实例对象的isa指针指向该类，该类内部实现了对应的setXxx:方法,该方法内部实现为Foundation框架的_NSSetObjectValueAndNotify方法(根据属性类型方法名不同int bool or other...)

每次被观察者属性值被修改是，大致经过以下过程:
> 1. 首先调用willChangeValueForKey: 方法
> 2. 调用set方法修改属性值
> 3. 调用didChangeValueForKey:方法，再通知对应监听者，会调用observeValueForKeyPath:方法

那么我们来看开头提出的几个问题
###  我们修改监听对象的成员变量，会有效果吗？
应该是不会有的，修改成员变量不会调用set方法，如果需要手动实现可以前后调用willChangeValueForKey: 和 didChangeValueForKey: 方法


## 手动实现KVO

...