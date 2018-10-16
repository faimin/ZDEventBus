//
//  ViewController.m
//  ZDEventBus
//
//  Created by Zero.D.Saber on 2018/8/13.
//  Copyright © 2018年 Zero.D.Saber. All rights reserved.
//

#import "ViewController.h"
#import "ZDEventBus.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [ZDEventBus subscribeEvent:@"ViewController" subscriber:self next:^(NSString *name, NSInteger age){
        NSLog(@"Event ViewController = %@ + %ld", name, (long)age);
    }];
    
    [ZDEventBus subscribeEvent:@"xxx" subscriber:self next:^(NSNumber *x, NSInteger i){
        NSLog(@"Event xxx = %@ + %ld", x, (long)i);
    }];
}

- (IBAction)tapAction:(id)sender {
    //dispatch_queue_t queue = dispatch_get_main_queue();
    dispatch_queue_t queue = dispatch_queue_create("com.zero.d.saber.queue.dispatchEvent", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, 0));
    dispatch_apply(pow(10, 2), dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^(size_t i) {
        [ZDEventBus dispatchEvent:@"ViewController" onQueue:queue values:^(ZDSubscribeNext deliverValuesBlock) {
            deliverValuesBlock(@"zero.d.saber", i);
        }];
        
        ZDEventBusDispatchEvent(@"xxx", @123456789, i);
    });
}

#pragma mark -

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
