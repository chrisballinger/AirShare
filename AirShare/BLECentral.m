//
//  BLECentral.m
//  Pods
//
//  Created by Christopher Ballinger on 3/4/15.
//
//

#import "BLECentral.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface BLECentral () <CBCentralManagerDelegate, CBPeripheralDelegate>
@property (nonatomic, strong, readonly) NSMutableDictionary *allDiscoveredPeripherals;
@property (nonatomic, strong, readonly) NSMutableDictionary *connectedPeripherals;
@property (nonatomic, strong, readonly) CBCentralManager *centralManager;
@property (nonatomic, strong, readonly) NSMutableDictionary *peripheralDataCharacteristics;

@end

@implementation BLECentral

- (instancetype) initWithDelegate:(id<BLEBluetoothDeviceDelegate>)delegate
                      serviceUUID:(CBUUID*)serviceUUID
               characteristicUUID:(CBUUID*)characteristicUUID
               supportsBackground:(BOOL)supportsBackground {
    if (self = [super initWithDelegate:delegate serviceUUID:serviceUUID characteristicUUID:characteristicUUID supportsBackground:supportsBackground]) {
        _allDiscoveredPeripherals = [NSMutableDictionary dictionary];
        _connectedPeripherals = [NSMutableDictionary dictionary];
        _peripheralDataCharacteristics = [NSMutableDictionary dictionary];
        [self setupCentral];
    }
    return self;
}

- (BOOL) sendData:(NSData*)data
     toIdentifier:(NSString*)identifier
            error:(NSError**)error {
    [self.dataQueue queueData:data forIdentifier:identifier mtu:155];
    CBPeripheral *periperal = [self.connectedPeripherals objectForKey:identifier];
    BLEConnectionStatus status = [self connectionStatusForPeripheral:periperal];
    if (status == BLEConnectionStatusConnected) {
        [self sendQueuedDataForConnectedPeripheral:periperal];
    } else if (status == BLEConnectionStatusDisconnected) {
        if (periperal) {
            [self.centralManager connectPeripheral:periperal options:nil];
        }
    }
    return YES;
}

- (void) sendQueuedDataForConnectedPeripheral:(CBPeripheral*)peripheral {
    NSData *data = [self.dataQueue peekDataForIdentifier:peripheral.identifier.UUIDString];
    if (!data) {
        return;
    }
    CBCharacteristic *characteristic = [self dataCharacteristicForPeripheral:peripheral];
    [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    NSLog(@"Writing %d bytes to peripheral: %@", (int)data.length, peripheral);

}

- (BOOL) hasSeenIdentifier:(NSString*)identifier {
    CBPeripheral *peripheral = [self.allDiscoveredPeripherals objectForKey:identifier];
    return peripheral != nil;
}


- (CBCharacteristic*) dataCharacteristicForPeripheral:(CBPeripheral*)peripheral {
    return [self.peripheralDataCharacteristics objectForKey:peripheral.identifier.UUIDString];
}

- (void) scanForPeripherals {
    if (self.centralManager.state == CBCentralManagerStatePoweredOn) {
        BOOL allowDuplicates = NO;
        NSArray *services = @[self.serviceUUID];
        [self.centralManager scanForPeripheralsWithServices:services
                                                    options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @(allowDuplicates)}];
    } else {
        NSLog(@"central not powered on");
    }
}

- (void) setupCentral {
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    if (self.supportsBackground) {
        [options setObject:self.serviceUUID.UUIDString forKey:CBPeripheralManagerOptionRestoreIdentifierKey];
    }
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                           queue:self.eventQueue
                                                         options:options];
}

#pragma mark CBCentralManagerDelegate

- (void) centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict {
    NSLog(@"centralManager:willRestoreState: %@", dict);
    NSArray *peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey];
    [peripherals enumerateObjectsUsingBlock:^(CBPeripheral *peripheral, NSUInteger idx, BOOL *stop) {
        [self.allDiscoveredPeripherals setObject:peripheral forKey:peripheral.identifier.UUIDString];
        if (peripheral.state == CBPeripheralStateConnected) {
            [self.connectedPeripherals setObject:peripheral forKey:peripheral.identifier.UUIDString];
        }
    }];
}

- (void) centralManagerDidUpdateState:(CBCentralManager *)centralManager {
    NSLog(@"centralManagerDidUpdateState: %@", centralManager);
    [self scanForPeripherals];
}

