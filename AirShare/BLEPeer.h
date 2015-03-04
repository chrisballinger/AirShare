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

/** May be nil if transport doesn't support signal strength */
@property (nonatomic, strong, readonly) NSNumber *RSSI;

/** Last time peer has been seen */
@property (nonatomic, strong, readonly) NSDate *lastSeenDate;

@end
