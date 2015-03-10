//
//  BLEFileTransferMessage.h
//  Pods
//
//  Created by Christopher Ballinger on 3/3/15.
//
//

#import "BLESessionMessage.h"

typedef NS_ENUM (NSInteger ,
                 BLEFileTransferMessageType ) {
    BLEFileTransferMessageTypeOffer,
    BLEFileTransferMessageTypeAccept,
    BLEFileTransferMessageTypeTransfer
};

@interface BLEFileTransferMessage : BLESessionMessage

@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic) BLEFileTransferMessageType transferType;
@property (nonatomic, readonly) NSUInteger fileLength;
@property (nonatomic, strong, readonly) NSString *fileName;

- (instancetype) initWithFileURL:(NSURL*)fileURL
                    transferType:(BLEFileTransferMessageType)transferType;

@end

extern NSString * const kBLEFileTransferMessageHeaderOfferLengthKey;
extern NSString * const kBLEFileTransferMessageHeaderTypeOffer;
extern NSString * const kBLEFileTransferMessageHeaderTypeAccept;
extern NSString * const kBLEFileTransferMessageHeaderTypeTransfer;
extern NSString * const kBLEFileTransferMessageHeaderFileNameKey;
