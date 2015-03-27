//
//  BLEPeerTableViewCell.m
//  Pods
//
//  Created by Christopher Ballinger on 2/21/15.
//
//

#import "BLEPeerTableViewCell.h"
#import "PureLayout.h"

@interface BLEPeerTableViewCell()
@property (nonatomic) BOOL hasAddedConstraints;
@end

@implementation BLEPeerTableViewCell

- (instancetype) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setupDisplayNameLabel];
        [self setupLastSeenDateLabel];
        [self setupRSSILabel];
        [self updateConstraintsIfNeeded];
    }
    return self;
}

- (void) setupDisplayNameLabel {
    _displayNameLabel = [[UILabel alloc] init];
    self.displayNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.displayNameLabel];
}

- (void) setupLastSeenDateLabel {
    _lastSeenDateLabel = [[UILabel alloc] init];
    self.lastSeenDateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.lastSeenDateLabel];
}

- (void) setupRSSILabel {
    _RSSILabel = [[UILabel alloc] init];
    self.RSSILabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.RSSILabel];
}


- (void) updateConstraints {
    if (!self.hasAddedConstraints) {
        [self.displayNameLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:5];
        [self.displayNameLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:5];
        [self.displayNameLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:5];
        [self.displayNameLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.lastSeenDateLabel];
        [self.lastSeenDateLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:5];
        [self.lastSeenDateLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:5];
        [self.lastSeenDateLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:5];
        [self.RSSILabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:5];
        [self.RSSILabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:5];
        [self.displayNameLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.lastSeenDateLabel];
        self.hasAddedConstraints = YES;
    }
    [super updateConstraints];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void) setPeer:(BLERemotePeer*)peer {
    self.displayNameLabel.text = peer.alias;
    //self.lastSeenDateLabel.text = peer.lastSeenDate.description;
    //self.RSSILabel.text = peer.RSSI.description;
}

+ (NSString*) cellIdentifier {
    return NSStringFromClass([self class]);
}

@end
