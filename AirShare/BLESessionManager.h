//
//  BLESessionManager.h
//  Pods
//
//  Created by Christopher Ballinger on 2/20/15.
//
//

#import <Foundation/Foundation.h>
#import "BLEPeer.h"
#import "BLESession.h"
#import "BLETransport.h"

@class BLESessionManager;

typedef NS_ENUM(NSInteger, BLEPeerStatus) {
    BLEPeerStatusDisconnected,
    BLEPeerStatusConnecting,
    BLEPeerStatusConnected
};

@protocol BLESessionManagerDelegate <NSObject>
- (void) sessionManager:(BLESessionManager*)sessionManager
errorEstablishingSession:(NSError*)error;

- (void) sessionManager:(BLESessionManager*)sessionManager
     sessionEstablished:(BLESession*)session;

- (void) sessionManager:(BLESessionManager *)sessionManager
                   peer:(BLEPeer *)peer
          statusUpdated:(BLEPeerStatus)status;

@end

@interface BLESessionManager : NSObject <BLETransportDelegate>

@property (nonatomic, strong, readonly) BLEPeer *localPeer;
@property (nonatomic, weak) id<BLESessionManagerDelegate> delegate;
@property (nonatomic, strong) dispatch_queue_t delegateQueue;

- (instancetype) initWithLocalPeer:(BLEPeer*)localPeer delegate:(id<BLESessionManagerDelegate>)delegate;

- (void) advertiseLocalPeer;

- (void) scanForPeers;

/** Start synchronous session with peer, default 10s timeout */
- (void) startSessionWithPeer:(BLEPeer*)peer;

/** Start synchronous session with remote peer */
- (void) startSessionWithPeer:(BLEPeer*)peer
                      timeout:(NSTimeInterval)timeout;

@end
