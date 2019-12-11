//
//  Person.m
//  KVO
//
//  Created by yuweizhong on 2019/11/19.
//  Copyright © 2019年 hexin. All rights reserved.
//

#import "Person.h"

@implementation Person

- (void)willChangeValueForKey:(NSString *)key{
    NSLog(@"%s",__func__);
    [super willChangeValueForKey:key];
}

- (void)didChangeValueForKey:(NSString *)key{
    NSLog(@"%s",__func__);
    [super didChangeValueForKey:key];
}
- (void)setName:(NSString *)name{
    NSLog(@"%s",__func__);
    _name = name;
}
@end
