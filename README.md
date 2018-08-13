# ZDEventBus

### 简单事件总线

#### 思路：

模仿系统通知方式简单实现了下（笔者觉得完全可以把系统通知封装一下来实现）。首先建立一个单例对象持有一个订阅关系表，事件名为`key`，订阅者集合为`value`；这里笔者为了简化(偷懒)解除订阅流程，直接用的`NSHashTable`来弱引用订阅者，这样可以避免当订阅者释放时还要手动解除订阅的麻烦。当添加订阅时会给订阅对象自动关联一个`block`属性，用以收到消息时的回调处理。

> 这里使用`NSHashTable`另一个原因是当从里面查找要移除的对象时速度要比`NSArray`要快，详情参考这里: [NSHash​Table & NSMap​Table](https://nshipster.cn/nshashtable-and-nsmaptable/);
> 
> 当然你要认为`NSHashTable`性能不好可以使用链表处理；这里，笔者觉得没必要，一是因为这个方法调用不会太频繁，二是笔者觉得`NSHashTable`的性能还可以😁;

#### 使用方式：

```objectivec
// 订阅事件
[ZDEventBus subscribeEvent:@"EventName" subscriber:self next:^(NSString *name, NSInteger age){
    NSLog(@"%@ + %ld", name, age);
}];

// 接收事件
[ZDEventBus dispatchEvent:@"EventName" values:^(ZDSubscribeNext deliverValuesBlock) {
    deliverValuesBlock(@"zero.d.saber", 100); // 可变参数
}];
```

