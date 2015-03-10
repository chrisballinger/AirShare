//
//  BLEPeerBrowserViewController.h
//  Pods
//
//  Created by Christopher Ballinger on 2/20/15.
//
//

#import <UIKit/UIKit.h>
#import "BLESessionManager.h"

@interface BLEPeerBrowserViewController : UIViewController <BLESessionManagerDelegate>

@property (nonatomic, strong, readonly) BLESessionManager *sessionManager;

- (instancetype) initWithSessionManager:(BLESessionManager*)sessionManager;

@end
