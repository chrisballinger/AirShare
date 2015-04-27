//
//  BLEBluetoothDevice.h
//  Pods
//
//  Created by Christopher Ballinger on 3/4/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BLETransport.h"
#import "BLETransportDataQueue.h"

@class BLEBluetoothDevice;

@protocol BLEBluetoothDeviceDelegate <NSObject>

- (void) device:(BLEBluetoothDevice*)device
   dataReceived:(NSData*)data
 fromIdentifier:(NSString*)identifier;

- (void) device:(BLEBluetoothDevice*)device
       dataSent:(NSData*)data
   toIdentifier:(NSString*)identifier
          error:(NSError*)error;

- (void) device:(BLEBluetoothDevice*)device
identifierUpdated:(NSString*)identifier
         status:(BLEConnectionStatus)status
      extraInfo:(NSDictionary*)extraInfo;

@end


@interface BLEBluetoothDevice : NSObject

@property (nonatomic, strong, readonly) CBUUID *serviceUUID;
@property (nonatomic, strong, readonly) CBUUID *characteristicUUID;
@property (nonatomic, weak) id<BLEBluetoothDeviceDelegate> delegate;
@property (nonatomic, strong) dispatch_queue_t delegateQueue;
@property (nonatomic, strong) dispatch_queue_t eventQueue;
@property (nonatomic, strong, readonly) BLETransportDataQueue *dataQueue;
@property (nonatomic) BOOL supportsBackground;

- (instancetype) initWithDelegate:(id<BLEBluetoothDeviceDelegate>)delegate
                      serviceUUID:(CBUUID*)serviceUUID
               characteristicUUID:(CBUUID*)characteristicUUID
               supportsBackground:(BOOL)supportsBackground;

- (BOOL) sendData:(NSData*)data
     toIdentifier:(NSString*)identifier
            error:(NSError**)error;

- (BOOL) hasSeenIdentifier:(NSString*)identifier;


- (void) start;
- (void) stop;

@end
