//
//  BLETransport.m
//  Pods
//
//  Created by Christopher Ballinger on 2/20/15.
//
//

#import "BLETransport.h"
#import "BLETransportDataQueue.h"

@implementation BLETransport

- (instancetype) initWithServiceName:(NSString*)serviceName
                            delegate:(id<BLETransportDelegate>)delegate {
    if (self = [super init]) {
        _serviceName = serviceName;
        _delegate = delegate;
        _delegateQueue = dispatch_queue_create("BLETransport Delegate", 0);
    }
    return self;
}

- (BOOL) sendData:(NSData*)data
    toIdentifiers:(NSArray*)identifiers
         withMode:(BLETransportSendDataMode)mode
            error:(NSError**)error {
    NSAssert(NO, @"BLETransport is abstract, use concrete subclass");
    return NO;
}

- (void) scan {}
- (void) advertise {}
- (void) stop {}

@end
