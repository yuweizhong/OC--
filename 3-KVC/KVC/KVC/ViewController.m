//
//  ViewController.m
//  KVC
//
//  Created by yuweizhong on 2019/11/20.
//  Copyright © 2019年 hexin. All rights reserved.
//

#import "ViewController.h"
#import "Person.h"

@interface ViewController ()

@property (nonatomic, strong) Person *person;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.person = [[Person alloc] init];
    [self.person  setValue:@"yu" forKey:@"name"];
    
    NSLog(@"complete -- %@",[self.person  valueForKey:@"name"]);
    
    [self.person addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if([keyPath isEqualToString:@"name"]){
        NSLog(@"%@",change);
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.person  setValue:@"yuyuyu" forKey:@"name"];
}


@end