- (BLEConnectionStatus) connectionStatusForPeripheral:(CBPeripheral*)peripheral {
    if (peripheral.state == CBPeripheralStateDisconnected) {
        return BLEConnectionStatusDisconnected;
    } else if (peripheral.state == CBPeripheralStateConnecting) {
        return BLEConnectionStatusConnecting;
    } else if (peripheral.state == CBPeripheralStateConnected) {
        BOOL connected = [self.connectedPeripherals objectForKey:peripheral.identifier.UUIDString] != nil;
        if (connected) {
            return BLEConnectionStatusConnected;
        } else {
            return BLEConnectionStatusConnecting;
        }
    }
    return BLEConnectionStatusDisconnected;
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    NSLog(@"didDiscoverPeripheral: %@ %@ %@", peripheral, advertisementData, RSSI);
    CBPeripheral *previouslySeenPeripheral = [self.allDiscoveredPeripherals objectForKey:peripheral.identifier.UUIDString];
    BLEConnectionStatus status = [self connectionStatusForPeripheral:peripheral];
    dispatch_async(self.delegateQueue, ^{
        [self.delegate device:self identifierUpdated:peripheral.identifier.UUIDString status:status extraInfo:@{@"RSSI": RSSI}];
    });
    if (!previouslySeenPeripheral) {
        [self.allDiscoveredPeripherals setObject:peripheral forKey:peripheral.identifier.UUIDString];
        peripheral.delegate = self;
        [central connectPeripheral:peripheral options:nil];
        dispatch_async(self.delegateQueue, ^{
            [self.delegate device:self identifierUpdated:peripheral.identifier.UUIDString status:BLEConnectionStatusConnecting extraInfo:nil];
        });
    }
}

- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"didConnectPeripheral: %@", peripheral);
    [peripheral discoverServices:@[self.serviceUUID]];
    dispatch_async(self.delegateQueue, ^{
        [self.delegate device:self identifierUpdated:peripheral.identifier.UUIDString status:BLEConnectionStatusConnecting extraInfo:nil];
    });
}

- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    dispatch_async(self.delegateQueue, ^{
        [self.delegate device:self identifierUpdated:peripheral.identifier.UUIDString status:BLEConnectionStatusDisconnected extraInfo:nil];
    });
}

- (void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    dispatch_async(self.delegateQueue, ^{
        [self.delegate device:self identifierUpdated:peripheral.identifier.UUIDString status:BLEConnectionStatusDisconnected extraInfo:nil];
    });
}

#pragma mark CBPeripheralDelegate

- (void) peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSString *identifier = peripheral.identifier.UUIDString;
    NSData *data = nil;
    if (error) {
        data = [self.dataQueue peekDataForIdentifier:identifier];
    } else {
        data = [self.dataQueue popDataForIdentifier:identifier];
    }
    NSLog(@"didWriteValueForCharacteristic %@ %@", data, error);
    dispatch_async(self.delegateQueue, ^{
        [self.delegate device:self dataSent:data toIdentifier:identifier error:error];
    });
    [self sendQueuedDataForConnectedPeripheral:peripheral];
}

- (void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"didUpdateValueForCharacteristic error %@", error);
        return;
    }
    NSString *identifier = peripheral.identifier.UUIDString;
    NSData *data = characteristic.value;
    dispatch_async(self.delegateQueue, ^{
        [self.delegate device:self dataReceived:data fromIdentifier:identifier];
    });
    NSLog(@"didUpdateValueForCharacteristic %@", characteristic.value);
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"didUpdateNotificationStateForCharacteristic %@ %@", characteristic, error);
    if ([characteristic.UUID isEqual:self.characteristicUUID] && !error) {
        [self.connectedPeripherals setObject:peripheral forKey:peripheral.identifier.UUIDString];
        dispatch_async(self.delegateQueue, ^{
            [self.delegate device:self identifierUpdated:peripheral.identifier.UUIDString status:BLEConnectionStatusConnected extraInfo:nil];
        });
        
    }
}

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        NSLog(@"didDiscoverCharacteristicsForService error %@" ,error);
        return;
    } else {
        NSLog(@"didDiscoverCharacteristicsForService: %@", service.characteristics);
    }
    NSArray *characteristics = service.characteristics;
    NSUInteger characteristicIndex = [characteristics indexOfObjectPassingTest:^BOOL(CBCharacteristic *characteristic, NSUInteger idx, BOOL *stop) {
        if ([characteristic.UUID isEqual:self.characteristicUUID]) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];
    if (characteristicIndex == NSNotFound) {
        NSLog(@"Characteristic not found");
        return;
    }
    CBCharacteristic *characteristic = [characteristics objectAtIndex:characteristicIndex];
    if (!characteristic) {
        NSLog(@"Characteristic not found");
        return;
    }
    [self.peripheralDataCharacteristics setObject:characteristic forKey:peripheral.identifier.UUIDString];
    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
}

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    NSLog(@"didDiscoverServices: %@", peripheral.services);
    if (peripheral.services.count == 0) {
        return;
    }
    NSUInteger serviceIndex = [peripheral.services indexOfObjectPassingTest:^BOOL(CBService *service, NSUInteger idx, BOOL *stop) {
        if ([service.UUID isEqual:self.serviceUUID]) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];
    if (serviceIndex == NSNotFound) {
        NSLog(@"Data service not found");
        return;
    }
    CBService *service = [peripheral.services objectAtIndex:serviceIndex];
    [peripheral discoverCharacteristics:@[self.characteristicUUID] forService:service];
}

@end
