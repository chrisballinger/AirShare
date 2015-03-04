//
//  IOCipherTests.m
//  IOCipher
//
//  Created by Christopher Ballinger on 1/20/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "BLEDataMessage.h"
#import "BLEMessageSerialization.h"

@interface AirShareTests : XCTestCase <BLEMessageSerializationDelegate>
@property (nonatomic, strong) BLEMessageSerialization *serialization;
@property (nonatomic, strong) XCTestExpectation *expectation;
@property (nonatomic, strong) BLESessionMessage *outgoingSessionMessage;
@end

@implementation AirShareTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.serialization = [[BLEMessageSerialization alloc] initWithDelegate:self];
    self.serialization.callbackQueue = dispatch_queue_create("callback queue", 0);
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    self.serialization = nil;
}

- (void)testDataMessage {
    self.expectation = [self expectationWithDescription:@"Serialization Expectation"];
    NSMutableData *testData = [NSMutableData data];
    for (uint32_t i = 0; i < 4096; i++) {
        [testData appendBytes:&i length:sizeof(uint32_t)];
    }
    BLEDataMessage *dataMessage = [[BLEDataMessage alloc] initWithData:testData];
    self.outgoingSessionMessage = dataMessage;
    NSData *messageData = [dataMessage serialize];
    NSUInteger length = [messageData length];
    NSUInteger chunkSize = 155;
    NSUInteger offset = 0;
    do {
        NSUInteger thisChunkSize = length - offset > chunkSize ? chunkSize : length - offset;
        NSData* chunk = [NSData dataWithBytesNoCopy:(char *)[messageData bytes] + offset
                                             length:thisChunkSize
                                       freeWhenDone:NO];
        offset += thisChunkSize;
        [self.serialization receiveData:chunk];
    } while (offset < length);
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
        }
    }];
}

#pragma mark BLEMessageSerializationDelegate

- (void) serialization:(BLEMessageSerialization*)serialization
        headerComplete:(BLESessionMessage*)message {
    NSLog(@"headers complete: %@", message.headers);
    if ([message isKindOfClass:[self.outgoingSessionMessage class]]) {
        if ([message isKindOfClass:[BLEDataMessage class]]) {
            BLEDataMessage *dataMessage = (BLEDataMessage*)message;
            BOOL equal = [[dataMessage headers] isEqualToDictionary:[self.outgoingSessionMessage headers]];
            XCTAssertTrue(equal, @"headers are different");
            
        }
    } else {
        XCTFail(@"Wrong class");
    }
}

- (void) serialization:(BLEMessageSerialization*)serialization
               message:(BLESessionMessage*)message
          incomingData:(NSData*)incomingData
              progress:(float)progress {
    NSLog(@"progress: %f", progress);
}

- (void) serialization:(BLEMessageSerialization*)serialization
      transferComplete:(BLESessionMessage*)message {
    NSLog(@"complete");
    if ([message isKindOfClass:[BLEDataMessage class]]) {
        BLEDataMessage *dataMessage = (BLEDataMessage*)message;
        BLEDataMessage *outgoingDataMessage = (BLEDataMessage*)self.outgoingSessionMessage;
        NSData *incomingData = dataMessage.data;
        NSData *outgoingData = outgoingDataMessage.data;
        BOOL equal = [incomingData isEqualToData:outgoingData];
        XCTAssertTrue(equal, @"data is different");
        if (equal) {
            [self.expectation fulfill];
        }
    }
}

@end
