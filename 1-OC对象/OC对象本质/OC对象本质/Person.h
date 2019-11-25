//
//  Person.h
//  OC对象本质
//
//  Created by yuweizhong on 2019/11/6.
//  Copyright © 2019年 hexin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Person : NSObject

@property (nonatomic,assign) int age;
@property (nonatomic,assign) int height;
@property (nonatomic,assign) int weight;

@end

NS_ASSUME_NONNULL_END
