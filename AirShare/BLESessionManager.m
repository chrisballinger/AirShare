//
//  BLESessionManager.m
//  Pods
//
//  Created by Christopher Ballinger on 2/20/15.
//
//

#import "BLESessionManager.h"

@interface BLESessionManager()
@property (nonatomic, strong, readonly) NSMutableSet *transports;
@end

@implementation BLESessionManager

- (instancetype) initWithLocalPeer:(BLEPeer*)localPeer delegate:(id<BLESessionManagerDelegate>)delegate {
    if (self = [super init]) {
        _localPeer = localPeer;
        _transports = [NSMutableSet set];
        _delegateQueue = dispatch_queue_create("BLESessionManagerDelegate Queue", 0);
        [self registerTransports];
    }
    return self;
}

- (void) registerTransports {
    BLETransport *transport = [[BLETransport alloc] initWithLocalPeer:self.localPeer delegate:self];
    [self.transports addObject:transport];
}

- (BLETransport*) preferredTransport {
    return [self.transports anyObject];
}

- (void) advertiseLocalPeer {
    BLETransport *transport = [self preferredTransport];
    [transport advertiseLocalPeer];
}

- (void) scanForPeers {
    BLETransport *transport = [self preferredTransport];
    [transport scanForPeers];
}

/** Start synchronous session with peer, default 10s timeout */
- (void) startSessionWithPeer:(BLEPeer*)peer {
    
}

/** Start synchronous session with remote peer */
- (void) startSessionWithPeer:(BLEPeer*)peer
                      timeout:(NSTimeInterval)timeout {
    
}

#pragma mark BLETransportDelegate

- (void) transport:(BLETransport*)transport
      dataReceived:(NSData*)data
          fromPeer:(BLEPeer*)peer {
    
}

- (void) transport:(BLETransport*)transport
       peerUpdated:(BLEPeer*)peer
              RSSI:(NSNumber*)RSSI {
    
}

@end
