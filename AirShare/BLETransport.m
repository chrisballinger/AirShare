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
@property (nonatomic, strong, readonly) CBMutableCharacteristic *unreliableDataCharacteristic;
@property (nonatomic, strong, readonly) CBMutableCharacteristic *identityCharacteristic;
@property (nonatomic, readonly) dispatch_queue_t eventQueue;

@property (nonatomic, strong, readonly) NSMutableDictionary *identitiesToCentralCache;
@property (nonatomic, strong, readonly) NSMutableDictionary *identitiesToPeripheralCache;


@property (nonatomic, strong, readonly) NSMutableDictionary *peerToPeripheralCache;

@property (nonatomic, strong, readonly) NSMutableDictionary *allDiscoveredPeripherals;

@property (nonatomic, strong, readonly) NSMutableDictionary *characteristicsDictionary;
@end

@implementation BLETransport
@synthesize delegate = _delegate;
@synthesize localPeer = _localPeer;
@synthesize delegateQueue = _delegateQueue;

- (void) setupCharacteristics {
    _dataCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"72A7700C-859D-4317-9E35-D7F5A93005B1"] properties:CBCharacteristicPropertyRead | CBCharacteristicPropertyWrite | CBCharacteristicPropertyIndicate value:nil permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable];
    _identityCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"71E3140C-595C-4608-A324-7C494935E86C"] properties:CBCharacteristicPropertyRead | CBCharacteristicPropertyWrite | CBCharacteristicPropertyIndicate value:nil permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable];
    _unreliableDataCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"52360422-019C-4FE1-A9B7-616EC771D2C8"] properties:CBCharacteristicPropertyRead | CBCharacteristicPropertyWriteWithoutResponse | CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable];
}

- (void) setupServices {
    _dataService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:@"B491602C-C912-47AE-B639-9C17A4AADB06"] primary:YES];
    self.dataService.characteristics = @[self.dataCharacteristic, self.unreliableDataCharacteristic, self.identityCharacteristic];
}

- (void) setupPeripheral {
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self
                                                                 queue:_eventQueue
                                                               options:@{CBPeripheralManagerOptionRestoreIdentifierKey: kBLEBroadcasterRestoreIdentifier,
                                                                         CBPeripheralManagerOptionShowPowerAlertKey: @YES}];
    [self.peripheralManager addService:self.dataService];

}

- (void) setupCentral {
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                           queue:_eventQueue
                                                         options:@{CBCentralManagerOptionRestoreIdentifierKey: kBLEScannerRestoreIdentifier}];
    _allDiscoveredPeripherals = [NSMutableDictionary dictionary];
}

- (void) scanForPeripherals {
    if (self.centralManager.state == CBCentralManagerStatePoweredOn) {
        BOOL allowDuplicates = YES;
        NSArray *services = @[self.dataService.UUID];
        [self.centralManager scanForPeripheralsWithServices:services
                                                    options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @(allowDuplicates)}];
    } else {
        NSLog(@"central not powered on");
    }
}

- (void) broadcastPeripheral {
    if (self.peripheralManager.state == CBPeripheralManagerStatePoweredOn) {
        if (!self.peripheralManager.isAdvertising) {
            [self.peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey: @[self.dataService.UUID],
                                                       CBAdvertisementDataLocalNameKey: @"AirShare"}];
        }
    } else {
        NSLog(@"peripheral not powered on");
    }
}

#pragma mark BLETransport

- (void) sendData:(NSData*)data
          toPeers:(NSArray*)peers {
    
}

- (void) advertiseLocalPeer {
    [self setupPeripheral];
}

- (void) scanForPeers {
    [self setupCentral];
}

- (instancetype) initWithLocalPeer:(BLEPeer*)localPeer
                          delegate:(id<BLETransportDelegate>)delegate {
    if (self = [super init]) {
        _localPeer = localPeer;
        _delegate = delegate;
        _delegateQueue = dispatch_queue_create("BLETransportDelegate Queue", 0);
        _eventQueue = dispatch_queue_create("BLETransport Event Queue", 0);
        [self setupCharacteristics];
        [self setupServices];
    }
    return self;
}

#pragma mark CBCentralManagerDelegate

- (void) centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict {
    NSLog(@"centralManager:willRestoreState: %@", dict);
    NSArray *peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey];
}

- (void) centralManagerDidUpdateState:(CBCentralManager *)centralManager {
    NSLog(@"centralManagerDidUpdateState: %@", centralManager);
    [self scanForPeripherals];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    NSLog(@"didDiscoverPeripheral: %@ %@ %@", peripheral, advertisementData, RSSI);
    CBPeripheral *previouslySeenPeripheral = [self.allDiscoveredPeripherals objectForKey:peripheral.identifier.UUIDString];
    if (!previouslySeenPeripheral) {
        [self.allDiscoveredPeripherals setObject:peripheral forKey:peripheral.identifier.UUIDString];
        peripheral.delegate = self;
        [central connectPeripheral:peripheral options:nil];
    }
}

- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [peripheral discoverServices:@[self.dataService.UUID]];
}

- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
}

- (void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
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
    NSLog(@"peripheralManager:didSubscribeToCharacteristic");
}

- (void) peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {
    NSLog(@"peripheralManager:didUnsubscribeFromCharacteristic");
}

#pragma mark CBPeripheralDelegate

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    NSLog(@"didDiscoverCharacteristicsForService");
    NSArray *characteristics = service.characteristics;
}

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    NSLog(@"didDiscoverServices");
    [peripheral.services enumerateObjectsUsingBlock:^(CBService *service, NSUInteger idx, BOOL *stop) {
        [peripheral discoverCharacteristics:@[self.dataCharacteristic.UUID, self.unreliableDataCharacteristic.UUID, self.identityCharacteristic.UUID] forService:service];
    }];
}

@end
