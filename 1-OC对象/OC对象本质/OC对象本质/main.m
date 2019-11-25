//
//  main.m
//  OC对象本质
//
//  Created by yuweizhong on 2019/11/5.
//  Copyright © 2019年 hexin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "Person.h"
#import <malloc/malloc.h>
#import <objc/runtime.h>

@interface Student : NSObject{
    int _age;
}
@end

int main(int argc, char * argv[]) {
    @autoreleasepool {
        
        Person *person = [[Person alloc] init];
        person.age = 10;
        person.height = 160;
        person.weight = 70;
        NSLog(@"Person: sizeof %lu,instanceSize %lu,mallocSize %lu",sizeof(person),class_getInstanceSize([Person class]),malloc_size(CFBridgingRetain(person)));
        
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
