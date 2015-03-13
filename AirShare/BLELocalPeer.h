//
//  BLELocalPeer.h
//  Pods
//
//  Created by Christopher Ballinger on 3/2/15.
//
//

#import "BLEPeer.h"

@interface BLELocalPeer : BLEPeer <NSSecureCoding>

@property (nonatomic, strong, readonly) NSData *privateKey;

- (instancetype) initWithPublicKey:(NSData *)publicKey privateKey:(NSData*)privateKey;

@end
