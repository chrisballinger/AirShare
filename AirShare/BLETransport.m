//
//  BLETransport.m
//  Pods
//
//  Created by Christopher Ballinger on 2/20/15.
//
//

#import "BLETransport.h"
#import <CoreBluetooth/CoreBluetooth.h>

static NSString * const kBLEBroadcasterRestoreIdentifier = @"kBLEBroadcasterRestoreIdentifier";
static NSString * const kBLEScannerRestoreIdentifier = @"kBLEScannerRestoreIdentifier";

@interface BLETransport() <CBCentralManagerDelegate, CBPeripheralManagerDelegate, CBPeripheralDelegate>
@property (nonatomic, strong, readonly) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong, readonly) CBCentralManager *centralManager;

@property (nonatomic, strong, readonly) CBMutableService *dataService;
@property (nonatomic, strong, readonly) CBMutableCharacteristic *dataCharacteristic;
@property (nonatomic, readonly) dispatch_queue_t eventQueue;

@property (nonatomic, strong, readonly) NSMutableDictionary *identitiesToCentralCache;
@property (nonatomic, strong, readonly) NSMutableDictionary *identitiesToPeripheralCache;


@property (nonatomic, strong, readonly) NSMutableDictionary *peerToPeripheralCache;

@property (nonatomic, strong, readonly) NSMutableDictionary *allDiscoveredPeripherals;
@property (nonatomic, strong, readonly) NSMutableDictionary *allDiscoveredCentrals;

@property (nonatomic, strong, readonly) NSMutableDictionary *connectedPeripherals;

@property (nonatomic, strong, readonly) NSMutableDictionary *peripheralDataCharacteristics;
@end

@implementation BLETransport
@synthesize delegate = _delegate;
@synthesize delegateQueue = _delegateQueue;

- (void) setupCharacteristics {
    _dataCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"72A7700C-859D-4317-9E35-D7F5A93005B1"] properties:CBCharacteristicPropertyRead | CBCharacteristicPropertyWrite | CBCharacteristicPropertyIndicate  value:nil permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable];
}

- (void) setupServices {
    CBMutableService *dataService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:@"B491602C-C912-47AE-B639-9C17A4AADB06"] primary:YES];
    dataService.characteristics = @[self.dataCharacteristic];
    _dataService = dataService;
}

- (void) setupPeripheral {
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self
                                                                 queue:_eventQueue
                                                               options:@{CBPeripheralManagerOptionRestoreIdentifierKey: kBLEBroadcasterRestoreIdentifier,
                                                                         CBPeripheralManagerOptionShowPowerAlertKey: @YES}];
}

- (void) setupCentral {
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                           queue:_eventQueue
                                                         options:@{CBCentralManagerOptionRestoreIdentifierKey: kBLEScannerRestoreIdentifier}];
}

- (void) scanForPeripherals {
    if (self.centralManager.state == CBCentralManagerStatePoweredOn) {
        BOOL allowDuplicates = NO;
        NSArray *services = @[self.dataService.UUID];
        [self.centralManager scanForPeripheralsWithServices:services
                                                    options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @(allowDuplicates)}];
    } else {
        NSLog(@"central not powered on");
    }
}

- (void) broadcastPeripheral {
    if (self.peripheralManager.state == CBPeripheralManagerStatePoweredOn) {
        [self.peripheralManager addService:self.dataService];

        if (!self.peripheralManager.isAdvertising) {
            [self.peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey: @[self.dataService.UUID],
                                                       CBAdvertisementDataLocalNameKey: @"AirShare"}];
        }
    } else {
        NSLog(@"peripheral not powered on");
    }
}

- (CBCharacteristic*) dataCharacteristicForPeripheral:(CBPeripheral*)peripheral {
    return [self.peripheralDataCharacteristics objectForKey:peripheral.identifier.UUIDString];
}

#pragma mark BLETransport

