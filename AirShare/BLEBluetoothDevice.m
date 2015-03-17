//
//  BLEBluetoothDevice.m
//  Pods
//
//  Created by Christopher Ballinger on 3/4/15.
//
//

#import "BLEBluetoothDevice.h"

@implementation BLEBluetoothDevice

- (instancetype) initWithDelegate:(id<BLEBluetoothDeviceDelegate>)delegate
                      serviceUUID:(CBUUID*)serviceUUID
               characteristicUUID:(CBUUID*)characteristicUUID
               supportsBackground:(BOOL)supportsBackground {
    if (self = [super init]) {
        _delegate = delegate;
        _serviceUUID = serviceUUID;
        _characteristicUUID = characteristicUUID;
        _delegateQueue = dispatch_queue_create("BLEBluetoothDevice Delegate", 0);
        _eventQueue = dispatch_queue_create("Bluetooth Events", 0);
        _dataQueue = [[BLETransportDataQueue alloc] init];
        _supportsBackground = supportsBackground;
    }
    return self;
}

- (BOOL) sendData:(NSData*)data
     toIdentifier:(NSString*)identifier
            error:(NSError**)error {
    return NO;
}

- (BOOL) sendStream:(NSInputStream*)inputStream
       toIdentifier:(NSString *)identifier
              error:(NSError**)error {
    return NO;
}

- (BOOL) hasSeenIdentifier:(NSString*)identifier {
    return NO;
}
- (void) start {}
- (void) stop {}
@end
