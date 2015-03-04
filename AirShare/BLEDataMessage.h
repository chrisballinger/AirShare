//
//  BLEDataMessage.h
//  Pods
//
//  Created by Christopher Ballinger on 3/3/15.
//
//

#import "BLESessionMessage.h"

@interface BLEDataMessage : BLESessionMessage

@property (nonatomic, strong) NSData *data;

- (instancetype) initWithData:(NSData*)data;

@end
