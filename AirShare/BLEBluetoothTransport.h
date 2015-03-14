//
//  BLEBluetoothTransport.h
//  Pods
//
//  Created by Christopher Ballinger on 3/4/15.
//
//

#import <Foundation/Foundation.h>
#import "BLETransport.h"
#import "BLEBluetoothDevice.h"

@class BLEBluetoothTransport;
@class BLECentral;
@class BLEPeripheral;


@interface BLEBluetoothTransport : BLETransport <BLEBluetoothDeviceDelegate>

@property (nonatomic, strong) BLECentral *central;
@property (nonatomic, strong) BLEPeripheral *peripheral;
@property (nonatomic) BOOL supportsBackground;

- (instancetype) initWithServiceName:(NSString*)serviceName
                            delegate:(id<BLETransportDelegate>)delegate
                  supportsBackground:(BOOL)supportsBackground;

@end
