//
//  BLETransfer.h
//  Pods
//
//  Created by Christopher Ballinger on 2/19/15.
//
//

#import <Foundation/Foundation.h>

@class BLETransfer;

typedef void (^BLETransferCompletionBlock)(BLETransfer *transfer, NSError *error);

@interface BLETransfer : NSObject

@property (nonatomic) BOOL isIncoming;

/** Data being transferred, nil if transferring file */
@property (nonatomic, strong, readonly) NSData *data;

/* File resource being transferred. You can change this to a different destination URL for incoming files. */
@property (nonatomic, strong) NSURL *fileURL;

/* Raw headers for transfer */
@property (nonatomic, strong, readonly) NSDictionary *headers;

/* Total length in bytes */
@property (nonatomic, readonly) NSUInteger totalLength;

+ (instancetype) transferWithFileURL:(NSURL*)fileURL;
+ (instancetype) transferWithData:(NSData*)data;

@end
