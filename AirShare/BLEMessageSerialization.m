//
//  BLEMessageSerialization.m
//  Pods
//
//  Created by Christopher Ballinger on 3/2/15.
//
//

#import "BLEMessageSerialization.h"
#import "BLEFileTransferMessage.h"
#import "BLEDataMessage.h"
#import "BLEIdentityMessage.h"

@interface BLEMessageSerialization ()
@property (nonatomic, strong) NSData *prefixData;
@property (nonatomic, strong) NSMutableData *headerData;
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic, strong) BLESessionMessage *sessionMessage;
@property (nonatomic) uint8_t version;
@property (nonatomic) uint32_t headerLength;

/** Used for Data Message */
@property (nonatomic, strong) NSMutableData *incomingDataMessagePayload;
@end

@implementation BLEMessageSerialization

- (instancetype) initWithDelegate:(id<BLEMessageSerializationDelegate>)delegate {
    if (self = [super init]) {
        _callbackQueue = dispatch_get_main_queue();
        _delegate = delegate;
    }
    return self;
}

- (void) receiveData:(NSData*)data {
    if (!self.prefixData) {
        if (data.length >= kBLESessionMessagePrefixLength) {
            _prefixData = [data subdataWithRange:NSMakeRange(0, kBLESessionMessagePrefixLength)];
            _version = [BLESessionMessage versionFromPrefixData:self.prefixData];
            _headerLength = [BLESessionMessage headerLengthFromPrefixData:self.prefixData];
            data = [data subdataWithRange:NSMakeRange(kBLESessionMessagePrefixLength, data.length - kBLESessionMessagePrefixLength)];
        }
    }
    if (!self.headerData && self.headerLength > 0) {
        _headerData = [NSMutableData dataWithCapacity:self.headerLength];
    }
    if (self.headerData && self.headerData.length < self.headerLength && data.length > 0) {
        NSUInteger remainingHeaderBytes = self.headerLength - self.headerData.length;
        if (remainingHeaderBytes > data.length) {
            remainingHeaderBytes = data.length;
        }
        NSData *partialHeaderData = [data subdataWithRange:NSMakeRange(0, remainingHeaderBytes)];
        [self.headerData appendData:partialHeaderData];
        data = [data subdataWithRange:NSMakeRange(remainingHeaderBytes, data.length - remainingHeaderBytes)];
    }
    if (!self.headers && self.headerData && self.headerData.length == self.headerLength) {
        NSError *error = nil;
        NSDictionary *headers = [BLESessionMessage headersFromData:self.headerData version:self.version error:&error];
        if (headers) {
            self.headers = headers;
        } else if (error) {
            NSLog(@"Error parsing headers: %@", error);
        }
    }
    if (self.headers && !self.sessionMessage) {
        NSString *type = [self.headers objectForKey:kBLESessionMessageHeaderTypeKey];
        BLESessionMessage *sessionMessage = nil;
        Class messageClass = nil;
        if ([type isEqualToString:[BLEIdentityMessage type]]) {
            messageClass = [BLEIdentityMessage class];
        } else if ([type isEqualToString:[BLEDataMessage type]]) {
            messageClass = [BLEDataMessage class];
        } else if ([type isEqualToString:[BLEFileTransferMessage type]]) {
            messageClass = [BLEFileTransferMessage class];
        }
        if (messageClass) {
            sessionMessage = [[messageClass alloc] initWithVersion:self.version headers:self.headers];
        }
        if (sessionMessage) {
            _sessionMessage = sessionMessage;
            dispatch_async(self.callbackQueue, ^{
                [self.delegate serialization:self headerComplete:sessionMessage];
            });
        }
    }
    if (self.sessionMessage) {
        if ([self.sessionMessage isKindOfClass:[BLEDataMessage class]]) {
            BLEDataMessage *dataMessage = (BLEDataMessage*)self.sessionMessage;
            if (!self.incomingDataMessagePayload) {
                _incomingDataMessagePayload = [NSMutableData dataWithCapacity:dataMessage.payloadLength];
            }
            [self.incomingDataMessagePayload appendData:data];
            if (dataMessage.payloadLength > 0) {
                if (self.incomingDataMessagePayload.length < dataMessage.payloadLength) {
                    float progress = (float)self.incomingDataMessagePayload.length / (float)dataMessage.payloadLength;
                    dispatch_async(self.callbackQueue, ^{
                        [self.delegate serialization:self message:dataMessage incomingData:data progress:progress];
                    });
                } else if (self.incomingDataMessagePayload.length == dataMessage.payloadLength) {
                    dataMessage.data = self.incomingDataMessagePayload;
                    self.incomingDataMessagePayload = nil;
                    dispatch_async(self.callbackQueue, ^{
                        [self.delegate serialization:self transferComplete:dataMessage];
                    });
                }
            }
        }
    }
}

@end
