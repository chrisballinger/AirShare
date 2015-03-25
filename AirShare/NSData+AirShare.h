//
//  NSData+AirShare.h
//  Pods
//
//  Created by Christopher Ballinger on 3/18/15.
//
//

#import <Foundation/Foundation.h>

@interface NSData (AirShare)

- (NSData*) ble_sha256;
- (NSString*) ble_hexString;

@end
