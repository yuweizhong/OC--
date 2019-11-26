# OC底层--Objective-C对象本质
我们先来看几个个问题:

1.一个NSObject对象占多少内存？

2.OC对象的isa指针指向哪里？

3.OC对象的类信息，方法都存放在哪里

这就涉及到OC对象内存布局、isa指针以及类和元类等信息...所以我们今天就来剖析一下OC对象的本质...

## 一、OC中代码编译
首先，我们平常写的OC代码，都是面向对象的，底层实际都是C/C++代码；同时最后需要机器听懂，最后肯定是需要重新编译成对应的机器语言的。

Objective代码 -----> C/C++daima -----> 汇编代码 -----> 机器语言

所以，所有OC的面向对象都是基于C/C++的数据结构实现的。那么，OC对象、类都是基于C/C++的什么数据结构实现的呢？
> 结构体

既然OC底层是C/C++代码，我们肯定可以把它转换为对应的C/C++代码
```
xcrun -sdk iphoneos clang -arch arm64 (-framework Foundation/链接框架) -rewrite-objc OC源文件 -o 输出的cpp文件
```

大致了解了这些，我们回到一开始的那个问题，一个NSObject对象占用的内存大小:
##二、OC对象内存占用
我们先来看NSObject的定义:

```
@interface NSObject <NSObject> {
    Class isa  OBJC_ISA_AVAILABILITY;
}

typedef struct objc_class *Class;

struct objc_class {
    Class _Nonnull isa  OBJC_ISA_AVAILABILITY;

#if !__OBJC2__
    Class _Nullable super_class                              OBJC2_UNAVAILABLE;
    const char * _Nonnull name                               OBJC2_UNAVAILABLE;
    long version                                             OBJC2_UNAVAILABLE;
    long info                                                OBJC2_UNAVAILABLE;
    long instance_size                                       OBJC2_UNAVAILABLE;
    struct objc_ivar_list * _Nullable ivars                  OBJC2_UNAVAILABLE;
    struct objc_method_list * _Nullable * _Nullable methodLists                    OBJC2_UNAVAILABLE;
    struct objc_cache * _Nonnull cache                       OBJC2_UNAVAILABLE;
    struct objc_protocol_list * _Nullable protocols          OBJC2_UNAVAILABLE;
#endif

} OBJC2_UNAVAILABLE;
```
可用看到 一个NSObject对象里面有一个类指针（isa指针,这个后面介绍）,一个指针一般占用8个字节,那是不是一个NSObject就在内存中占用8个字节呢？
我们来打印一下一个NSObejct对象的内存大小，涉及到以下几个函数：
1. sizeof():一个运算符，可以计算某个类型的大小，在编译器确定
2. class_getInstanceSize()：获取某个对象实际占用的内存大小(至少占用多少存储空间)
3. malloc_size(): 某个对象实际分配的内存大小

2/3两个的差异主要在于部分编译器存在内存对其等等规则，导致得到结果不一样

好，我们来打印一下

