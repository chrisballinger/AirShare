//
//  BLEBluetoothTransport.m
//  Pods
//
//  Created by Christopher Ballinger on 3/4/15.
//
//

#import "BLEBluetoothTransport.h"
#import "BLECentral.h"
#import "BLEPeripheral.h"

@implementation BLEBluetoothTransport

- (instancetype) initWithServiceName:(NSString *)serviceName delegate:(id<BLETransportDelegate>)delegate {
    if (self = [super initWithServiceName:serviceName delegate:delegate]) {
        CBUUID *characteristicUUID = [CBUUID UUIDWithString:@"72A7700C-859D-4317-9E35-D7F5A93005B1"];
        CBUUID *serviceUUID = [CBUUID UUIDWithString:@"B491602C-C912-47AE-B639-9C17A4AADB06"];
        _central = [[BLECentral alloc] initWithDelegate:self serviceUUID:serviceUUID characteristicUUID:characteristicUUID];
        _peripheral = [[BLEPeripheral alloc] initWithDelegate:self serviceUUID:serviceUUID characteristicUUID:characteristicUUID];
    }
    return self;
}

- (void) advertise {
    [self.peripheral start];
}

- (void) scan {
    [self.central start];
}

- (void) stop {
    [self.central stop];
    [self.peripheral stop];
}


- (BOOL) sendData:(NSData*)data
    toIdentifiers:(NSArray*)identifiers
         withMode:(BLETransportSendDataMode)mode
            error:(NSError**)error {
    [identifiers enumerateObjectsUsingBlock:^(NSString *identifier, NSUInteger idx, BOOL *stop) {
        BOOL seenOnCentral = [self.central hasSeenIdentifier:identifier];
        BOOL seenOnPeripheral = [self.peripheral hasSeenIdentifier:identifier];
        if (seenOnCentral) {
            [self.central sendData:data toIdentifier:identifier error:error];
        } else if (seenOnPeripheral) {
            [self.peripheral sendData:data toIdentifier:identifier error:error];
        }
    }];
    return NO;
}

#pragma mark BLEBluetoothDeviceDelegate

- (void) device:(BLEBluetoothDevice*)device
   dataReceived:(NSData*)data
 fromIdentifier:(NSString*)identifier {
    dispatch_async(self.delegateQueue, ^{
        [self.delegate transport:self dataReceived:data fromIdentifier:identifier];
    });
}

- (void) device:(BLEBluetoothDevice*)device
       dataSent:(NSData*)data
   toIdentifier:(NSString*)identifier
          error:(NSError*)error {
    dispatch_async(self.delegateQueue, ^{
        [self.delegate transport:self dataSent:data toIdentifier:identifier error:error];
    });
}

- (void) device:(BLEBluetoothDevice*)device
identifierUpdated:(NSString*)identifier
         status:(BLEConnectionStatus)status
      extraInfo:(NSDictionary*)extraInfo {
    dispatch_async(self.delegateQueue, ^{
        [self.delegate transport:self identifierUpdated:identifier connectionStatus:status extraInfo:extraInfo];
    });
}


@end
