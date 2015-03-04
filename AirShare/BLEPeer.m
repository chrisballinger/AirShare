//
//  BLEPeer.m
//  Pods
//
//  Created by Christopher Ballinger on 2/19/15.
//
//

#import "BLEPeer.h"

@implementation BLEPeer

- (instancetype) initWithPublicKey:(NSData*)publicKey {
    if (self = [super init]) {
        _publicKey = publicKey;
    }
    return self;
}

@end
