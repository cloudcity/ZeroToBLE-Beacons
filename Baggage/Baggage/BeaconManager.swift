//
//  BeaconManager.swift
//  Baggage
//
//  Created by Evan Stone on 8/20/15.
//  Copyright © 2016 Cloud City. All rights reserved.
//

import UIKit
import CoreLocation

protocol BeaconManagerDelegate {
    func beaconManager(_ manager:BeaconManager, locationServicesAuthorized:Bool, status:CLAuthorizationStatus)
    func beaconManager(_ manager:BeaconManager, didFindClosestBeacon beacon: CLBeacon)
    func beaconManager(_ manager:BeaconManager, didFindBeacons beacons: Array<CLBeacon>, inRegion region:CLBeaconRegion)
}

class BeaconManager: NSObject, CLLocationManagerDelegate {
    
    let beaconRegionIdentifier = "io.cloudcity.BeaconRegion"

    let beaconUUID = "B9407F30-F5F8-466E-AFF9-25556B57FE6D"
    let beaconMajor = 61142
    let beaconMinor = 41244
    
    var delegate:BeaconManagerDelegate?
    var locationManager:CLLocationManager!
    var beaconRegion:CLBeaconRegion!
    var isRanging:Bool = false
    
    
    // MARK: - Step 1: Initialization
    
    func initializeLocationManager() {
        locationManager = CLLocationManager()
        
        // set the delegate property so we can respond to events
        locationManager.delegate = self
        
        // Create a CLBeaconRegion object with a proximity NSUUID and a String identifier
        beaconRegion = CLBeaconRegion(proximityUUID:UUID(uuidString: beaconUUID)!, identifier: beaconRegionIdentifier)
        
        isRanging = false
    }
    
    
    // MARK: - Step 2: Authorization
    
    func authorizeLocationServices() {
        let status = CLLocationManager.authorizationStatus()
        print("Current Location Services Authorization Status: \(status.rawValue)")
        
        if (status != CLAuthorizationStatus.authorizedWhenInUse) {
            // for this app, we'll use authorizedAlways so we can monitor in the background.
            /*
             Restrict authorization to use location services only when the app is in foreground.
             
             From Apple's docs:
                You must call the requestWhenInUseAuthorization method or the requestAlwaysAuthorization 
                method prior to using location services. If the user grants “when-in-use” authorization 
                to your app, your app can start most (but not all) location services while it is in the 
                foreground.

             NOTE: You must add the NSLocationWhenInUseUsageDescription (or NSLocationAlwaysUsageDescription)
                entry to Info.plist with a description of how the location services will be used.
                That entry sets the prompt in the Alert View that appears when user is asked to enable 
                location services (e.g. "Demonstrates beacon monitoring and ranging")
            */
            locationManager.requestWhenInUseAuthorization()
        } else {
            delegate?.beaconManager(self, locationServicesAuthorized: true, status:status)
        }
    }
    
    
    // MARK: - Scanning ("Ranging")
    
    func startRanging() {
        print("****** STARTING TO SCAN!!!")
        locationManager.startRangingBeacons(in: beaconRegion)
        isRanging = true
    }
    
    func stopRanging() {
        locationManager.stopRangingBeacons(in: beaconRegion)
        isRanging = false
    }
    
    
    // MARK: - CLLocationManagerDelegate methods
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("\(Date()) *** didChangeAuthorizationStatus to: \(status.rawValue)")
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            delegate?.beaconManager(self, locationServicesAuthorized: true, status:status)
        } else {
            delegate?.beaconManager(self, locationServicesAuthorized: false, status:status)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        
        // we found beacons (1 or more)
        delegate?.beaconManager(self, didFindBeacons: beacons, inRegion: region)
        
        // filter out any "unknown" beacons
        let knownBeacons = beacons.filter { $0.proximity != CLProximity.unknown }
        if (knownBeacons.count > 0) {
            let closestBeacon = knownBeacons[0] as CLBeacon
            delegate?.beaconManager(self, didFindClosestBeacon: closestBeacon)
        }
    }
    
}
