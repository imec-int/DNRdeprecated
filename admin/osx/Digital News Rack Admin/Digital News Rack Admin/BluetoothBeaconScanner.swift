//
//  RelayManager.swift
//  Relay
//
//  Created by Sam Decrock on 22/04/16.
//  Copyright © 2016 Sam. All rights reserved.
//

import Foundation
import CoreBluetooth
import EmitterKit


extension NSData {
    func toHexString() -> String {
        
        let string = NSMutableString(capacity: length * 2)
        var byte: UInt8 = 0
        
        for i in 0 ..< length {
            getBytes(&byte, range: NSMakeRange(i, 1))
            string.appendFormat("%02x", byte)
        }
        
        return string as String
    }
}

struct Beacon {
    var uuid: NSUUID
    var major: UInt16
    var minor: UInt16
    var power: Int8
    var bluetoothName: String?
}


class BluetoothBeaconScanner: NSObject, CBCentralManagerDelegate {

    var centralManager:CBCentralManager!
    
    let onBeaconFound = Event<Beacon>()
    
    func startScanning() {
        print("Initializing CBCentralManager")
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    internal func centralManagerDidUpdateState(central: CBCentralManager) {
        print("Checking BLE state")
        switch (central.state) {
        case .PoweredOff:
            print("CoreBluetooth BLE hardware is powered off")
            
        case .PoweredOn:
            print("CoreBluetooth BLE hardware is powered on and ready")
            centralManager.scanForPeripheralsWithServices(nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey : false])
            
        case .Resetting:
            print("CoreBluetooth BLE hardware is resetting")
            
        case .Unauthorized:
            print("CoreBluetooth BLE state is unauthorized")
            
        case .Unknown:
            print("CoreBluetooth BLE state is unknown")
            
        case .Unsupported:
            print("CoreBluetooth BLE hardware is unsupported on this platform")
        }
    }

    func stopScanning(){
        print("Stop scanning")
        centralManager.stopScan()
    }
    
    internal func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        let beacon = getBeaconData(peripheral, advertisementData: advertisementData)
        if beacon != nil {
            self.onBeaconFound.emit(beacon!)
        }
    }
    
    internal func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {

    }
    
    internal func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {

    }
  
    private func getBeaconData(peripheral: CBPeripheral, advertisementData: [NSObject : AnyObject]) -> Beacon? {
        if advertisementData.count == 0 { return nil }
        
        let dic: NSDictionary = advertisementData
        if let data: NSData = dic.objectForKey(CBAdvertisementDataManufacturerDataKey) as? NSData{ // kCBAdvDataManufacturerData

            if data.length != 25 { return nil }
            
            
            var companyIdentifier: UInt16 = 0
            var dataType: Int8 = 0
            var dataLength: Int8 = 0
            
            var uuidBytes = [UInt8](count: 16, repeatedValue: 0)
            var majorPointer: UInt16 = 0
            var minorPointer: UInt16 = 0
            var measuredPowerPointer: Int8 = 0
            
            let companyIDRange = NSMakeRange(0, 2)
            data.getBytes(&companyIdentifier, range: companyIDRange)
            if companyIdentifier != 0x4C { return nil }
            
            let dataTypeRange = NSMakeRange(2,1)
            data.getBytes(&dataType, range: dataTypeRange)
            if dataType != 0x02 { return nil }
            
            let dataLengthRange = NSMakeRange(3,1)
            data.getBytes(&dataLength, range: dataLengthRange)
            if dataLength != 0x15 { return nil }
            
            
            let uuidRange = NSMakeRange(4, 16)
            let majorRange = NSMakeRange(20, 2)
            let minorRange = NSMakeRange(22, 2)
            let powerRange = NSMakeRange(24, 1)
            
            data.getBytes(&uuidBytes, range: uuidRange)
            let proximityUUID: NSUUID = NSUUID(UUIDBytes: uuidBytes)
            
            data.getBytes(&majorPointer, range: majorRange)
            let major: UInt16 = (majorPointer >> 8) | (majorPointer << 8)
            
            data.getBytes(&minorPointer, range: minorRange)
            let minor: UInt16 = (minorPointer >> 8) | (minorPointer << 8)
            
            data.getBytes(&measuredPowerPointer, range: powerRange)
            let measuredPower: Int8 = measuredPowerPointer
            
            
            let beacon = Beacon(uuid: proximityUUID, major: major, minor: minor, power: measuredPower, bluetoothName: peripheral.name)
            return beacon
            
        }
        
        
        return nil
    }
}