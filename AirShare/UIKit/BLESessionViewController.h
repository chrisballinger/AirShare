//
//  BLETransferViewController.h
//  Pods
//
//  Created by Christopher Ballinger on 2/20/15.
//
//

#import <UIKit/UIKit.h>
#import "BLESession.h"
#import "BLESessionManager.h"
#import "BLEFileTransferMessage.h"

@interface BLESessionViewController : UIViewController <BLESessionDelegate>

@property (nonatomic, strong, readonly) BLESession *session;
@property (nonatomic, strong, readonly) BLESessionManager *sessionManager;
@property (nonatomic, strong, readonly) BLEFileTransferMessage *transfer;

- (instancetype) initWithOutgoingTransfer:(BLEFileTransferMessage*)transfer
                           sessionManager:(BLESessionManager*)sessionManager;

- (instancetype) initWithSession:(BLESession*)session
                  sessionManager:(BLESessionManager*)sessionManager;

@end
