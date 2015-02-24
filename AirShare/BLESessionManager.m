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
/** identifier -> peer */
@property (nonatomic, strong, readonly) NSMutableDictionary *identifiersToPeers;

@property (nonatomic, strong, readonly) NSMutableSet *identifiersUndergoingPeerDiscovery;
@end

@implementation BLESessionManager

- (instancetype) initWithLocalPeer:(BLEPeer*)localPeer delegate:(id<BLESessionManagerDelegate>)delegate {
    if (self = [super init]) {
        _localPeer = localPeer;
        _transports = [NSMutableSet set];
        _delegateQueue = dispatch_queue_create("BLESessionManagerDelegate Queue", 0);
        _identifiersToPeers = [NSMutableDictionary dictionary];
        _identifiersUndergoingPeerDiscovery = [NSMutableSet set];
        [self registerTransports];
    }
    return self;
}

- (void) registerTransports {
    BLETransport *transport = [[BLETransport alloc] initWithDelegate:self];
    [self.transports addObject:transport];
}

- (BLETransport*) preferredTransportForPeer:(BLEPeer*)peer {
    return [self.transports anyObject];
}

- (void) advertiseLocalPeer {
    [self.transports enumerateObjectsUsingBlock:^(BLETransport *transport, BOOL *stop) {
        [transport advertise];
    }];
}

- (void) scanForPeers {
    [self.transports enumerateObjectsUsingBlock:^(BLETransport *transport, BOOL *stop) {
        [transport scan];
    }];
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
    fromIdentifier:(NSString*)identifier {
    NSLog(@"dataReceived:fromIdentifier %@: %@", identifier, data);

}

- (void) transport:(BLETransport*)transport
          dataSent:(NSData*)data
      toIdentifier:(NSString*)identifier
             error:(NSError*)error {
    NSLog(@"dataSent:toIdentifier %@: %@", identifier, data);
}

- (void) transport:(BLETransport*)transport
 identifierUpdated:(NSString*)identifier
  connectionStatus:(BLEConnectionStatus)connectionStatus
         extraInfo:(NSDictionary*)extraInfo {
    NSLog(@"identifier: %@ %d %@", identifier, (int)connectionStatus, extraInfo);
    BLEPeer *peer = [self.identifiersToPeers objectForKey:identifier];
    if (!peer) {
        BOOL identifierUndergoingPeerDiscovery = [self.identifiersUndergoingPeerDiscovery containsObject:identifier];
        if (!identifierUndergoingPeerDiscovery) {
            if (connectionStatus == BLEConnectionStatusConnected) {
                [self.identifiersUndergoingPeerDiscovery addObject:identifier];
                NSError *error = nil;
                BOOL success = [transport sendData:[@"test" dataUsingEncoding:NSUTF8StringEncoding] toIdentifiers:@[identifier] withMode:BLETransportSendDataReliable error:&error];
            }
        }
    }
}

@end
