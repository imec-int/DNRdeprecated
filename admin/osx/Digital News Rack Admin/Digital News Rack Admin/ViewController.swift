//
//  ViewController.swift
//  Digital News Rack Admin
//
//  Created by Sam Decrock on 13/05/16.
//  Copyright © 2016 KrookLab. All rights reserved.
//

import Cocoa
import EmitterKit

class ViewController: NSViewController {
    
    private var listeners = [Listener]()
    
    let beaconScanner = BluetoothBeaconScanner()
    let websocketServer = WebsocketServer()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        websocketServer.onSocketConnected.on { (socket) -> Void in
            print("webinterface connected!")
        }
        
        websocketServer.onSocketMessage.on { (message) -> Void in
            print("socket message:", message)
        }
        
        
        
        listeners += beaconScanner.onBeaconFound.on { (beacon) -> Void in
            print("beacon found:", beacon)
            
            self.websocketServer.sendObject([
                "uuid": beacon.uuid.UUIDString,
                "major": NSNumber(unsignedShort: beacon.major),
                "minor": NSNumber(unsignedShort: beacon.minor),
                "bluetoothName": beacon.bluetoothName != nil ? beacon.bluetoothName! : ""
            ])
        }
        
        beaconScanner.startScanning()
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

