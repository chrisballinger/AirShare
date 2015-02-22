//
//  BLETransport.h
//  Pods
//
//  Created by Christopher Ballinger on 2/20/15.
//
//

#import <Foundation/Foundation.h>
#import "BLEPeer.h"



@class BLETransport;

@protocol BLETransportDelegate <NSObject>

- (void) transport:(BLETransport*)transport
      dataReceived:(NSData*)data
          fromPeer:(BLEPeer*)peer;

- (void) transport:(BLETransport*)transport
       peerUpdated:(BLEPeer*)peer
              RSSI:(NSNumber*)RSSI;

@end

@protocol BLETransport <NSObject>

- (void) sendData:(NSData*)data
          toPeers:(NSArray*)peers;

- (void) advertiseLocalPeer;
- (void) scanForPeers;

- (instancetype) initWithLocalPeer:(BLEPeer*)localPeer
                          delegate:(id<BLETransportDelegate>)delegate;

@property (nonatomic, weak) id<BLETransportDelegate> delegate;
@property (nonatomic, strong) dispatch_queue_t delegateQueue;
@property (nonatomic, strong, readonly) BLEPeer *localPeer;

@end

@interface BLETransport : NSObject <BLETransport>


@end
