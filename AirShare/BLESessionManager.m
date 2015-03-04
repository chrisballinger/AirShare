//
//  BLESessionManager.m
//  Pods
//
//  Created by Christopher Ballinger on 2/20/15.
//
//

#import "BLESessionManager.h"
#import "BLESessionMessageReceiver.h"
#import "BLEIdentityMessage.h"
#import "BLEDataMessage.h"

@interface BLESessionManager() <BLESessionMessageReceiverDelegate>
@property (nonatomic, strong, readonly) NSMutableSet *transports;
/** identifier -> peer */
@property (nonatomic, strong, readonly) NSMutableDictionary *identifiersToPeers;

@property (nonatomic, strong, readonly) NSMutableSet *identifiersUndergoingPeerDiscovery;

@property (nonatomic, strong, readonly) NSMutableDictionary *receiverForIdentifier;
@end

@implementation BLESessionManager

- (instancetype) initWithLocalPeer:(BLELocalPeer*)localPeer delegate:(id<BLESessionManagerDelegate>)delegate {
    if (self = [super init]) {
        _localPeer = localPeer;
        _transports = [NSMutableSet set];
        _delegateQueue = dispatch_queue_create("BLESessionManagerDelegate Queue", 0);
        _identifiersToPeers = [NSMutableDictionary dictionary];
        _identifiersUndergoingPeerDiscovery = [NSMutableSet set];
        _receiverForIdentifier = [NSMutableDictionary dictionary];
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
    BLESessionMessageReceiver *receiver = [self.receiverForIdentifier objectForKey:identifier];
    if (!receiver) {
        receiver = [[BLESessionMessageReceiver alloc] initWithDelegate:self];
        receiver.context = identifier;
        [self.receiverForIdentifier setObject:receiver forKey:identifier];
    }
    [receiver receiveData:data];
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
                BLEIdentityMessage *identityMessage = [[BLEIdentityMessage alloc] initWithPeer:self.localPeer];
                BOOL success = [transport sendData:identityMessage.serializedData toIdentifiers:@[identifier] withMode:BLETransportSendDataReliable error:&error];
            }
        }
    }
}

#pragma mark BLESessionMessageReceiverDelegate

- (void) receiver:(BLESessionMessageReceiver*)receiver
   headerComplete:(BLESessionMessage*)message {
    NSLog(@"headers complete: %@", message.headers);
    if ([message isKindOfClass:[BLEDataMessage class]]) {
    } else if ([message isKindOfClass:[BLEIdentityMessage class]]) {
    
    }
}

- (void) receiver:(BLESessionMessageReceiver*)receiver
          message:(BLESessionMessage*)message
     incomingData:(NSData*)incomingData
         progress:(float)progress {
    NSLog(@"progress: %f", progress);
    if ([message isKindOfClass:[BLEDataMessage class]]) {
    } else if ([message isKindOfClass:[BLEIdentityMessage class]]) {
    }
}

- (void) receiver:(BLESessionMessageReceiver*)receiver
 transferComplete:(BLESessionMessage*)message {
    NSLog(@"transferComplete");
    if ([message isKindOfClass:[BLEDataMessage class]]) {
    } else if ([message isKindOfClass:[BLEIdentityMessage class]]) {
        BLEIdentityMessage *identityMessage = (BLEIdentityMessage*)message;
        NSString *identifier = receiver.context;
        BLEPeer *peer = [[BLEPeer alloc] initWithPublicKey:identityMessage.publicKey];
        NSLog(@"peer discovered for identifier: %@ %@", peer, identifier);
    }
}

@end
