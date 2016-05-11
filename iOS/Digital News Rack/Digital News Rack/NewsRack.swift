//
//  Beacon.swift
//  Digital News Rack
//
//  Created by Sam Decrock on 11/05/16.
//  Copyright © 2016 KrookLab. All rights reserved.
//

import Foundation
import CoreLocation

class NewsRack {
    let name: String
    let accessToName: String
    let accessToUrl: String
    
    
    let uuid: NSUUID
    
    let majorValue: CLBeaconMajorValue
    let minorValue: CLBeaconMinorValue
    
    var lastSeenBeacon: CLBeacon?
    var beaconRegion: CLRegion?
    var lastSeenCounter = 3
    
    init(name: String, accessToName: String, accessToUrl: String, uuid: NSUUID, majorValue: CLBeaconMajorValue, minorValue: CLBeaconMinorValue) {
        
        self.name = name
        self.accessToName = accessToName
        self.accessToUrl = accessToUrl
        
        self.uuid = uuid
        self.majorValue = majorValue
        self.minorValue = minorValue
    }
    
    func resetLastSeenCounter() {
        lastSeenCounter = 3
    }
    
    func matchesBeacon(clBeacon: CLBeacon) -> Bool {
        return ((clBeacon.proximityUUID.UUIDString == self.uuid.UUIDString)
            && (Int(clBeacon.major) == Int(self.majorValue))
            && (Int(clBeacon.minor) == Int(self.minorValue)))
    }
}

func ==(newsrack: NewsRack, clBeacon: CLBeacon) -> Bool {
    return ((clBeacon.proximityUUID.UUIDString == newsrack.uuid.UUIDString)
        && (Int(clBeacon.major) == Int(newsrack.majorValue))
        && (Int(clBeacon.minor) == Int(newsrack.minorValue)))
}
