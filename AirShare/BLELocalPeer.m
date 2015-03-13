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

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _privateKey = [aDecoder decodeObjectOfClass:[NSData class] forKey:NSStringFromSelector(@selector(privateKey))];
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.privateKey forKey:NSStringFromSelector(@selector(privateKey))];
}

+ (BOOL) supportsSecureCoding {
    return YES;
}

@end