```
    NSObject *obj = [[NSObject alloc] init];
    NSLog(@"Obj: sizeof %lu,instanceSize %lu,mallocSize %lu",sizeof(obj),class_getInstanceSize([NSObject class]),malloc_size(CFBridgingRetain(obj)));
```
得到结果分别是sizeof 8,instanceSize 8,mallocSize 16;【默认64位架构讨论】 那么为什么这个对象在内存中实际被分配了16的大小呢？我们来看下OC的源码，源码地址 [https://opensource.apple.com/tarballs/objc4/](https://opensource.apple.com/tarballs/objc4/)
![](https://github.com/yuweizhong/OC--/blob/master/1-OC%E5%AF%B9%E8%B1%A1/OC_Object_pic1.png)
我们发现源码中有这么一段，默认分配最小内存就是16

当然，还有其他的办法，比如内存查看工具、LLDB等等来验证以上说法:


* View Memory

调试模式，断电代码，po对象打印对象地址,Debug-ViewMenmory输入内存地址查看
![](https://github.com/yuweizhong/OC--/blob/master/1-OC%E5%AF%B9%E8%B1%A1/OC_Object_pic2.png)
从图中可以看到 后面的8个字节都是00，都是空的，实际只用到了前面的8个字节，这个也可以证明我们之前所说！

* LLDB(常用的LLDB指令看这篇 [常用LLDB指令](...))

通过x命令查看
![](https://github.com/yuweizhong/OC--/blob/master/1-OC%E5%AF%B9%E8%B1%A1/OC_Object_pic3.png)

**以上都是对NSOBject对象的分析，那么自定义对象呢？**
For Example: 自定义Person对象

```
@interface Person : NSObject

@property (nonatomic,assign) int age;
@property (nonatomic,assign) int height;
@property (nonatomic,assign) int weight;

@end
```
打印一下（代码与上类似，不贴了）得到结果
```
Person: sizeof 8,instanceSize 24,mallocSize 32
```
指针占用8个字节好理解，对象至少需要24个字节，这个似乎有点难解释（int类型占用4个字节 4x3+8 应该是20个字节啊...）实际分配内存也好理解（之前有提到过内存对齐，应该是和这个有关系，正好是16的倍数），那么为什么这个person对象实际需要24个字节呢？

我们知道OC底层都是C/C++实现的，那么一个OC对象在底层对应的就是结构体的数据结构**为结构体分配内存空间时，所分配的内存空间大小必须是结构体中占用最大内存空间成员所占用内存大小的倍数**，所以就是8的倍数 24啦啦啦...


## 三、OC对象分类

OC中对象大致可以分为以下三类: 

### 1. 实例对象(instance)
> 实例对象就是我们平时通过类alloc出来的对象，每次alloc都会生产新的实例对象。每个不同实例对象都在内存中占有着不同的内存地址。实例对象在内存中存储的信息主要有两个**1.isa指针 2.成员变量值**


### 2. 类对象(class)
> 实例对象的isa指针指向class对象(类对象)，我们通过class方法或者RuntimeAPI objc_getClass(instance class) 得到的对象。一个类的类对象是唯一的，在内存中只有一份。类对象在内存中存储的信息主要有**1.isa指针 2.superclass指针 3.类的属性信息(@property)，类的成员变量信息(ivar)、协议信息(@protocol) 4.类的对象方法信息**


### 3. 元类对象(meta-class)
>类对象的isa指针指向元类对象，我们通过RuntimeAPI objc_getClass(class) 得到的对象。每个类在内存中也只有一个元类对象。元类对象和类对象结构一样(用途不同)，可以通过class_isMetaClass()查看class是否为元类对象。元类对象存储信息主要有:**1.isa指针 2.superclass指针 3.类方法信息**

其实这个也好理解，因为实例对象允许在内存中会存在不止一份，每个实例对象的成员变量值 都不一样，所以成员变量值存放在实例对象中；

每个实例对象都指向同一个类对象，每个实例对象的属性、成员变量、协议和方法等信息都是一样的，所以放在类对象内，只有创建实例对象时才给具体的成员变量、属性等赋值。

对象方法是通过实例对象调用的，通过isa找到对应的类对象调用存放在类对象内的对象发放；而类方法是通过类对象直接调用的，同样的逻辑通过isa指针找到元类对象，调用存放在元类对象内的类方法。(注:这里我们暂且任务isa指针是直接指向类对象和元类对象的)

那么isa指针又是什么呢？接下去看:

## 四、OC中isa指针

我们来看下源码...



**讲到这里，自然要po出那张图了**
![]()

总结:
> instance的isa 指向class
> class的isa 指向meta-class
> meta-class的isa 指向基类的meta-class
> class的superclass 指向父类的class(如果没有父类，superclass为nil)
> meta-class的superclass 指向父类的meta-class(基类的meta-class的superclass指向 基类的class)
> instance调用对象方法的轨迹--**【isa找到class 方法不存在就通过superclass查找父类，一层层往上找】**
> class调用类方法的轨迹--**【isa找到meta-class 方法不存在就通过superclass查找父类】**

Attention:
> 在64-bit之后，isa需要进行一次位运算才能计算出实际的内存地址[isa & ISA_MASK]
> 在64-bit之前，isa只是一个普通的指针，在64-bit之后isa---union共用体，用位域来存放更多信息


```
# if __arm64__
#   define ISA_MASK        0x0000000ffffffff8ULL
#   define ISA_MAGIC_MASK  0x000003f000000001ULL
#   define ISA_MAGIC_VALUE 0x000001a000000001ULL
    struct {
        uintptr_t indexed           : 1;
        uintptr_t has_assoc         : 1;
        uintptr_t has_cxx_dtor      : 1;
        uintptr_t shiftcls          : 33; // MACH_VM_MAX_ADDRESS 0x1000000000
        uintptr_t magic             : 6;
        uintptr_t weakly_referenced : 1;
        uintptr_t deallocating      : 1;
        uintptr_t has_sidetable_rc  : 1;
        uintptr_t extra_rc          : 19;
#       define RC_ONE   (1ULL<<45)
#       define RC_HALF  (1ULL<<18)
    };

# elif __x86_64__
#   define ISA_MASK        0x00007ffffffffff8ULL
#   define ISA_MAGIC_MASK  0x001f800000000001ULL
#   define ISA_MAGIC_VALUE 0x001d800000000001ULL
    struct {
        uintptr_t indexed           : 1;
        uintptr_t has_assoc         : 1;
        uintptr_t has_cxx_dtor      : 1;
        uintptr_t shiftcls          : 44; // MACH_VM_MAX_ADDRESS 0x7fffffe00000
        uintptr_t magic             : 6;
        uintptr_t weakly_referenced : 1;
        uintptr_t deallocating      : 1;
        uintptr_t has_sidetable_rc  : 1;
        uintptr_t extra_rc          : 8;
#       define RC_ONE   (1ULL<<56)
#       define RC_HALF  (1ULL<<7)
    };

# else
    // Available bits in isa field are architecture-specific.
#   error unknown architecture
# endif

```
## 五、LLDB