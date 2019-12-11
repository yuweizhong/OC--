//
//  ViewController.m
//  KVO
//
//  Created by yuweizhong on 2019/11/19.
//  Copyright © 2019年 hexin. All rights reserved.
//

#import "ViewController.h"
#import "Person.h"

@interface ViewController ()

@property (nonatomic, strong) Person *person1;
@property (nonatomic, strong) Person *person2;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.person1 = [[Person alloc] init];
    self.person1.name = @"yuweizhong";
    
    self.person2 = [[Person alloc] init];
    self.person2.name = @"dog";
    
    [self.person1 addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"name"]) {
        NSLog(@"触发observe--%@",change);
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    static NSInteger count = 0;
    self.person1.name = [NSString stringWithFormat:@"yuweizhong-%ld",(long)count];
    self.person2.name = [NSString stringWithFormat:@"dog-%ld",(long)count];

    count++;
}

- (void)dealloc{
    [self removeObserver:self.person1 forKeyPath:@"name"];
}
@end
