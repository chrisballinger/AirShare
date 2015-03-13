//
//  BLEPeripheral.m
//  Pods
//
//  Created by Christopher Ballinger on 3/4/15.
//
//

#import "BLEPeripheral.h"
#import <CoreBluetooth/CoreBluetooth.h>

static NSString * const kBLEBroadcasterRestoreIdentifier = @"kBLEBroadcasterRestoreIdentifier";


@interface BLEPeripheral () <CBPeripheralManagerDelegate>
@property (nonatomic, strong, readonly) CBPeripheralManager *peripheralManager;
@property (nonatomic) BOOL serviceAdded;
@property (nonatomic, strong, readonly) CBMutableService *dataService;
@property (nonatomic, strong, readonly) CBMutableCharacteristic *dataCharacteristic;
@property (nonatomic, strong, readonly) NSMutableDictionary *subscribedCentrals;
@property (nonatomic, readonly) dispatch_queue_t eventQueue;

@end

@implementation BLEPeripheral

- (instancetype) initWithDelegate:(id<BLEBluetoothDeviceDelegate>)delegate
                      serviceUUID:(CBUUID*)serviceUUID
               characteristicUUID:(CBUUID*)characteristicUUID {
    if (self = [super initWithDelegate:delegate serviceUUID:serviceUUID characteristicUUID:characteristicUUID]) {
        _subscribedCentrals = [NSMutableDictionary dictionary];
        [self setupCharacteristics];
        [self setupServices];
        [self setupPeripheral];
    }
    return self;
}

- (BOOL) sendData:(NSData*)data
     toIdentifier:(NSString*)identifier
            error:(NSError**)error {
    [self.dataQueue queueData:data forIdentifier:identifier];
    CBCentral *central = [self.subscribedCentrals objectForKey:identifier];
    if (!central) {
        return NO;
    }
    [self writeQueuedDataForCentral:central];
    return YES;
}

- (void) writeQueuedDataForCentral:(CBCentral*)central {
    NSString *identifier = central.identifier.UUIDString;
    NSData *data = [self.dataQueue peekDataForIdentifier:identifier];
    if (!data) {
        return;
    }
    NSUInteger mtu = central.maximumUpdateValueLength;
    BOOL success = [self.peripheralManager updateValue:data forCharacteristic:self.dataCharacteristic onSubscribedCentrals:@[central]];
    NSLog(@"Writing %d bytes to central: %@", (int)data.length, central);
    if (success) {
        [self.dataQueue popDataForIdentifier:identifier];
    }
}

- (BOOL) hasSeenIdentifier:(NSString*)identifier {
    CBCentral *central = [self.subscribedCentrals objectForKey:identifier];
    return central != nil;
}


- (void) setupPeripheral {
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self
                                                                 queue:self.eventQueue
                                                               options:@{CBPeripheralManagerOptionRestoreIdentifierKey: kBLEBroadcasterRestoreIdentifier,
                                                                         CBPeripheralManagerOptionShowPowerAlertKey: @YES}];
}

- (void) setupCharacteristics {
    _dataCharacteristic = [[CBMutableCharacteristic alloc] initWithType:self.characteristicUUID properties:CBCharacteristicPropertyRead | CBCharacteristicPropertyWrite | CBCharacteristicPropertyIndicate  value:nil permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable];
}

- (void) setupServices {
    CBMutableService *dataService = [[CBMutableService alloc] initWithType:self.serviceUUID primary:YES];
    dataService.characteristics = @[self.dataCharacteristic];
    _dataService = dataService;
}

- (void) broadcastPeripheral {
    if (self.peripheralManager.state == CBPeripheralManagerStatePoweredOn) {
        if (!self.serviceAdded) {
            [self.peripheralManager addService:self.dataService];
            self.serviceAdded = YES;
        }
        
        if (!self.peripheralManager.isAdvertising) {
            [self.peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey: @[self.dataService.UUID],
                                                       CBAdvertisementDataLocalNameKey: @"AirShare"}];
        }
    } else {
        NSLog(@"peripheral not powered on");
    }
}

#pragma mark CBPeripheralManagerDelegate

- (void) peripheralManager:(CBPeripheralManager *)peripheral willRestoreState:(NSDictionary *)dict {
    NSLog(@"peripheralManager:willRestoreState: %@", dict);
    NSArray *restoredServices = dict[CBPeripheralManagerRestoredStateServicesKey];
    NSDictionary *restoredAdvertisementDict = dict[CBPeripheralManagerRestoredStateAdvertisementDataKey];
}


- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheralManager {
    NSLog(@"peripheralManagerDidUpdateState: %@", peripheralManager);
    [self broadcastPeripheral];
}

- (void) peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    [self.subscribedCentrals setObject:central forKey:central.identifier.UUIDString];
    NSLog(@"peripheralManager:didSubscribeToCharacteristic: %@ %@", central, characteristic);
}

- (void) peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {
    [self.subscribedCentrals removeObjectForKey:central.identifier.UUIDString];
    NSLog(@"peripheralManager:didUnsubscribeFromCharacteristic: %@ %@", central, characteristic);
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {
    NSArray *centrals = [self.subscribedCentrals allValues];
    [centrals enumerateObjectsUsingBlock:^(CBCentral *central, NSUInteger idx, BOOL *stop) {
        [self writeQueuedDataForCentral:central];
    }];
    NSLog(@"peripheralManagerIsReadyToUpdateSubscribers");
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
    NSLog(@"peripheralManagerDidStartAdvertising: %@ %@", peripheral, error);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {
    NSLog(@"peripheralManager:didAddService: %@ %@", service, error);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests {
    NSLog(@"didReceiveWriteRequests: %@", requests);
    [requests enumerateObjectsUsingBlock:^(CBATTRequest *request, NSUInteger idx, BOOL *stop) {
        NSData *data = request.value;
        NSLog(@"write (%d bytes) %@", (int)data.length, data);
        NSString *identifier = request.central.identifier.UUIDString;
        dispatch_async(self.delegateQueue, ^{
            [self.delegate device:self dataReceived:data fromIdentifier:identifier];
        });
        [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
    }];
    
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {
    NSLog(@"didReceiveReadRequest: %@", request);
    if (request) {
        [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
    }
}

@end
