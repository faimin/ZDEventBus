//
//  ZDEventBus.m
//  ZDEventBus
//
//  Created by Zero.D.Saber on 2018/8/13.
//  Copyright © 2018年 Zero.D.Saber. All rights reserved.
//

#import "ZDEventBus.h"
@import ObjectiveC;

//-----------------------------------------------------------------------

@interface NSObject (ZDEventBusSubscribe)

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableSet<ZDSubscribeNext> *> *zd_subscribeNextDict;

- (void)zd_addSubscribeNext:(ZDSubscribeNext)next forKey:(NSString *)eventName;

- (NSMutableSet<ZDSubscribeNext> *)zd_subscribeNextsForKey:(NSString *)eventName;

@end

//-----------------------------------------------------------------------

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
    
    [subscriber zd_addSubscribeNext:subscribeNext forKey:eventName];
    
    ZDEventBus *bus = [ZDEventBus shareBus];
    
    dispatch_semaphore_wait(bus.lock, DISPATCH_TIME_FOREVER);
    {
        NSHashTable *subscribers = bus.subscribersDict[eventName];
        if (!subscribers) {
            subscribers = [NSHashTable weakObjectsHashTable];
        }
        [subscribers addObject:subscriber];
        bus.subscribersDict[eventName] = subscribers;
    }
    dispatch_semaphore_signal(bus.lock);
}

+ (void)unsubscribeEvent:(NSString *)eventName subscriber:(NSObject *)subscriber {
    if (!eventName || eventName.length == 0) return;
    if (!subscriber) return;
    
    ZDEventBus *bus = [ZDEventBus shareBus];
    
    dispatch_semaphore_wait(bus.lock, DISPATCH_TIME_FOREVER);
    {
        NSHashTable *subscribers = bus.subscribersDict[eventName];
        if ([subscribers containsObject:subscriber]) {
            [subscribers removeObject:subscriber];
            bus.subscribersDict[eventName] = subscribers;
        }
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
    NSArray *allTargets = subscribers.allObjects; // guaranteed that the target will not be released when traversing
    dispatch_semaphore_signal(bus.lock);
    
    if (onQueue &&
        strcmp(dispatch_queue_get_label(dispatch_get_main_queue()), dispatch_queue_get_label(onQueue)) &&
        strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(onQueue))) {
        dispatch_apply(subscribers.count, onQueue, ^(size_t i) {
            __kindof NSObject *target = allTargets[i];
            NSMutableSet<ZDSubscribeNext> *set = [target zd_subscribeNextsForKey:eventName];
            for (ZDSubscribeNext nextBlock in set.copy) {
                wrapCallbackBlock(nextBlock);
            }
        });
    }
    else {
        for (__kindof NSObject *target in subscribers) {
            NSMutableSet<ZDSubscribeNext> *set = [target zd_subscribeNextsForKey:eventName];
            for (ZDSubscribeNext nextBlock in set.copy) {
                wrapCallbackBlock(nextBlock);
            }
        }
    }
}

@end

//-----------------------------------------------------------------------

@implementation NSObject (ZDEventBusSubscribe)

- (void)zd_addSubscribeNext:(ZDSubscribeNext)next forKey:(NSString *)eventName {
    if (!next || !eventName) return;
    
    dispatch_semaphore_wait([ZDEventBus shareBus].lock, DISPATCH_TIME_FOREVER);
    NSMutableSet *mutSet = self.zd_subscribeNextDict[eventName];
    if (!mutSet) {
        mutSet = [NSMutableSet set];
    }
    [mutSet addObject:next];
    self.zd_subscribeNextDict[eventName] = mutSet;
    dispatch_semaphore_signal([ZDEventBus shareBus].lock);
}

- (NSMutableSet<ZDSubscribeNext> *)zd_subscribeNextsForKey:(NSString *)eventName {
    if (!eventName) return nil;
    
    dispatch_semaphore_wait([ZDEventBus shareBus].lock, DISPATCH_TIME_FOREVER);
    NSMutableSet *set = self.zd_subscribeNextDict[eventName];
    dispatch_semaphore_signal([ZDEventBus shareBus].lock);
    return set;
}

#pragma mark - Property
- (void)setZd_subscribeNextDict:(NSMutableDictionary<NSString *, NSMutableSet *> *)zd_subscribeNextDict {
    objc_setAssociatedObject(self, @selector(zd_subscribeNextDict), zd_subscribeNextDict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableDictionary<NSString *, NSMutableSet<ZDSubscribeNext> *> *)zd_subscribeNextDict {
    NSMutableDictionary<NSString *, NSMutableSet<ZDSubscribeNext> *> *mutDict = objc_getAssociatedObject(self, _cmd);
    if (!mutDict) {
        mutDict = @{}.mutableCopy;
        self.zd_subscribeNextDict = mutDict;
    }
    return mutDict;
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
