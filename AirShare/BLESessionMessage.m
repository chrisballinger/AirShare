//
//  BLESessionMessage.m
//  Pods
//
//  Created by Christopher Ballinger on 3/2/15.
//
//

#import "BLESessionMessage.h"

const NSUInteger kBLESessionMessagePrefixLength = 5;

NSString * const kBLESessionMessageHeaderTypeKey = @"type";
NSString * const kBLESessionMessageHeaderPayloadLengthKey = @"length";
NSString * const kBLESessionMessageHeaderIdentifierKey = @"id";

@implementation BLESessionMessage

- (instancetype) init {
    NSString *identifier = [[NSUUID UUID] UUIDString];
    if (self = [self initWithIdentifier:identifier]) {
    }
    return self;
}

- (instancetype) initWithIdentifier:(NSString*)identifier {
    if (self = [super init]) {
        _identifer = identifier;
        _version = 1;
    }
    return self;
}

- (instancetype) initWithPrefixData:(NSData*)prefixData {
    if (self = [super init]) {
    }
    return self;
}

- (void) parsePrefixData:(NSData*)prefixData {
    _version = [BLESessionMessage versionFromPrefixData:prefixData];
    _headerLength = [BLESessionMessage headerLengthFromPrefixData:prefixData];
}

- (NSData*) serializePrefixData {
    NSMutableData *prefixData = [NSMutableData dataWithLength:kBLESessionMessagePrefixLength];
    [prefixData appendBytes:&_version length:1];
    uint32_t headerLength = NSSwapHostIntToLittle(_headerLength);
    [prefixData appendBytes:&headerLength length:4];
    return prefixData;
}


+ (uint8_t) versionFromPrefixData:(NSData*)prefixData {
    NSAssert(prefixData.length == kBLESessionMessagePrefixLength, @"Bad prefix");
    if (prefixData.length != kBLESessionMessagePrefixLength) {
        return 0;
    }
    uint8_t version = 0;
    [prefixData getBytes:&version range:NSMakeRange(0, 1)];
    return version;
}

+ (uint32_t) headerLengthFromPrefixData:(NSData*)prefixData {
    NSAssert(prefixData.length == kBLESessionMessagePrefixLength, @"Bad prefix");
    if (prefixData.length != kBLESessionMessagePrefixLength) {
        return 0;
    }
    uint32_t headerLength = 0;
    [prefixData getBytes:&headerLength range:NSMakeRange(1, 4)];
    headerLength = NSSwapLittleIntToHost(headerLength);
    return headerLength;
}

- (void) parseHeaders:(NSDictionary *)headers {
    _type = [headers objectForKey:kBLESessionMessageHeaderTypeKey];
    _identifer = [headers objectForKey:kBLESessionMessageHeaderIdentifierKey];
    _payloadLength = [[headers objectForKey:kBLESessionMessageHeaderPayloadLengthKey] unsignedIntegerValue];
}

- (NSMutableDictionary*) headers {
    NSMutableDictionary *headers = [[NSMutableDictionary alloc] init];
    [headers setObject:self.type forKey:kBLESessionMessageHeaderTypeKey];
    [headers setObject:self.identifer forKey:kBLESessionMessageHeaderIdentifierKey];
    [headers setObject:@(self.payloadLength) forKey:kBLESessionMessageHeaderPayloadLengthKey];
    return headers;
}

- (NSData*) serializeHeaderData {
    NSDictionary *headers = [self headers];
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:headers options:0 error:&error];
    return data;
}

+ (NSDictionary*) headersFromData:(NSData*)data version:(uint8_t)version error:(NSError**)error {
    NSDictionary *headers = [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
    return headers;
}

@end
