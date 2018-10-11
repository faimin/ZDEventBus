//
//  ZDEventBus.h
//  ZDEventBus
//
//  Created by Zero.D.Saber on 2018/8/13.
//  Copyright © 2018年 Zero.D.Saber. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"
typedef void(^_Nullable ZDSubscribeNext)();
#pragma clang diagnostic pop

//================================================================

@interface ZDEventBus<__covariant Subscriber : NSObject *> : NSObject

@property (class, nonatomic, readonly) ZDEventBus *shareBus;

+ (void)subscribeEvent:(NSString *)eventName subscriber:(Subscriber)subscriber next:(ZDSubscribeNext)subscribeNext;
// needn't use it, unless you want to unsubscribe early
+ (void)unsubscribeEvent:(NSString *)eventName subscriber:(Subscriber)subscriber;

+ (void)dispatchEvent:(NSString *)eventName values:(void(^)(ZDSubscribeNext deliverValuesBlock))wrapCallbackBlock;
+ (void)dispatchEvent:(NSString *)eventName onQueue:(nullable dispatch_queue_t)onQueue values:(void(^)(ZDSubscribeNext deliverValuesBlock))wrapCallbackBlock;

@end

//================================================================

@interface NSObject (ZDEventBus)

- (void)subscribeEvent:(NSString *)eventName next:(ZDSubscribeNext)subscribeNext;

- (void)dispatchEvent:(NSString *)eventName values:(void(^)(ZDSubscribeNext deliverValuesBlock))wrapCallbackBlock;

@end

//================================================================

#define ZDEventBusDispatchEvent(eventName, ...) \
[ZDEventBus dispatchEvent:eventName onQueue:nil values:^(ZDSubscribeNext deliverValuesBlock) {\
    deliverValuesBlock(__VA_ARGS__);            \
}];

NS_ASSUME_NONNULL_END
