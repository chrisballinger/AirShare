//
//  BLEDataMessage.m
//  Pods
//
//  Created by Christopher Ballinger on 3/3/15.
//
//

#import "BLEDataMessage.h"
#import "NSData+AirShare.h"

NSString * const kBLEFileTransferMessageHeaderExtraKey = @"extra";

@interface BLEDataMessage()
@property (nonatomic, strong) NSMutableData *serializedMessage;
@end

@implementation BLEDataMessage

- (instancetype) initWithData:(NSData*)data extraHeaders:(NSDictionary*)extraHeaders {
    if (self = [super init]) {
        _data = data;
        _extraHeaders = extraHeaders;
        if (self.data) {
            self.payloadLength = data.length;
            self.payloadHash = [data ble_sha256];
        }
    }
    return self;
}

- (NSData*) serializedData {
    if (!self.serializedMessage) {
        NSData *prefixData = [self serializedPrefixData];
        NSParameterAssert(prefixData.length > 0);
        NSData *headerData = [self serializedHeaderData];
        NSParameterAssert(headerData.length > 0);
        NSUInteger totalLength = prefixData.length + headerData.length + self.data.length;
        self.serializedMessage = [[NSMutableData alloc] initWithCapacity:totalLength];
        [self.serializedMessage appendData:prefixData];
        [self.serializedMessage appendData:headerData];
        [self.serializedMessage appendData:self.data];
    }
    return self.serializedMessage;
}

+ (NSString*) type {
    return @"datatransfer";
}

- (NSMutableDictionary*) headers {
    NSMutableDictionary *headers = [super headers];
    if (self.extraHeaders) {
        [headers setObject:self.extraHeaders forKey:kBLEFileTransferMessageHeaderExtraKey];
    }
    return headers;
}

- (void) parseHeaders:(NSDictionary *)headers {
    [super parseHeaders:headers];
    self.extraHeaders = [headers objectForKey:kBLEFileTransferMessageHeaderExtraKey];
}

- (BOOL) verifyHash {
    if (!self.payloadHash) {
        return NO;
    }
    NSData *payloadHash = [self.data ble_sha256];
    if ([self.payloadHash isEqualToData:payloadHash]) {
        return YES;
    }
    return NO;
}

@end
