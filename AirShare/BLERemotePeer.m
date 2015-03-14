//
//  BLERemotePeer.m
//  Pods
//
//  Created by Christopher Ballinger on 3/14/15.
//
//

#import "BLERemotePeer.h"

@implementation BLERemotePeer

- (instancetype) initWithPublicKey:(NSData *)publicKey {
    if (self = [super initWithPublicKey:publicKey]) {
        _identifiers = [NSMutableSet set];
    }
    return self;
}

+ (BOOL) supportsSecureCoding {
    return YES;
}

@end
