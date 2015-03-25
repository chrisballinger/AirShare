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
@property (nonatomic, strong) NSDictionary *extraHeaders;

/** extraHeaders must be JSON compatible */
- (instancetype) initWithData:(NSData*)data extraHeaders:(NSDictionary*)extraHeaders;

- (BOOL) verifyHash;

@end

extern NSString * const kBLEFileTransferMessageHeaderExtraKey;
