//
//  BLECryptoTests.m
//  AirShare
//
//  Created by Christopher Ballinger on 4/16/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "BLECrypto.h"

@interface BLECryptoTests : XCTestCase

@end

@implementation BLECryptoTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testEd25519Signatures {
    BLEKeyPair *keyPair = [BLEKeyPair keyPairWithType:BLEKeyTypeEd25519];
    NSData *data = [NSMutableData dataWithLength:500];
    NSData *sig = [BLECrypto signatureForData:data privateKey:keyPair.privateKey];
    BOOL success = [BLECrypto verifyData:data signature:sig publicKey:keyPair.publicKey];
    XCTAssert(success == YES, @"Ed25519 signature test failed!");
}


@end
