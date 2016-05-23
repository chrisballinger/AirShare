# [AirShare](https://github.com/chrisballinger/AirShare)

A library designed to ease P2P communication between iOS and Android devices. Use AirShare to build software that doesn't require the Internet to discover and interact with peers, or to create unique networks based on the geographical connections of their users.

Also see the [Android library](https://github.com/OnlyInAmerica/AirShare-Android).

**Under Development : APIs subject to change**

## Motivation

To abstract away the particulars of connection negotiation with clients over radio technologies like BLE and WiFi.
P2P networking should be as simple as:

1. Express an identity for your local device's user and to the service this user belongs to
1. Express an intent to discover peers on remote devices, or make your local user discoverable
1. (Optional) When a remote peer is discovered, query available transports and upgrade transport if desired.
1. Exchange arbitrary data with discovered peers over a plain serial interface

## Requirements

+ iOS 5 SDK *or greater*.
+ Compatible devices: iPhone 4s *or newer*, iPad 3rd gen *or newer*, iPad mini, iPad Pro, iPod touch 5th gen *or newer*.

## Example Apps

+ The [example](https://github.com/chrisballinger/AirShare/tree/master/Example) module of this repository illustrates simple synchronous sharing of structured data.
+ [BLEMeshChat](https://github.com/chrisballinger/BLEMeshChat) is a more advanced example featuring background operation and store-and-forward messaging.
+
## Installation  

This library is currently under developmemt. CocoaPods is probably the simplist way to bundle it as a framework for inclusion in a project and install it's dependancies. Simply clone the project, add a local reference to it in your `Podfile`:

```
pod 'AirShare/UIKit', :path => "./AirShare"
[...]
use_frameworks!
```

Run `pod install`, and you should be ready to go.

```swift
import AirShare
[...]
```

## Usage

### Basic Usage -- BLESessionManager

`BLESessionManager` manages peer scanning and advertising, and provides delegatable methods to respond to peers being connected and receiving data. It also exposes the set of `discoveredPeers` (`[BLERemotePeer]`) and a method to send a `BLESessionMessage` to a peer.


```swift
class MyAirShareManager : NSObject, BLESessionManagerDelegate  {

  private var sessionManager : BLESessionManager?;

  override init(){

    super.init()

    let keyPair = BLEKeyPair(type: .Ed25519)
    let me = BLELocalPeer(publicKey: keyPair.publicKey, privateKey: keyPair.privateKey)

    me.alias = "Alice"

    sessionManager = BLESessionManager(localPeer: me, delegate: self)

    sessionManager!.advertiseLocalPeer()
    sessionManager!.scanForPeers()

  }


  @objc func sessionManager(sessionManager: BLESessionManager!, peer: BLERemotePeer!, statusUpdated status: BLEConnectionStatus, peerIsHost: Bool) {

        switch status {
        case .Connected:  print("\(peer.alias) connected."); break
        case .Connecting: print("\(peer.alias) is connecting."); break
        case .Disconnected:  print("\(peer.alias) disconnected."); break
        }

    }

  @objc func sessionManager(sessionManager: BLESessionManager!, receivedMessage message: BLESessionMessage!, fromPeer peer: BLERemotePeer!) {

    print("Received \(message.type) message")

    // Is data BLEDataMessage
    if message.type != "datatransfer" {
        return;
    }

    // Upcast to concrete BLEDataMessage.
    let message = message as! BLEDataMessage

    let fromBytes = String(data: message.data, encoding: NSUTF8StringEncoding)!

    if let data = fromBytes.dataUsingEncoding(NSUTF8StringEncoding) {
      print("\(peer.alias) sent: \(data).")
    }
  }
}
```

## License

    Chris Ballinger

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
