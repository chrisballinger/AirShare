//
//  BLEMessageSerialization.h
//  Pods
//
//  Created by Christopher Ballinger on 3/2/15.
//
//

#import <Foundation/Foundation.h>
#import "BLESessionMessage.h"

@class BLEMessageSerialization;

@protocol BLEMessageSerializationDelegate <NSObject>

- (void) serialization:(BLEMessageSerialization*)serialization
        headerComplete:(BLESessionMessage*)message;

- (void) serialization:(BLEMessageSerialization*)serialization
               message:(BLESessionMessage*)message
          incomingData:(NSData*)incomingData
              progress:(float)progress;

- (void) serialization:(BLEMessageSerialization*)serialization
      transferComplete:(BLESessionMessage*)message;

@end

@interface BLEMessageSerialization : NSObject

@property (nonatomic, weak) id<BLEMessageSerializationDelegate> delegate;
@property (nonatomic) dispatch_queue_t callbackQueue;

- (instancetype) initWithDelegate:(id<BLEMessageSerializationDelegate>)delegate;

- (void) receiveData:(NSData*)data;

@end
