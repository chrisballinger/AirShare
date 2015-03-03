//
//  BLESessionMessage.h
//  Pods
//
//  Created by Christopher Ballinger on 3/2/15.
//
//

#import <Foundation/Foundation.h>

@interface BLESessionMessage : NSObject

// Prefix
@property (nonatomic, readonly) uint8_t version;
@property (nonatomic, readonly) uint32_t headerLength;

// Derived from values in header
@property (nonatomic, strong, readonly) NSString *identifer;
@property (nonatomic, readonly) NSUInteger payloadLength;
@property (nonatomic, strong, readonly) NSString *type;

- (NSMutableDictionary*) headers;
- (void) parseHeaders:(NSDictionary *)headers;

- (NSData*) payloadDataAtOffset:(NSUInteger)offset length:(NSUInteger)length;

- (void) parsePrefixData:(NSData*)prefixData;
- (NSData*) serializePrefixData;
- (NSData*) serializeHeaderData;

- (instancetype) initWithIdentifier:(NSString*)identifier;

- (instancetype) initWithPrefixData:(NSData*)prefixData;

+ (uint8_t) versionFromPrefixData:(NSData*)prefixData;
+ (uint32_t) headerLengthFromPrefixData:(NSData*)prefixData;
+ (NSDictionary*) headersFromData:(NSData*)data version:(uint8_t)version error:(NSError**)error;

@end

extern const NSUInteger kBLESessionMessagePrefixLength;

extern NSString * const kBLESessionMessageHeaderTypeKey;
extern NSString * const kBLESessionMessageHeaderPayloadLengthKey;
extern NSString * const kBLESessionMessageHeaderIdentifierKey;

