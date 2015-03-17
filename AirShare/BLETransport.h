//
//  BLETransport.h
//  Pods
//
//  Created by Christopher Ballinger on 2/20/15.
//
//

#import <Foundation/Foundation.h>
#import "BLEPeer.h"

typedef NS_ENUM (NSInteger ,
                 BLETransportSendDataMode ) {
    BLETransportSendDataReliable,
    BLETransportSendDataUnreliable
};

typedef NS_ENUM(NSInteger, BLEConnectionStatus) {
    BLEConnectionStatusDisconnected,
    BLEConnectionStatusConnecting,
    BLEConnectionStatusConnected
};

@class BLETransport;

@protocol BLETransportDelegate <NSObject>

- (void) transport:(BLETransport*)transport
      dataReceived:(NSData*)data
    fromIdentifier:(NSString*)identifier;

- (void) transport:(BLETransport*)transport
          dataSent:(NSData*)data
      toIdentifier:(NSString*)identifier
             error:(NSError*)error;

- (void) transport:(BLETransport*)transport
 identifierUpdated:(NSString*)identifier
  connectionStatus:(BLEConnectionStatus)connectionStatus
         extraInfo:(NSDictionary*)extraInfo;

@end

@interface BLETransport : NSObject

@property (nonatomic, strong, readonly) NSString *serviceName;

@property (nonatomic, weak) id<BLETransportDelegate> delegate;
@property (nonatomic, strong) dispatch_queue_t delegateQueue;

- (instancetype) initWithServiceName:(NSString*)serviceName
                            delegate:(id<BLETransportDelegate>)delegate;

- (BOOL) sendData:(NSData*)data
    toIdentifiers:(NSArray*)identifiers
         withMode:(BLETransportSendDataMode)mode
            error:(NSError**)error;

- (BOOL) sendStream:(NSInputStream*)inputStream
       toIdentifier:(NSString*)identifier
           withMode:(BLETransportSendDataMode)mode
              error:(NSError**)error;

- (void) advertise;
- (void) scan;
- (void) stop;

@end
