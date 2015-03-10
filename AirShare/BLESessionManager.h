//
//  BLESessionManager.h
//  Pods
//
//  Created by Christopher Ballinger on 2/20/15.
//
//

#import <Foundation/Foundation.h>
#import "BLELocalPeer.h"
#import "BLESession.h"
#import "BLETransport.h"
#import "BLESessionMessage.h"

@class BLESessionManager;

@protocol BLESessionManagerDelegate <NSObject>
- (void) sessionManager:(BLESessionManager*)sessionManager
errorEstablishingSession:(NSError*)error;

- (void) sessionManager:(BLESessionManager*)sessionManager
     sessionEstablished:(BLESession*)session;

- (void) sessionManager:(BLESessionManager *)sessionManager
                   peer:(BLEPeer *)peer
          statusUpdated:(BLEConnectionStatus)status;

@end

@interface BLESessionManager : NSObject <BLETransportDelegate>

@property (nonatomic, strong, readonly) BLELocalPeer *localPeer;
@property (nonatomic, weak) id<BLESessionManagerDelegate> delegate;
@property (nonatomic, strong) dispatch_queue_t delegateQueue;

- (instancetype) initWithLocalPeer:(BLELocalPeer*)localPeer delegate:(id<BLESessionManagerDelegate>)delegate;

- (void) advertiseLocalPeer;

- (void) scanForPeers;

- (NSArray*) discoveredPeers;

- (void) sendSessionMessage:(BLESessionMessage*)sessionMessage
                     toPeer:(BLEPeer*)peer;

@end
