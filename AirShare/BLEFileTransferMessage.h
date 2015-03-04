//
//  BLEFileTransferMessage.h
//  Pods
//
//  Created by Christopher Ballinger on 3/3/15.
//
//

#import "BLESessionMessage.h"

@interface BLEFileTransferMessage : BLESessionMessage

@property (nonatomic, strong) NSURL *fileURL;

@end
