# OC底层--Category
## 一、什么是Category

首先，什么是Category？形势上就是XXX+AAA的一个类，俗称分类，类别。是对原来类的扩展，可以在不改变原有类的基础上，动态的为原来的类添加方法。
分类的优点主要在于:
1. 不改变原有类，动态为其添加方法，可用于分解体积庞大的类文件；
2. 可以将framework私有方法公开；
3. 可以模拟多继承
...
从源码上看

```
struct category_t {
    const char *name;
    classref_t cls;
    struct method_list_t *instanceMethods;
    struct method_list_t *classMethods;
    struct protocol_list_t *protocols;
    struct property_list_t *instanceProperties;

    method_list_t *methodsForMeta(bool isMeta) {
        if (isMeta) return classMethods;
        else return instanceMethods;
    }

    property_list_t *propertiesForMeta(bool isMeta) {
        if (isMeta) return nil; // classProperties;
        else return instanceProperties;
    }
};
```
分类实现的结构体包含分类名称、原来类，实例方法、类方法、协议和属性信息。
## 二、Category的使用
具体不做赘述 创建分类-引入分类即可使用分类中扩展的方法


## 三、Category加载与底层实现
> 从源码看 在objc-runtime-new.mm中，主要涉及方法_read_images、remethodizeClass、attachCategories...

源码阅读顺序
* objc-os.mm [_objc_init	map_images	map_images_nolock];
* objc-runtime-new.mm [_read_images remethodizeClass attachCategories attachLists realloc/memmove/memcpy] 

```
 for (EACH_HEADER) {
        category_t **catlist = 
            _getObjc2CategoryList(hi, &count);
        for (i = 0; i < count; i++) {
            category_t *cat = catlist[i];
            Class cls = remapClass(cat->cls);
            。。。//省略
            // Process this category. 
            // First, register the category with its target class. 
            // Then, rebuild the class's method lists (etc) if 
            // the class is realized. 
            bool classExists = NO;
            if (cat->instanceMethods ||  cat->protocols  
                ||  cat->instanceProperties) 
            {
                addUnattachedCategoryForClass(cat, cls, hi);
                if (cls->isRealized()) {
                    remethodizeClass(cls);
                    classExists = YES;
                }
                if (PrintConnecting) {
                    _objc_inform("CLASS: found category -%s(%s) %s", 
                                 cls->nameForLogging(), cat->name, 
                                 classExists ? "on existing class" : "");
                }
            }

            if (cat->classMethods  ||  cat->protocols  
                /* ||  cat->classProperties */) 
            {
                addUnattachedCategoryForClass(cat, cls->ISA(), hi);
                if (cls->ISA()->isRealized()) {
                    remethodizeClass(cls->ISA());
                }
                if (PrintConnecting) {
                    _objc_inform("CLASS: found category +%s(%s)", 
                                 cls->nameForLogging(), cat->name);
                }
            }
```

```
            // many lists -> many lists
            uint32_t oldCount = array()->count;
            uint32_t newCount = oldCount + addedCount;
            setArray((array_t *)realloc(array(), array_t::byteSize(newCount)));
            array()->count = newCount;
            memmove(array()->lists + addedCount, array()->lists, 
                    oldCount * sizeof(array()->lists[0]));
            memcpy(array()->lists, addedLists, 
                   addedCount * sizeof(array()->lists[0]));
```


**Summary**
> 1. 通过runtime加载某个类的所有Category数据
> 2. 所有Category的方法、属性、协议都会放到一个大数组中（后编译的Category会放在前面）
> 3. 将合并后的分类数据添加到原来类的前面

## 四、load && initialize

### load方法解读


源码阅读
objc-os.mm [_objc_init load_images prepare_load_methods call_load_methods call_class_loads call_category_loads...]

```
 classref_t *classlist = 
        _getObjc2NonlazyClassList(mhdr, &count);
    for (i = 0; i < count; i++) {
        schedule_class_load(remapClass(classlist[i]));
    }

    category_t **categorylist = _getObjc2NonlazyCategoryList(mhdr, &count);
    for (i = 0; i < count; i++) {
        category_t *cat = categorylist[i];
        Class cls = remapClass(cat->cls);
        if (!cls) continue;  // category for ignored weak-linked class
        realizeClass(cls);
        assert(cls->ISA()->isRealized());
        add_category_to_loadable_list(cat);
    }
```


```
static void schedule_class_load(Class cls)
{
    if (!cls) return;
    assert(cls->isRealized());  // _read_images should realize

    if (cls->data()->flags & RW_LOADED) return;

    // Ensure superclass-first ordering
    schedule_class_load(cls->superclass);

    add_class_to_loadable_list(cls);
    cls->setInfo(RW_LOADED); 
}
```


