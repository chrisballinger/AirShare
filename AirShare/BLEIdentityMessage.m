//
//  BLEIdentityMessage.m
//  Pods
//
//  Created by Christopher Ballinger on 3/3/15.
//
//

#import "BLEIdentityMessage.h"

NSString * const kBLEIdentityMessageHeaderPublicKey = @"pubkey";
NSString * const kBLEIdentityMessageHeaderAliasKey = @"alias";


@interface BLEIdentityMessage()
@property (nonatomic, strong) NSMutableData *serializedMessage;
@end

@implementation BLEIdentityMessage

- (instancetype) initWithPeer:(BLEPeer *)peer {
    if (self = [super init]) {
        NSParameterAssert(peer.publicKey != nil);
        _publicKey = peer.publicKey;
        _alias = peer.alias;
    }
    return self;
}

- (NSData*) serializedData {
    if (!self.serializedMessage) {
        NSData *prefixData = [self serializedPrefixData];
        NSParameterAssert(prefixData.length > 0);
        NSData *headerData = [self serializedHeaderData];
        NSParameterAssert(headerData.length > 0);
        NSUInteger totalLength = prefixData.length + headerData.length;
        self.serializedMessage = [[NSMutableData alloc] initWithCapacity:totalLength];
        [self.serializedMessage appendData:prefixData];
        [self.serializedMessage appendData:headerData];
    }
    return self.serializedMessage;
}

- (NSMutableDictionary*) headers {
    NSMutableDictionary *headers = [super headers];
    NSString *publicKeyString = [self.publicKey base64EncodedStringWithOptions:0];
    NSAssert(publicKeyString != nil, @"pubkey is nil!");
    if (publicKeyString) {
        [headers setObject:publicKeyString forKey:kBLEIdentityMessageHeaderPublicKey];
    }
    if (self.alias.length) {
        [headers setObject:self.alias forKey:kBLEIdentityMessageHeaderAliasKey];
    }
    return headers;
}

- (void) parseHeaders:(NSDictionary *)headers {
    [super parseHeaders:headers];
    NSString *publicKeyString = [headers objectForKey:kBLEIdentityMessageHeaderPublicKey];
    self.publicKey = [[NSData alloc] initWithBase64EncodedString:publicKeyString options:NSDataBase64DecodingIgnoreUnknownCharacters];
    NSParameterAssert(self.publicKey != nil);
    self.alias = [headers objectForKey:kBLEIdentityMessageHeaderAliasKey];
}

+ (NSString*) type {
    return @"identity";
}



@end
