//
//  BLERemotePeer.h
//  Pods
//
//  Created by Christopher Ballinger on 3/14/15.
//
//

#import "BLEPeer.h"

@interface BLERemotePeer : BLEPeer <NSSecureCoding>

/** internal transport identifier */
@property (nonatomic, strong, readonly) NSMutableSet *identifiers;

/** May be nil if transport doesn't support signal strength */
@property (nonatomic, strong) NSNumber *RSSI;

/** Last time peer has been seen */
@property (nonatomic, strong) NSDate *lastSeenDate;

@end
