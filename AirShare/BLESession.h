//
//  BLESession.h
//  Pods
//
//  Created by Christopher Ballinger on 2/19/15.
//
//

#import <Foundation/Foundation.h>
#import "BLELocalPeer.h"
#import "BLEFileTransferMessage.h"
#import "BLETransport.h"

@class BLESession;

@protocol BLESessionDelegate <NSObject>
- (void) session:(BLESession*)session transferOffered:(BLEFileTransferMessage*)transfer;
@end

@interface BLESession : NSObject <BLETransportDelegate>

@property (nonatomic, strong, readonly) BLETransport *transport;
@property (nonatomic, strong, readonly) BLELocalPeer *localPeer;
@property (nonatomic, strong, readonly) BLEPeer *connectedPeer;

@property (nonatomic, weak) id<BLESessionDelegate> delegate;
@property (nonatomic, strong) dispatch_queue_t delegateQueue;

- (instancetype) initWithTransport:(BLETransport*)transport
                         localPeer:(BLELocalPeer*)localPeer
                     connectedPeer:(BLEPeer*)connectedPeer
                          delegate:(id<BLESessionDelegate>)delegate;

- (void) acceptTransfer:(BLEFileTransferMessage*)transfer
               progress:(void (^)(float progress))progressBlock
             completion:(void (^)(BOOL success, NSError * error))completionBlock;

- (void) offerTransfer:(BLEFileTransferMessage*)transfer
              progress:(void (^)(float progress))progressBlock
            completion:(void (^)(BOOL success, NSError * error))completionBlock;

+ (UIImage*) identiconForSession:(BLESession*)session asReceiver:(BOOL)asReceiver;

@end
