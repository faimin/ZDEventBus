//
//  ZDEventBus.m
//  ZDEventBus
//
//  Created by Zero.D.Saber on 2018/8/13.
//  Copyright © 2018年 Zero.D.Saber. All rights reserved.
//

#import "ZDEventBus.h"
@import ObjectiveC;

@interface NSObject (ZDEventBusSubscribe)
@property (nonatomic, copy) ZDSubscribeNext subscribeNext;
@end

@interface ZDEventBus ()
@property (nonatomic, strong) dispatch_semaphore_t lock;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSHashTable *> *subscribersDict;
//@property (nonatomic, strong) dispatch_queue_t dispatchEventQueue;
@end


@implementation ZDEventBus

- (void)dealloc {
    _lock = NULL;
}

+ (ZDEventBus *)shareBus {
    static ZDEventBus *bus = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bus = [[self alloc] init];
    });
    return bus;
}

- (instancetype)init {
    if (self = [super init]) {
        _lock = dispatch_semaphore_create(1);
        
        _subscribersDict = [[NSMutableDictionary alloc] init];
        //_dispatchEventQueue = dispatch_queue_create("com.zero.d.saber.queue.dispatchEvent", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, 0));
    }
    return self;
}

+ (void)subscribeEvent:(NSString *)eventName subscriber:(NSObject *)subscriber next:(ZDSubscribeNext)subscribeNext {
    if (!eventName || eventName.length == 0) return;
    if (!subscriber) return;
    
    subscriber.subscribeNext = subscribeNext;
    
    ZDEventBus *bus = [ZDEventBus shareBus];
    
    dispatch_semaphore_wait(bus.lock, DISPATCH_TIME_FOREVER);
    NSHashTable *subscribers = bus.subscribersDict[eventName];
    if (!subscribers) {
        subscribers = [NSHashTable weakObjectsHashTable];
    }
    [subscribers addObject:subscriber];
    bus.subscribersDict[eventName] = subscribers;
    dispatch_semaphore_signal(bus.lock);
}

+ (void)unsubscribeEvent:(NSString *)eventName subscriber:(NSObject *)subscriber {
    if (!eventName || eventName.length == 0) return;
    if (!subscriber) return;
    
    ZDEventBus *bus = [ZDEventBus shareBus];
    
    dispatch_semaphore_wait(bus.lock, DISPATCH_TIME_FOREVER);
    NSHashTable *subscribers = bus.subscribersDict[eventName];
    if ([subscribers containsObject:subscriber]) {
        [subscribers removeObject:subscriber];
        bus.subscribersDict[eventName] = subscribers;
    }
    dispatch_semaphore_signal(bus.lock);
}

+ (void)dispatchEvent:(NSString *)eventName values:(void(^)(ZDSubscribeNext deliverValuesBlock))wrapCallbackBlock {
    [self dispatchEvent:eventName onQueue:NULL values:wrapCallbackBlock];
}

+ (void)dispatchEvent:(NSString *)eventName onQueue:(dispatch_queue_t)onQueue values:(void(^)(ZDSubscribeNext deliverValuesBlock))wrapCallbackBlock {
    if (!eventName || eventName.length == 0) return;
    
    ZDEventBus *bus = [ZDEventBus shareBus];
    
    dispatch_semaphore_wait(bus.lock, DISPATCH_TIME_FOREVER);
    NSHashTable *subscribers = bus.subscribersDict[eventName];
    if (onQueue &&
        strcmp(dispatch_queue_get_label(dispatch_get_main_queue()), dispatch_queue_get_label(onQueue)) &&
        strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(onQueue))) {
        NSArray *allTargets = subscribers.allObjects; // guaranteed that the target will not be released when traversing
        dispatch_apply(subscribers.count, onQueue, ^(size_t i) {
            __kindof NSObject *target = allTargets[i];
            ZDSubscribeNext nextBlock = target.subscribeNext;
            wrapCallbackBlock(nextBlock);
        });
    }
    else {
        for (__kindof NSObject *target in subscribers) {
            ZDSubscribeNext nextBlock = target.subscribeNext;
            if (!nextBlock) continue;
            wrapCallbackBlock(nextBlock);
        }
    }
    dispatch_semaphore_signal(bus.lock);
}

@end

//-----------------------------------------------------------------------

@implementation NSObject (ZDEventBusSubscribe)

- (void)setSubscribeNext:(ZDSubscribeNext)subscribeNext {
    if (self.subscribeNext) return;
    objc_setAssociatedObject(self, @selector(subscribeNext), subscribeNext, OBJC_ASSOCIATION_COPY);
}

- (ZDSubscribeNext)subscribeNext {
    return objc_getAssociatedObject(self, @selector(subscribeNext));
}

@end

//-----------------------------------------------------------------------

@implementation NSObject (ZDEventBus)

- (void)subscribeEvent:(NSString *)eventName next:(ZDSubscribeNext)subscribeNext {
    [ZDEventBus subscribeEvent:eventName subscriber:self next:subscribeNext];
}

- (void)dispatchEvent:(NSString *)eventName values:(void(^)(ZDSubscribeNext deliverValuesBlock))wrapCallbackBlock {
    [ZDEventBus dispatchEvent:eventName values:wrapCallbackBlock];
}

@end
