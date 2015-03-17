//
//  BLETransportDataQueue.m
//  Pods
//
//  Created by Christopher Ballinger on 3/4/15.
//
//

#import "BLETransportDataQueue.h"

@interface BLETransportDataQueue ()
@property (nonatomic, strong) NSMutableDictionary *queues;
@end

@implementation BLETransportDataQueue

- (instancetype) init {
    if (self = [super init]) {
        _queues = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSMutableArray*) queueForIdentifier:(NSString*)identifier {
    NSMutableArray *queue = [self.queues objectForKey:identifier];
    if (!queue) {
        queue = [NSMutableArray array];
        [self.queues setObject:queue forKey:identifier];
    }
    return queue;
}

/** Queues outgoing data for identifier */
- (void) queueData:(NSData*)data
     forIdentifier:(NSString*)identifier
               mtu:(NSUInteger)mtu {
    NSMutableArray *queue = [self queueForIdentifier:identifier];
    if (data.length <= mtu) {
        [queue insertObject:data atIndex:0];
    } else {
        // packetize data to MTU
        NSUInteger length = [data length];
        NSUInteger offset = 0;
        do {
            NSUInteger thisChunkSize = length - offset > mtu ? mtu : length - offset;
            NSData* chunk = [NSData dataWithBytes:(char *)[data bytes] + offset
                                                 length:thisChunkSize];
            offset += thisChunkSize;
            [queue insertObject:chunk atIndex:0];
        } while (offset < length);
    }
}

/** Return item at top of queue */
- (NSData*) peekDataForIdentifier:(NSString*)identifier {
    NSMutableArray *queue = [self queueForIdentifier:identifier];
    if (queue.count == 0) {
        return nil;
    }
    NSData *data = [queue lastObject];
    return data;
}

/** Return and remove item at top of queue */
- (NSData*) popDataForIdentifier:(NSString*)identifier {
    NSData *data = [self peekDataForIdentifier:identifier];
    if (!data) {
        return nil;
    }
    NSMutableArray *queue = [self queueForIdentifier:identifier];
    [queue removeLastObject];
    return data;
}

@end
