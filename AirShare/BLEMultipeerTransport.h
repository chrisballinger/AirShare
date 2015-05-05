//
//  BLEMultipeerTransport.h
//  Pods
//
//  Created by David Brodsky on 5/5/15.
//
//

#import <Foundation/Foundation.h>
#import "BLETransport.h"

@class BLEMultipeerTransport;

@interface BLEMultipeerTransport : BLETransport

@property (nonatomic) BOOL supportsBackground;

- (instancetype) initWithServiceName:(NSString*)serviceName
                            delegate:(id<BLETransportDelegate>)delegate
                  supportsBackground:(BOOL)supportsBackground;

@end
