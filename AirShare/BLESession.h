//
//  BLESession.h
//  Pods
//
//  Created by Christopher Ballinger on 2/19/15.
//
//

#import <Foundation/Foundation.h>
#import "BLEPeer.h"
#import "BLETransfer.h"
#import "BLETransport.h"

@class BLESession;

@protocol BLESessionDelegate <NSObject>
- (void) session:(BLESession*)session transferOffered:(BLETransfer*)transfer;
@end

@interface BLESession : NSObject <BLETransportDelegate>

@property (nonatomic, strong, readonly) BLETransport *transport;
@property (nonatomic, strong, readonly) BLELocalPeer *localPeer;
@property (nonatomic, strong, readonly) BLEPeer *connectedPeer;

@property (nonatomic, weak) id<BLESessionDelegate> delegate;

- (void) acceptTransfer:(BLETransfer*)transfer
               progress:(void (^)(float progress))progressBlock
             completion:(void (^)(BOOL success, NSError * error))completionBlock;

- (void) offerTransfer:(BLETransfer*)transfer
              progress:(void (^)(float progress))progressBlock
            completion:(void (^)(BOOL success, NSError * error))completionBlock;

+ (UIImage*) identiconForSession:(BLESession*)session asReceiver:(BOOL)asReceiver;

@end