```
 do {
        // 1. Repeatedly call class +loads until there aren't any more
        while (loadable_classes_used > 0) {
            call_class_loads();
        }

        // 2. Call category +loads ONCE
        more_categories = call_category_loads();

        // 3. Run more +loads if there are classes OR more untried categories
    } while (loadable_classes_used > 0  ||  more_categories);
```

Summary
> 每个类和分类都会被调用load方法
> load方法不是通过消息转发机制调用的(objc_msgSend())，是通过内存地址调用的
> 先调用类的load方法(先编译 先调用)，在调用分类的load方法
> 先调用父类的load方法，再调用子类的
> load方法只会被调用一次

### initialize方法解读
+initialize 方法是通过消息转发机制调用的；故其源码的解读走objc_msgSend()的逻辑
objc-runtime-new.mm[class_getInstanceMethod lookUpImpOrNil lookUpImpOrForward _class_initialize]

```
    if (initialize  &&  !cls->isInitialized()) {
        _class_initialize (_class_getNonMetaClass(cls, inst));
        // If sel == initialize, _class_initialize will send +initialize and 
        // then the messenger will send +initialize again after this 
        // procedure finishes. Of course, if this is not being called 
        // from the messenger then it won't happen. 2778172
    }
    
step..

  supercls = cls->superclass;
    if (supercls  &&  !supercls->isInitialized()) {
        _class_initialize(supercls);
    }

step..

        ((void(*)(Class, SEL))objc_msgSend)(cls, SEL_initialize);

```


**Summary**
> initialize方法 会在类第一次接收到消息的时候被调用
> 先调用父类的initialize方法，在调用子类的initialize方法(即先初始化父类，再初始化子类)
> 【objc_msgSend调用】故如果子类未实现initialize方法，父类的initialize方法会被多次调用
> 如果分类实现了initialize方法，则会覆盖原本类的initialize方法


## 五、Category给类添加(关联)属性？
**Q:有没有办法给分类添加成员变量呢？**

**A:有！ 关联对象**

关联对象提供了以下API:
1、添加关联对象
	void
	objc_setAssociatedObject(id _Nonnull object, const void * _Nonnull key,
                         id _Nullable value, objc_AssociationPolicy policy)
2、获取关联对象
	id _Nullable
	objc_getAssociatedObject(id _Nonnull object, const void * _Nonnull key)
3、移除关联对象
void
objc_removeAssociatedObjects(id _Nonnull object)
    OBJC_AVAILABLE(10.6, 3.1, 9.0, 1.0, 2.0);

### 关联对象底层实现
objc-references.mm 【_object_set_associative_reference】
```
 ObjcAssociation old_association(0, nil);
    id new_value = value ? acquireValue(value, policy) : nil;
    {
        AssociationsManager manager;
        AssociationsHashMap &associations(manager.associations());
        disguised_ptr_t disguised_object = DISGUISE(object);
        if (new_value) {
            // break any existing association.
            AssociationsHashMap::iterator i = associations.find(disguised_object);
            if (i != associations.end()) {
                // secondary table exists
                ObjectAssociationMap *refs = i->second;
                ObjectAssociationMap::iterator j = refs->find(key);
                if (j != refs->end()) {
                    old_association = j->second;
                    j->second = ObjcAssociation(policy, new_value);
                } else {
                    (*refs)[key] = ObjcAssociation(policy, new_value);
                }
            } else {
                // create the new association (first time).
                ObjectAssociationMap *refs = new ObjectAssociationMap;
                associations[disguised_object] = refs;
                (*refs)[key] = ObjcAssociation(policy, new_value);
                object->setHasAssociatedObjects();
            }
        } else {
            // setting the association to nil breaks the association.
            AssociationsHashMap::iterator i = associations.find(disguised_object);
            if (i !=  associations.end()) {
                ObjectAssociationMap *refs = i->second;
                ObjectAssociationMap::iterator j = refs->find(key);
                if (j != refs->end()) {
                    old_association = j->second;
                    refs->erase(j);
                }
            }
        }
    }
```

> 关联对象底层通过AssociationsManager 管理，存储在全局的AssociationsHashMap中，以DISGUISE(object)为key，ObjectAssociationMap为value保存，ObjectAssociationMap以关联对象key作为key，ObjcAssociation为value保存，ObjcAssociation存放关联对象对应的policy和value。设置关联对象为nil就是移除关联对象

## 六、Category && Class Extension


### Class Extension

* 一般用来声明私有属性、私有成员变量和私有方法；
* 写在原来类的.m文件中
* 在编译期决议
* 不能为系统类添加扩展


### Category

* 一般用来为类增加方法（属性原则上不可以，可通过关联对象方式添加，也不是在原来类上添加，通过全局的AssociationsManager来管理）
* 以单独类的形势创建，形式上为 原类名+XXX
* 在运行期决议，依赖于Runtime






