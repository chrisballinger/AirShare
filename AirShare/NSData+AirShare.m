//
//  NSData+AirShare.m
//  Pods
//
//  Created by Christopher Ballinger on 3/18/15.
//
//

#import "NSData+AirShare.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation NSData (AirShare)

- (NSData*) ble_sha256 {
    uint8_t *hashBytes = malloc(CC_SHA256_DIGEST_LENGTH * sizeof(uint8_t));
    if (!hashBytes) {
        return nil;
    }
    CC_SHA256([self bytes], (CC_LONG)[self length], hashBytes);
    NSData *sha256 = [NSData dataWithBytesNoCopy:hashBytes length:CC_SHA256_DIGEST_LENGTH freeWhenDone:YES];
    return sha256;
}

- (NSString *)ble_hexString
{
    NSMutableString *stringBuffer = [NSMutableString stringWithCapacity:([self length] * 2)];
    
    const unsigned char *dataBuffer = [self bytes];
    int i;
    
    for (i = 0; i < [self length]; ++i)
    {
        [stringBuffer appendFormat:@"%02x", (unsigned int)dataBuffer[i]];
    }
    
    return [stringBuffer copy];
}

@end
