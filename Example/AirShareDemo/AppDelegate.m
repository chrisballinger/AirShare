//
//  AppDelegate.m
//  IOCipherServer
//
//  Created by Christopher Ballinger on 1/22/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "AppDelegate.h"
#import "BLECrypto.h"
#import "BLEPeerBrowserViewController.h"

static NSString * const kCachedLocalPeerKey = @"kCachedLocalPeerKey";


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    NSData *localPeerData = [[NSUserDefaults standardUserDefaults] objectForKey:kCachedLocalPeerKey];
    BLELocalPeer *localPeer = nil;
    if (!localPeerData) {
        BLEKeyPair *keyPair = [BLEKeyPair keyPairWithType:BLEKeyTypeEd25519];
        localPeer = [[BLELocalPeer alloc] initWithPublicKey:keyPair.publicKey privateKey:keyPair.privateKey];
        NSData *peerData = [NSKeyedArchiver archivedDataWithRootObject:localPeer];
        [[NSUserDefaults standardUserDefaults] setObject:peerData forKey:kCachedLocalPeerKey];
    } else {
        localPeer = [NSKeyedUnarchiver unarchiveObjectWithData:localPeerData];
        NSParameterAssert(localPeer != nil);
    }
    self.sessionManager = [[BLESessionManager alloc] initWithLocalPeer:localPeer delegate:nil];
    [self.sessionManager advertiseLocalPeer];
    [self.sessionManager scanForPeers];
    
    UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
    [application registerUserNotificationSettings:notificationSettings];
    
    BLEPeerBrowserViewController *peerBrowser = [[BLEPeerBrowserViewController alloc] initWithSessionManager:self.sessionManager];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:peerBrowser];
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = nav;
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
