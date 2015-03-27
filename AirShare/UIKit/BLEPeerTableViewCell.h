//
//  BLEPeerTableViewCell.h
//  Pods
//
//  Created by Christopher Ballinger on 2/21/15.
//
//

#import <UIKit/UIKit.h>
#import "BLERemotePeer.h"

@interface BLEPeerTableViewCell : UITableViewCell

@property (nonatomic, strong, readonly) UILabel *displayNameLabel;
@property (nonatomic, strong, readonly) UILabel *lastSeenDateLabel;
@property (nonatomic, strong, readonly) UILabel *RSSILabel;

- (void) setPeer:(BLERemotePeer*)peer;

+ (NSString*) cellIdentifier;

@end
