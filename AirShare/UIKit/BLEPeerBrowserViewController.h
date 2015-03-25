//
//  BLEPeerBrowserViewController.h
//  Pods
//
//  Created by Christopher Ballinger on 2/20/15.
//
//

#import <UIKit/UIKit.h>
#import "BLESessionManager.h"

@class BLEPeerBrowserViewController;

typedef NS_ENUM(NSUInteger, BLEPeerBrowserMode) {
    BLEPeerBrowserModeSend,
    BLEPeerBrowserModeReceive,
    BLEPeerBrowserModeBoth
};

@protocol BLEPeerBrowserDelegate <NSObject>

- (void) peerBrowser:(BLEPeerBrowserViewController*)peerBrowser
        dataReceived:(NSData*)data
             headers:(NSDictionary*)headers;

- (void) peerBrowser:(BLEPeerBrowserViewController*)peerBrowser
            dataSent:(NSData*)data
             headers:(NSDictionary*)headers;

@end

@interface BLEPeerBrowserViewController : UIViewController <BLESessionManagerDelegate>

@property (nonatomic, strong, readonly) BLESessionManager *sessionManager;
@property (nonatomic) BLEPeerBrowserMode mode;
@property (nonatomic, weak) id<BLEPeerBrowserDelegate> delegate;
@property (nonatomic) dispatch_queue_t delegateQueue;

- (instancetype) initWithSessionManager:(BLESessionManager*)sessionManager;

- (void) addOutgoingData:(NSData*)data headers:(NSDictionary*)headers;

@end
