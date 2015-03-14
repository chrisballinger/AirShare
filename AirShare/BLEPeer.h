//
//  BLEPeer.h
//  Pods
//
//  Created by Christopher Ballinger on 2/19/15.
//
//

@interface BLEPeer : NSObject <NSSecureCoding>

/** Serves as unique identifier */
@property (nonatomic, strong, readonly) NSData *publicKey;

@property (nonatomic, strong) NSString *alias;

- (instancetype) initWithPublicKey:(NSData*)publicKey;

@end
