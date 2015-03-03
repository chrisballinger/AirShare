//
//  BLELocalPeer.h
//  Pods
//
//  Created by Christopher Ballinger on 3/2/15.
//
//

#import "BLEPeer.h"

@interface BLELocalPeer : BLEPeer

@property (nonatomic, strong, readonly) NSData *privateKey;

@end
