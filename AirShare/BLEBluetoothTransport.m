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
#import "NSData+AirShare.h"

@implementation BLEBluetoothTransport

- (instancetype) initWithServiceName:(NSString *)serviceName delegate:(id<BLETransportDelegate>)delegate supportsBackground:(BOOL)supportsBackground {
    if (self = [super initWithServiceName:serviceName delegate:delegate]) {
        _supportsBackground = supportsBackground;
        CBUUID *characteristicUUID = [CBUUID UUIDWithString:@"72A7700C-859D-4317-9E35-D7F5A93005B1"];
        CBUUID *serviceUUID = [self uuidFromServiceName:serviceName];
        _central = [[BLECentral alloc] initWithDelegate:self serviceUUID:serviceUUID characteristicUUID:characteristicUUID supportsBackground:supportsBackground];
        _peripheral = [[BLEPeripheral alloc] initWithDelegate:self serviceUUID:serviceUUID characteristicUUID:characteristicUUID supportsBackground:supportsBackground];
    }
    return self;
}

- (CBUUID*) uuidFromServiceName:(NSString*)serviceName {
    NSData *sha256 = [[serviceName dataUsingEncoding:NSUTF8StringEncoding] ble_sha256];
    NSString *hexString = [sha256 ble_hexString];
    hexString = [hexString uppercaseString];
    NSMutableString *uuidString = [[NSMutableString alloc] init];
    [uuidString appendString:[hexString substringToIndex:32]];
    [uuidString insertString:@"-" atIndex:8];
    [uuidString insertString:@"-" atIndex:13];
    [uuidString insertString:@"-" atIndex:18];
    [uuidString insertString:@"-" atIndex:23];
    CBUUID *uuid = [CBUUID UUIDWithString:uuidString];
    return uuid;
}

- (instancetype) initWithServiceName:(NSString *)serviceName delegate:(id<BLETransportDelegate>)delegate {
    if (self = [self initWithServiceName:serviceName delegate:delegate supportsBackground:NO]) {
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
        if (seenOnCentral && seenOnPeripheral) {
            NSLog(@"seen on both central and peripheral: %@", identifier);
        }
        if (seenOnPeripheral) {
            [self.peripheral sendData:data toIdentifier:identifier error:error];
        } else if (seenOnCentral) {
            [self.central sendData:data toIdentifier:identifier error:error];
        } else if (!seenOnCentral && !seenOnPeripheral) {
            //NSAssert(NO, @"OH NO!");
            NSLog(@"identifier not seen: %@", identifier);
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
    
    // The BLE Central device always plays the client role, so all its connections are to hosts
    BOOL isIdentifierHost = [device isKindOfClass:[BLECentral class]];
    
    dispatch_async(self.delegateQueue, ^{
        [self.delegate transport:self identifierUpdated:identifier connectionStatus:status isIdentifierHost:isIdentifierHost extraInfo:extraInfo];
    });
}


@end
