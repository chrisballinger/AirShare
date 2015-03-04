//
//  BLELocalPeer.m
//  Pods
//
//  Created by Christopher Ballinger on 3/2/15.
//
//

#import "BLELocalPeer.h"

@implementation BLELocalPeer

- (instancetype) initWithPublicKey:(NSData *)publicKey privateKey:(NSData*)privateKey {
    if (self = [super initWithPublicKey:publicKey]) {
        _privateKey = privateKey;
    }
    return self;
}

@end
