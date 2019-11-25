//
//  ViewController.m
//  OC对象本质
//
//  Created by yuweizhong on 2019/11/5.
//  Copyright © 2019年 hexin. All rights reserved.
//

#import "ViewController.h"
#import <objc/runtime.h>
#import <malloc/malloc.h>
#import "Person.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSObject *obj = [[NSObject alloc] init];
    NSLog(@"Obj: sizeof %lu,instanceSize %lu,mallocSize %lu",sizeof(obj),class_getInstanceSize([NSObject class]),malloc_size(CFBridgingRetain(obj)));
    
    Person *person = [[Person alloc] init];
    person.age = 10;
    person.height = 160;
    person.weight = 70;
    NSLog(@"Person: sizeof %lu,instanceSize %lu,mallocSize %lu",sizeof(person),class_getInstanceSize([Person class]),malloc_size(CFBridgingRetain(person)));

    
}


@end
