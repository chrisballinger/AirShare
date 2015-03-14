//
//  BLESessionManager.h
//  Pods
//
//  Created by Christopher Ballinger on 2/20/15.
//
//

#import <Foundation/Foundation.h>
#import "BLELocalPeer.h"
#import "BLERemotePeer.h"
#import "BLETransport.h"
#import "BLESessionMessage.h"

@class BLESessionManager;

@protocol BLESessionManagerDelegate <NSObject>

- (void) sessionManager:(BLESessionManager *)sessionManager
                   peer:(BLERemotePeer *)peer
          statusUpdated:(BLEConnectionStatus)status;

- (void) sessionManager:(BLESessionManager *)sessionManager
        receivedMessage:(BLESessionMessage*)message
               fromPeer:(BLERemotePeer*)peer;

@end

@interface BLESessionManager : NSObject <BLETransportDelegate>

@property (nonatomic, strong, readonly) BLELocalPeer *localPeer;
@property (nonatomic, weak) id<BLESessionManagerDelegate> delegate;
@property (nonatomic, strong) dispatch_queue_t delegateQueue;
@property (nonatomic) BOOL supportsBackground;

- (instancetype) initWithLocalPeer:(BLELocalPeer*)localPeer delegate:(id<BLESessionManagerDelegate>)delegate;

- (void) advertiseLocalPeer;

- (void) scanForPeers;

- (NSArray*) discoveredPeers;

- (void) sendSessionMessage:(BLESessionMessage*)sessionMessage
                     toPeer:(BLERemotePeer*)peer;

@end
