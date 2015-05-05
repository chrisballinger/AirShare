//
//  BLEMultipeerTransport.m
//  Pods
//
//  Created by David Brodsky on 5/5/15.
//
//

#import "BLEMultipeerTransport.h"
#import "NSData+AirShare.h"
@import MultipeerConnectivity;

@interface BLEMultipeerTransport () <MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate, MCSessionDelegate>

@property (nonatomic, strong) MCPeerID *localPeerID;

@property (nonatomic, strong) NSString *serviceType;

@property (nonatomic, strong) MCSession *currentSession;

@property (nonatomic, strong) MCNearbyServiceAdvertiser *advertiser;

@property (nonatomic, strong) MCNearbyServiceBrowser *browser;

@end

@implementation BLEMultipeerTransport

- (instancetype) initWithServiceName:(NSString *)serviceName delegate:(id<BLETransportDelegate>)delegate supportsBackground:(BOOL)supportsBackground {
    if (self = [super initWithServiceName:serviceName delegate:delegate]) {
        _supportsBackground = supportsBackground;
        _localPeerID = [BLEMultipeerTransport randomMCPeerID];
        _serviceType = [BLEMultipeerTransport multipeerServiceTypeFromServiceName:serviceName];
        
        _advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:_localPeerID discoveryInfo:nil serviceType:_serviceType];
        _advertiser.delegate = self;
        
        _browser = [[MCNearbyServiceBrowser alloc] initWithPeer:_localPeerID serviceType:_serviceType];
        _browser.delegate = self;
    }
    return self;
}


- (void) advertise {
    [_advertiser startAdvertisingPeer];
}

- (void) scan {
    [_browser startBrowsingForPeers];
}

- (void) stop {
    [_advertiser stopAdvertisingPeer];
    [_browser stopBrowsingForPeers];
    
    if (_currentSession) {
        [_currentSession disconnect];
        _currentSession = nil;
    }
}

- (BOOL) sendData:(NSData*)data
    toIdentifiers:(NSArray*)identifiers
         withMode:(BLETransportSendDataMode)mode
            error:(NSError**)error {
    
    if(_currentSession) {
        // TODO : Respond to errors
        [_currentSession sendData:data toPeers:identifiers withMode:MCSessionSendDataReliable error:nil];
        return YES;
        
    } else {
        NSLog(@"No Session established to send data!");
        return NO;
    }
}

#pragma mark MCNearbyServiceAdvertiserDelegate

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser
didReceiveInvitationFromPeer:(MCPeerID *)peerID
       withContext:(NSData *)context
 invitationHandler:(void (^)(BOOL accept,
                             MCSession *session))invitationHandler {
    
    // TODO : We should probably bundle some context data such as the public key negotiated
    // over the base transport
    
    if (!_currentSession) {
        NSLog(@"Accepting invitation from %@", peerID.displayName);

        _currentSession = [[MCSession alloc] initWithPeer:_localPeerID];
        _currentSession.delegate = self;
        
        invitationHandler(YES, _currentSession);
        
    } else {
        NSLog(@"Received invitation from %@ but we're already involved in a session", peerID.displayName);
    }
}

#pragma mark MCNearbyServiceBrowserDelegate

- (void)browser:(MCNearbyServiceBrowser *)browser
      foundPeer:(MCPeerID *)peerID
withDiscoveryInfo:(NSDictionary *)info {
    
    [self.delegate transport:self identifierUpdated:peerID.displayName connectionStatus:BLEConnectionStatusConnected isIdentifierHost:YES extraInfo:nil];
}

- (void)browser:(MCNearbyServiceBrowser *)browser
       lostPeer:(MCPeerID *)peerID {

    [self.delegate transport:self identifierUpdated:peerID.displayName connectionStatus:BLEConnectionStatusDisconnected isIdentifierHost:YES extraInfo:nil];
}

#pragma mark MCSessionDelegate

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    NSLog(@"Session peer %@ changed state to %ld", peerID.displayName, (long)state);
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    
    dispatch_async(self.delegateQueue, ^{
        [self.delegate transport:self dataReceived:data fromIdentifier:peerID.displayName];
    });
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {
    // unused
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {
    // unused
}

// Finished receiving a resource from remote peer and saved the content in a temporary location - the app is responsible for moving the file to a permanent location within its sandbox
- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {
    // unused
}

#pragma mark Helpers

+ (MCPeerID*) randomMCPeerID {
    // MCPeerID myDisplayName must be unique to each instance of this class and be no more than 63 UTF-8 bytes
    NSString *randomString = [[NSUUID UUID] UUIDString];
    return [[MCPeerID alloc] initWithDisplayName:[randomString substringToIndex:63]];
}
                       
+ (NSString*) multipeerServiceTypeFromServiceName:(NSString*)serviceName {
   // MCNearbyServiceAdvertiser serviceType must be unique to serviceName and be no more than 15 ASCII bytes
   NSData *sha256 = [[serviceName dataUsingEncoding:NSASCIIStringEncoding] ble_sha256];
   NSString *hexString = [sha256 ble_hexString];
   NSMutableString *serviceTypeString = [[NSMutableString alloc] init];
   [serviceTypeString appendString:[hexString substringToIndex:15]];
   return serviceTypeString;
}


@end
