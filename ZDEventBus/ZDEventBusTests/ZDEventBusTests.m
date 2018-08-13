//
//  ZDEventBusTests.m
//  ZDEventBusTests
//
//  Created by Zero.D.Saber on 2018/8/13.
//  Copyright © 2018年 Zero.D.Saber. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZDEventBus.h"

@interface ZDEventBusTests : XCTestCase

@end

@implementation ZDEventBusTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    [self subscribeEvent:@"" next:^(id value1, NSInteger value2, id value3){
        NSLog(@"***** %@ - %ld - %@", value1, value2, value3);
        XCTAssertEqualObjects(value1, @"xxxx");
        XCTAssert(value2 == 12345678);
        XCTAssertNotNil(value3);
    }];
    
    [self dispatchEvent:@"" values:^(ZDSubscribeNext deliverValuesBlock) {
        deliverValuesBlock(@"xxxx", 12345678, [NSObject new]);
    }];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
