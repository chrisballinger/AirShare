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
#import "BLESessionMessageReceiver.h"
#import "BLEIdentityMessage.h"
#import "BLECrypto.h"

@interface AirShareTests : XCTestCase <BLESessionMessageReceiverDelegate>
@property (nonatomic, strong) BLESessionMessageReceiver *receiver;
@property (nonatomic, strong) XCTestExpectation *expectation;
@property (nonatomic, strong) BLEDataMessage *outgoingDataMessage;
@property (nonatomic, strong) BLEIdentityMessage *outgoingIdentityMessage;
@end

@implementation AirShareTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.receiver = [[BLESessionMessageReceiver alloc] initWithDelegate:self];
    self.receiver.callbackQueue = dispatch_queue_create("callback queue", 0);
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    self.receiver = nil;
    self.expectation = nil;
}

- (void)testIdentityMessage {
    self.expectation = [self expectationWithDescription:@"Identity Expectation"];
    BLEKeyPair *keyPair = [BLEKeyPair keyPairWithType:BLEKeyTypeEd25519];
    BLEPeer *peer = [[BLEPeer alloc] initWithPublicKey:keyPair.publicKey];
    self.outgoingIdentityMessage = [[BLEIdentityMessage alloc] initWithPeer:peer];
    [self sendDataAsChunks:self.outgoingIdentityMessage.serializedData chunkSize:20 toReceiver:self.receiver];
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
        }
    }];
}

- (void) sendDataAsChunks:(NSData*)data chunkSize:(NSUInteger)chunkSize toReceiver:(BLESessionMessageReceiver*)receiver {
    NSUInteger length = [data length];
    NSUInteger offset = 0;
    do {
        NSUInteger thisChunkSize = length - offset > chunkSize ? chunkSize : length - offset;
        NSData* chunk = [NSData dataWithBytesNoCopy:(char *)[data bytes] + offset
                                             length:thisChunkSize
                                       freeWhenDone:NO];
        offset += thisChunkSize;
        [receiver receiveData:chunk];
    } while (offset < length);
}

- (void)testDataMessage {
    self.expectation = [self expectationWithDescription:@"Serialization Expectation"];
    NSMutableData *testData = [NSMutableData data];
    for (uint32_t i = 0; i < 4096; i++) {
        [testData appendBytes:&i length:sizeof(uint32_t)];
    }
    BLEDataMessage *dataMessage = [[BLEDataMessage alloc] initWithData:testData];
    self.outgoingDataMessage = dataMessage;
    [self sendDataAsChunks:self.outgoingDataMessage.serializedData chunkSize:155 toReceiver:self.receiver];
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
        }
    }];
}

#pragma mark BLEMessageSerializationDelegate

- (void) receiver:(BLESessionMessageReceiver*)receiver
   headerComplete:(BLESessionMessage*)message {
    NSLog(@"headers complete: %@", message.headers);
    if ([message isKindOfClass:[BLEDataMessage class]]) {
        BLEDataMessage *dataMessage = (BLEDataMessage*)message;
        BOOL equal = [[dataMessage headers] isEqualToDictionary:[self.outgoingDataMessage headers]];
        XCTAssertTrue(equal, @"headers are different");
    } else if ([message isKindOfClass:[BLEIdentityMessage class]]) {
        BLEIdentityMessage *identityMessage = (BLEIdentityMessage*)message;
        BOOL equal = [[identityMessage headers] isEqualToDictionary:[self.outgoingIdentityMessage headers]];
        XCTAssertTrue(equal, @"headers are different");
    } else {
        XCTFail(@"Wrong class");
    }
}

- (void) receiver:(BLESessionMessageReceiver*)receiver
          message:(BLESessionMessage*)message
     incomingData:(NSData*)incomingData
         progress:(float)progress {
    NSLog(@"progress: %f", progress);
}

- (void) receiver:(BLESessionMessageReceiver*)receiver
 transferComplete:(BLESessionMessage*)message {
    NSLog(@"complete");
    if ([message isKindOfClass:[BLEDataMessage class]]) {
        BLEDataMessage *dataMessage = (BLEDataMessage*)message;
        BLEDataMessage *outgoingDataMessage = (BLEDataMessage*)self.outgoingDataMessage;
        NSData *incomingData = dataMessage.data;
        NSData *outgoingData = outgoingDataMessage.data;
        BOOL equal = [incomingData isEqualToData:outgoingData];
        XCTAssertTrue(equal, @"data is different");
        if (equal) {
            [self.expectation fulfill];
        }
    }
    if ([message isKindOfClass:[BLEIdentityMessage class]]) {
        BLEIdentityMessage *identityMessage = (BLEIdentityMessage*)message;
        NSData *incomingPubKey = identityMessage.publicKey;
        NSData *outgoingPubKey = self.outgoingIdentityMessage.publicKey;
        BOOL equal = [incomingPubKey isEqualToData:outgoingPubKey];
        XCTAssertTrue(equal, @"identity is different");
        if (equal) {
            [self.expectation fulfill];
        }
    }
}

@end
