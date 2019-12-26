# OC底层--KVC
## KVC简介

KVC(Key-Value Coding),俗称键值编码，在iOS中是通过key来取值的一种编码方式


## KVC使用

平常我们经常使用的api主要如下：
```
- (void)setValue:(nullable id)value forKey:(NSString *)key;
- (void)setValue:(nullable id)value forKeyPath:(NSString *)keyPath;
- (nullable id)valueForKey:(NSString *)key;
- (nullable id)valueForKeyPath:(NSString *)keyPath;
```

key和keyPath使用在我们平常修改属性时用法大致一致，主要在修改类中深层类的属性时候，keyPath可以指定更深层次路径...
KVO具体使用这里不做赘述，大家应该都比较熟悉。那么KVC又是如何赋值，又是如何取值的呢？

## KVC赋值和取值过程

首先来看setValue:forKey:
> 1. 按顺序查找setKey、_setKey方法，找到方法即调用方法传递参数
> 2. 未找到方法，调用accessInstanceVariblesDirectly方法获取返回值(是否允许直接进入对象的成员变量？)
> 3. 若该方法返回YES，按照_key,_isKey,key,isKey的顺序查找成员变量，找到则直接赋值，否则异常NSUnknownKeyException；
> 4. 若该方法返回NO,抛出异常NSUnknownKeyException；


再来看valueForKey:
> 1. 按顺序查找getKey、key、isKey、_key方法，找到方法即调用方法获取value
> 2. 未找到方法，调用accessInstanceVariblesDirectly方法获取返回值(是否允许直接进入对象的成员变量？)
> 3. 若该方法返回YES，按照_key,_isKey,key,isKey的顺序查找成员变量，找到则直接取值，否则异常NSUnknownKeyException；
> 4. 若该方法返回NO,抛出异常NSUnknownKeyException；

因此
#### KVC赋值会触发KVO嘛？
**答案是 会的，KVC第一步就是调用set方法 而KVO触发是调用willChangeValueForKey: 和 didChangeValueForKey: 方法(见上一章) **