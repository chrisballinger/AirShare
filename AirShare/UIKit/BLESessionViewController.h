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
#import "BLETransfer.h"

@interface BLESessionViewController : UIViewController <BLESessionDelegate>

@property (nonatomic, strong) BLETransferCompletionBlock transferCompletionBlock;
@property (nonatomic, strong, readonly) BLESession *session;
@property (nonatomic, strong, readonly) BLESessionManager *sessionManager;

- (instancetype) initWithOutgoingTransfer:(BLETransfer*)transfer
                           sessionManager:(BLESessionManager*)sessionManager;

- (instancetype) initWithSession:(BLESession*)session
                  sessionManager:(BLESessionManager*)sessionManager;

@end
