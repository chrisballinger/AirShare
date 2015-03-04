//
//  BLEIdentityMessage.h
//  Pods
//
//  Created by Christopher Ballinger on 3/3/15.
//
//

#import "BLESessionMessage.h"
#import "BLEPeer.h"

@interface BLEIdentityMessage : BLESessionMessage

@property (nonatomic, strong) NSData *publicKey;
@property (nonatomic, strong) NSString *alias;

- (instancetype) initWithPeer:(BLEPeer*)peer;

@end

extern NSString * const kBLEIdentityMessageHeaderPublicKey;
extern NSString * const kBLEIdentityMessageHeaderAliasKey;
