//
//  BLEFileTransferMessage.m
//  Pods
//
//  Created by Christopher Ballinger on 3/3/15.
//
//

#import "BLEFileTransferMessage.h"

NSString * const kBLEFileTransferMessageHeaderFileNameKey = @"filename";
NSString * const kBLEFileTransferMessageHeaderOfferLengthKey = @"filetransfer-offer-length";
NSString * const kBLEFileTransferMessageHeaderTypeOffer = @"filetransfer-offer";
NSString * const kBLEFileTransferMessageHeaderTypeAccept = @"filetransfer-accept";
NSString * const kBLEFileTransferMessageHeaderTypeTransfer = @"filetransfer";

@interface BLEFileTransferMessage()
@property (nonatomic, strong) NSFileHandle *fileHandle;
@end

@implementation BLEFileTransferMessage

- (instancetype) initWithFileURL:(NSURL*)fileURL
                    transferType:(BLEFileTransferMessageType)transferType {
    if (self = [super init]) {
        _fileURL = fileURL;
        NSError *error = nil;
        NSString *filePath = fileURL.path;
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
        if (error) {
            NSLog(@"Error fetching file attributes: %@", error);
        } else {
            self.transferType = transferType;
            _fileLength = (NSUInteger)[fileAttributes fileSize];
            self.payloadLength = self.fileLength;
            self.fileHandle = [NSFileHandle fileHandleForReadingFromURL:self.fileURL error:&error];
            _fileName = fileURL.lastPathComponent;
            if (error) {
                NSLog(@"Error establishing file handle %@", error);
            }
        }
    }
    return self;
}

+ (NSString*) type {
    return kBLEFileTransferMessageHeaderTypeTransfer;
}

- (NSData*) payloadDataAtOffset:(NSUInteger)offset length:(NSUInteger)length {
    NSData *data = nil;
    @try {
        [self.fileHandle seekToFileOffset:offset];
        data = [self.fileHandle readDataOfLength:length];
    }
    @catch (NSException *exception) {
        NSLog(@"Error reading file: %@", exception);
    }
    return data;
}

- (void) parseHeaders:(NSDictionary *)headers {
    [super parseHeaders:headers];
    self.transferType = [self transferTypeForType:self.type];
    _fileName = [headers objectForKey:kBLEFileTransferMessageHeaderFileNameKey];
    _fileLength = [[headers objectForKey:kBLEFileTransferMessageHeaderOfferLengthKey] unsignedIntegerValue];
}



- (NSMutableDictionary*) headers {
    NSMutableDictionary *headers = [super headers];
    if (self.fileName.length) {
        [headers setObject:self.fileName forKey:kBLEFileTransferMessageHeaderFileNameKey];
    }
    [headers setObject:@(self.fileLength) forKey:kBLEFileTransferMessageHeaderOfferLengthKey];
    if (self.transferType != BLEFileTransferMessageTypeTransfer) {
        [headers removeObjectForKey:kBLESessionMessageHeaderPayloadLengthKey];
    }
    return headers;
}

- (void) setTransferType:(BLEFileTransferMessageType)transferType {
    _transferType = transferType;
    self.type = [self typeForTransferType:transferType];
    [self clearSerializationCache];
}

- (BLEFileTransferMessageType) transferTypeForType:(NSString*)type {
    BLEFileTransferMessageType transferType = BLEFileTransferMessageTypeTransfer;
    if ([type isEqualToString:kBLEFileTransferMessageHeaderTypeTransfer]) {
        transferType = BLEFileTransferMessageTypeTransfer;
    } else if ([type isEqualToString:kBLEFileTransferMessageHeaderTypeOffer]) {
        transferType = BLEFileTransferMessageTypeOffer;
    } else if ([type isEqualToString:kBLEFileTransferMessageHeaderTypeAccept]) {
        transferType = BLEFileTransferMessageTypeAccept;
    }
    return transferType;
}

- (NSString*) typeForTransferType:(BLEFileTransferMessageType)transferType {
    NSString *type = nil;
    switch (transferType) {
        case BLEFileTransferMessageTypeTransfer:
            type = kBLEFileTransferMessageHeaderTypeTransfer;
            break;
        case BLEFileTransferMessageTypeOffer:
            type = kBLEFileTransferMessageHeaderTypeOffer;
            break;
        case BLEFileTransferMessageTypeAccept:
            type = kBLEFileTransferMessageHeaderTypeAccept;
            break;
    }
    return type;
}

@end
