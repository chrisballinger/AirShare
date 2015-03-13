//
//  BLEPeer.m
//  Pods
//
//  Created by Christopher Ballinger on 2/19/15.
//
//

#import "BLEPeer.h"

@implementation BLEPeer

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _publicKey = [aDecoder decodeObjectOfClass:[NSData class] forKey:NSStringFromSelector(@selector(publicKey))];
        _alias = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(alias))];
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.publicKey forKey:NSStringFromSelector(@selector(publicKey))];
    [aCoder encodeObject:self.alias forKey:NSStringFromSelector(@selector(alias))];
}

+ (BOOL) supportsSecureCoding {
    return YES;
}

- (instancetype) initWithPublicKey:(NSData*)publicKey {
    if (self = [super init]) {
        _identifiers = [NSMutableSet set];
        _publicKey = publicKey;
    }
    return self;
}



@end
