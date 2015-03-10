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
#import "BLEFileTransferMessage.h"
#import "BLECrypto.h"

@interface AirShareTests : XCTestCase <BLESessionMessageReceiverDelegate>
@property (nonatomic, strong) BLESessionMessageReceiver *receiver;
@property (nonatomic, strong) XCTestExpectation *expectation;
@property (nonatomic, strong) BLEDataMessage *outgoingDataMessage;
@property (nonatomic, strong) BLEIdentityMessage *outgoingIdentityMessage;
@property (nonatomic, strong) BLEFileTransferMessage *fileTransferMessage;
@end

@implementation AirShareTests

- (void) setupReceiver {
    self.receiver = [[BLESessionMessageReceiver alloc] initWithDelegate:self];
    self.receiver.callbackQueue = dispatch_queue_create("callback queue", 0);
}

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [self setupReceiver];
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

- (void)testDataMessage {
    self.expectation = [self expectationWithDescription:@"Serialization Expectation"];
    NSData *testData = [self generateTestDataOfLength:16000];
    BLEDataMessage *dataMessage = [[BLEDataMessage alloc] initWithData:testData];
    self.outgoingDataMessage = dataMessage;
    [self sendDataAsChunks:self.outgoingDataMessage.serializedData chunkSize:155 toReceiver:self.receiver];
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
        }
    }];
}

- (void) testFileTransferMessage {
    self.expectation = [self expectationWithDescription:@"File Expectation"];
    NSData *testData = [self generateTestDataOfLength:16000];
    NSString *tempDirectory = NSTemporaryDirectory();
    XCTAssertNotNil(tempDirectory);
    XCTAssertTrue([[NSFileManager defaultManager] isWritableFileAtPath:tempDirectory]);
    NSString *path = [tempDirectory stringByAppendingPathComponent:@"test.file"];
    BOOL success = [testData writeToFile:path atomically:YES];
    XCTAssert(success, @"Error writing test data");
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    self.fileTransferMessage = [[BLEFileTransferMessage alloc] initWithFileURL:fileURL transferType:BLEFileTransferMessageTypeOffer];
    XCTAssert(self.fileTransferMessage.transferType == BLEFileTransferMessageTypeOffer);
    NSDictionary *headers = self.fileTransferMessage.headers;
    NSString *type = [headers objectForKey:kBLESessionMessageHeaderTypeKey];
    XCTAssertEqualObjects(type, kBLEFileTransferMessageHeaderTypeOffer);
    NSData *serializedOffer = self.fileTransferMessage.serializedData;
    [self.receiver receiveData:serializedOffer];
    [self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
        }
    }];
}

- (NSData*) generateTestDataOfLength:(NSUInteger)length {
    NSMutableData *data = [NSMutableData dataWithCapacity:length];
    uint8_t x = 0;
    for (NSUInteger i = 0; i < length; i++) {
        x++;
        [data appendBytes:&x length:1];
    }
    return data;
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

- (void) sendSessionMessagePayload:(BLESessionMessage*)sessionMessage
                         chunkSize:(NSUInteger)chunkSize
                        toReceiver:(BLESessionMessageReceiver*)receiver {
    NSUInteger length = [sessionMessage payloadLength];
    NSUInteger offset = 0;
    do {
        NSUInteger thisChunkSize = length - offset > chunkSize ? chunkSize : length - offset;
        NSData *chunk = [sessionMessage payloadDataAtOffset:offset length:thisChunkSize];
        offset += thisChunkSize;
        [receiver receiveData:chunk];
    } while (offset < length);
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
    } else if ([message isKindOfClass:[BLEFileTransferMessage class]]) {
        //BLEFileTransferMessage *transferMessage = (BLEFileTransferMessage*)message;
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
    } else if ([message isKindOfClass:[BLEIdentityMessage class]]) {
        BLEIdentityMessage *identityMessage = (BLEIdentityMessage*)message;
        NSData *incomingPubKey = identityMessage.publicKey;
        NSData *outgoingPubKey = self.outgoingIdentityMessage.publicKey;
        BOOL equal = [incomingPubKey isEqualToData:outgoingPubKey];
        XCTAssertTrue(equal, @"identity is different");
        if (equal) {
            [self.expectation fulfill];
        }
    } else if ([message isKindOfClass:[BLEFileTransferMessage class]]) {
        BLEFileTransferMessage *transferMessage = (BLEFileTransferMessage*)message;
        if (transferMessage.transferType == BLEFileTransferMessageTypeOffer) {
            [self setupReceiver];
            transferMessage.transferType = BLEFileTransferMessageTypeAccept;
            NSData *serializedData = transferMessage.serializedData;
            [self.receiver receiveData:serializedData];
        } else if (transferMessage.transferType == BLEFileTransferMessageTypeAccept) {
            [self setupReceiver];
            // send file
            self.fileTransferMessage.transferType = BLEFileTransferMessageTypeTransfer;
            NSData *header = [self.fileTransferMessage serializedPrefixAndHeaderData];
            [self.receiver receiveData:header];
            [self sendSessionMessagePayload:self.fileTransferMessage chunkSize:155 toReceiver:self.receiver];
        } else if (transferMessage.transferType == BLEFileTransferMessageTypeTransfer) {
            NSData *receivedData = [[NSData alloc] initWithContentsOfURL:transferMessage.fileURL];
            NSData *sentData = [[NSData alloc] initWithContentsOfURL:self.fileTransferMessage.fileURL];
            if ([receivedData isEqualToData:sentData]) {
                [self.expectation fulfill];
            } else {
                XCTFail(@"Data mismatch");
            }
        }
        NSLog(@"transfer message received");
        
    }
}

@end
