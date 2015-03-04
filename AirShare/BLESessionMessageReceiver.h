//
//  BLEMessageSerialization.h
//  Pods
//
//  Created by Christopher Ballinger on 3/2/15.
//
//

#import <Foundation/Foundation.h>
#import "BLESessionMessage.h"

@class BLESessionMessageReceiver;

@protocol BLESessionMessageReceiverDelegate <NSObject>

- (void) receiver:(BLESessionMessageReceiver*)receiver
   headerComplete:(BLESessionMessage*)message;

- (void) receiver:(BLESessionMessageReceiver*)receiver
          message:(BLESessionMessage*)message
     incomingData:(NSData*)incomingData
         progress:(float)progress;

- (void) receiver:(BLESessionMessageReceiver*)receiver
 transferComplete:(BLESessionMessage*)message;

@end

@interface BLESessionMessageReceiver : NSObject

@property (nonatomic, weak) id context;
@property (nonatomic, weak) id<BLESessionMessageReceiverDelegate> delegate;
@property (nonatomic) dispatch_queue_t callbackQueue;

- (instancetype) initWithDelegate:(id<BLESessionMessageReceiverDelegate>)delegate;

- (void) receiveData:(NSData*)data;

@end
