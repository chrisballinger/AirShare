//
//  BLEPeer.h
//  Pods
//
//  Created by Christopher Ballinger on 2/19/15.
//
//

@interface BLEPeer : NSObject

/** Serves as unique identifier */
@property (nonatomic, strong, readonly) NSData *publicKey;

@property (nonatomic, strong) NSString *alias;

/** May be nil if transport doesn't support signal strength */
@property (nonatomic, strong) NSNumber *RSSI;

/** Last time peer has been seen */
@property (nonatomic, strong) NSDate *lastSeenDate;

- (instancetype) initWithPublicKey:(NSData*)publicKey;

@end