- (BOOL) sendData:(NSData*)data
    toIdentifiers:(NSArray*)identifiers
         withMode:(BLETransportSendDataMode)mode
            error:(NSError**)error {
    NSMutableArray *peripherals = [NSMutableArray array];
    NSMutableArray *centrals = [NSMutableArray array];
    [identifiers enumerateObjectsUsingBlock:^(NSString *identifier, NSUInteger idx, BOOL *stop) {
        CBPeripheral *peripheral = [self.allDiscoveredPeripherals objectForKey:identifier];
        [peripherals addObject:peripheral];
    }];
    [peripherals enumerateObjectsUsingBlock:^(CBPeripheral *peripheral, NSUInteger idx, BOOL *stop) {
        BLEConnectionStatus status = [self connectionStatusForPeripheral:peripheral];
        if (status == BLEConnectionStatusDisconnected) {
            [self.centralManager connectPeripheral:peripheral options:nil];
        } else if (status == CBPeripheralStateConnected) {
            CBCharacteristic *characteristic = [self dataCharacteristicForPeripheral:peripheral];
            [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
        }
    }];
    return YES;
}

- (void) advertise {
    [self setupPeripheral];
}

- (void) scan {
    [self setupCentral];
}

- (instancetype) initWithDelegate:(id<BLETransportDelegate>)delegate {
    if (self = [super init]) {
        _delegate = delegate;
        _delegateQueue = dispatch_queue_create("BLETransportDelegate Queue", 0);
        _eventQueue = dispatch_queue_create("BLETransport Event Queue", 0);
        _allDiscoveredPeripherals = [NSMutableDictionary dictionary];
        _connectedPeripherals  = [NSMutableDictionary dictionary];
        _peripheralDataCharacteristics = [NSMutableDictionary dictionary];
        [self setupCharacteristics];
        [self setupServices];
    }
    return self;
}

#pragma mark CBCentralManagerDelegate

- (void) centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict {
    NSLog(@"centralManager:willRestoreState: %@", dict);
    NSArray *peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey];
    [peripherals enumerateObjectsUsingBlock:^(CBPeripheral *peripheral, NSUInteger idx, BOOL *stop) {
        [self.allDiscoveredPeripherals setObject:peripheral forKey:peripheral.identifier.UUIDString];
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
        [self.delegate transport:self identifierUpdated:peripheral.identifier.UUIDString connectionStatus:status extraInfo:@{@"RSSI": RSSI}];
    });
    if (!previouslySeenPeripheral) {
        [self.allDiscoveredPeripherals setObject:peripheral forKey:peripheral.identifier.UUIDString];
        peripheral.delegate = self;
        [central connectPeripheral:peripheral options:nil];
        dispatch_async(self.delegateQueue, ^{
            [self.delegate transport:self identifierUpdated:peripheral.identifier.UUIDString connectionStatus:BLEConnectionStatusConnecting extraInfo:nil];
        });
    }
}

- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"didConnectPeripheral: %@", peripheral);
    [peripheral discoverServices:nil];
    dispatch_async(self.delegateQueue, ^{
        [self.delegate transport:self identifierUpdated:peripheral.identifier.UUIDString connectionStatus:BLEConnectionStatusConnecting extraInfo:nil];
    });
}

- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    dispatch_async(self.delegateQueue, ^{
        [self.delegate transport:self identifierUpdated:peripheral.identifier.UUIDString connectionStatus:BLEConnectionStatusDisconnected extraInfo:nil];
    });
}

- (void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    dispatch_async(self.delegateQueue, ^{
        [self.delegate transport:self identifierUpdated:peripheral.identifier.UUIDString connectionStatus:BLEConnectionStatusDisconnected extraInfo:nil];
    });
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
    NSLog(@"peripheralManager:didSubscribeToCharacteristic: %@ %@", central, characteristic);
}

- (void) peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {
    NSLog(@"peripheralManager:didUnsubscribeFromCharacteristic: %@ %@", central, characteristic);
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {
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
        NSLog(@"write %@", data);
        NSString *identifier = request.central.identifier.UUIDString;
        dispatch_async(self.delegateQueue, ^{
            [self.delegate transport:self dataReceived:data fromIdentifier:identifier];
        });
        [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
    }];

}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {
    NSLog(@"didReceiveReadRequest: %@", request);
    [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
}

#pragma mark CBPeripheralDelegate

- (void) peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"didWriteValueForCharacteristic %@ %@", characteristic.value, error);

}

- (void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"didUpdateValueForCharacteristic %@ %@", characteristic.value, error);
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"didUpdateNotificationStateForCharacteristic %@ %@", characteristic, error);
    if ([characteristic.UUID isEqual:self.dataCharacteristic.UUID] && !error) {
        [self.connectedPeripherals setObject:peripheral forKey:peripheral.identifier.UUIDString];
        dispatch_async(self.delegateQueue, ^{
            [self.delegate transport:self identifierUpdated:peripheral.identifier.UUIDString connectionStatus:BLEConnectionStatusConnected extraInfo:nil];
        });
    }
}

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    NSLog(@"didDiscoverCharacteristicsForService: %@", service.characteristics);
    NSArray *characteristics = service.characteristics;
    NSUInteger characteristicIndex = [characteristics indexOfObjectPassingTest:^BOOL(CBCharacteristic *characteristic, NSUInteger idx, BOOL *stop) {
        if ([characteristic.UUID isEqual:self.dataCharacteristic.UUID]) {
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
    [self.peripheralDataCharacteristics setObject:characteristic forKey:peripheral.identifier.UUIDString];
    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
}

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    NSLog(@"didDiscoverServices: %@", peripheral.services);
    NSUInteger serviceIndex = [peripheral.services indexOfObjectPassingTest:^BOOL(CBService *service, NSUInteger idx, BOOL *stop) {
        if ([service.UUID isEqual:self.dataService.UUID]) {
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
    [peripheral discoverCharacteristics:@[self.dataCharacteristic.UUID] forService:service];
}

@end
