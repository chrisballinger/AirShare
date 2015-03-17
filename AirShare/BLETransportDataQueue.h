//
//  BLETransportDataQueue.h
//  Pods
//
//  Created by Christopher Ballinger on 3/4/15.
//
//

#import <Foundation/Foundation.h>

@interface BLETransportDataQueue : NSObject

/** Queues outgoing data for identifier */
- (void) queueData:(NSData*)data
     forIdentifier:(NSString*)identifier
               mtu:(NSUInteger)mtu;

/** Return item at top of queue */
- (NSData*) peekDataForIdentifier:(NSString*)identifier;
/** Return and remove item at top of queue */
- (NSData*) popDataForIdentifier:(NSString*)identifier;

@end
