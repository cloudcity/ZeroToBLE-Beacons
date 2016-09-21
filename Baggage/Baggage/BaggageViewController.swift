//
//  BaggageViewController.swift
//  Baggage
//
//  Created by Evan Stone on 9/19/16.
//  Copyright © 2016 Cloud City. All rights reserved.
//

import UIKit
import CoreLocation

class BaggageViewController: UIViewController, BeaconManagerDelegate {
    
    @IBOutlet weak var suitcaseImage: UIImageView!
    @IBOutlet weak var proximityLabel: UILabel!
    
    @IBOutlet weak var suitcaseTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var suitcaseWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var suitcaseHeightConstraint: NSLayoutConstraint!
    
    let suitcaseSizeSmall = CGSize(width: 58, height: 65)
    let suitcaseSizeMedium = CGSize(width: 116, height: 130)
    let suitcaseSizeLarge = CGSize(width: 174, height: 195)
    
    let suitcaseTopFar:CGFloat = 20.0
    var suitcaseTopNear:CGFloat!
    var suitcaseTopImmediate:CGFloat!
    
    let verticalCorrection:CGFloat = 64.0
    let velocity = 0.5
    
    var beaconManager:BeaconManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        proximityLabel.text = ""
        suitcaseImage.isHidden = true
        suitcaseWidthConstraint.constant = suitcaseSizeSmall.width
        suitcaseHeightConstraint.constant = suitcaseSizeSmall.height
        suitcaseTopConstraint.constant = suitcaseTopFar
        
        suitcaseTopNear = (view.frame.height / 3.0) - verticalCorrection
        suitcaseTopImmediate = (view.frame.height / 2.0) - verticalCorrection
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        beaconManager = BeaconManager()
        beaconManager.delegate = self
        beaconManager.initializeLocationManager()
        beaconManager.authorizeLocationServices()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    
    // MARK: - BeaconManagerDelegate methods
    
    internal func beaconManager(_ manager: BeaconManager, locationServicesAuthorized: Bool, status:CLAuthorizationStatus) {
        let auth = locationServicesAuthorized ? "YES" : "NO"
        print("*** beaconManager:locationServicesAuthorized: \(auth)")
        
        if locationServicesAuthorized {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.3 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
                self.beaconManager.startRanging()
            }
        } else {
            if status == CLAuthorizationStatus.denied {
                print("****** SHOWING SCANNING DISABLED ALERT!!!")
                let dispatchTime: DispatchTime = DispatchTime.now() + Double(Int64(0.3 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: { () -> Void in
                    let alertController = UIAlertController(
                        title: "Scanning Disabled",
                        message: "To enable scanning of items in the kit, you will need to enable Location Services in your iPad's iOS Settings:\n\n" +
                            "Settings -> Privacy -> Location Services -> Baggage\n\n" +
                        "Switch the \"ALLOW LOCATION ACCESS\" to \"While Using the App.\"",
                        preferredStyle: UIAlertControllerStyle.alert)
                    
                    let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) -> Void in
                        //
                    })
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true, completion: { () -> Void in
                        //
                    })
                })
            }
        }
    }
    
    internal func beaconManager(_ manager: BeaconManager, didFindBeacons beacons: Array<CLBeacon>, inRegion region: CLBeaconRegion) {
        print("*** BEACONS FOUND: \(beacons)")
    }
    
    internal func beaconManager(_ manager: BeaconManager, didFindClosestBeacon beacon: CLBeacon) {
        
        print("*** CLOSEST BEACON: \(beacon)")
        
        if (beacon.major.intValue != beaconManager.beaconMajor) || (beacon.minor.intValue != beaconManager.beaconMinor) {
            proximityLabel.text = ""
            suitcaseImage.isHidden = true
            return
        }
        
        // if beacon proximity is unknown then fade it out/hide it
        if beacon.proximity == CLProximity.unknown {
            
            proximityLabel.text = "Unknown"
            self.view.layoutIfNeeded()
            UIView.animate(withDuration: 0.2,
                animations: {
                    self.suitcaseImage.alpha = 0.0
                    self.view.layoutIfNeeded()
                },
                completion: { (finished) in
                        self.suitcaseImage.isHidden = true
                })
            
            return
        }
        
        // if the image is currently hidden we're going to fade it in, so let's prepare it here...
        var fadeIn = false
        if suitcaseImage.isHidden {
            fadeIn = true
            suitcaseImage.alpha = 0
            suitcaseImage.isHidden = false
        }
        
        self.view.layoutIfNeeded()
        UIView.animate(
            withDuration: velocity,
            animations: {
                if fadeIn {
                    self.suitcaseImage.alpha = 1.0
                }
                
                switch beacon.proximity {
                case CLProximity.far:
                    self.suitcaseImage.isHidden = false
                    self.proximityLabel.text = "Far"
                    self.suitcaseWidthConstraint.constant = self.suitcaseSizeSmall.width
                    self.suitcaseHeightConstraint.constant = self.suitcaseSizeSmall.height
                    self.suitcaseTopConstraint.constant = self.suitcaseTopFar
                case CLProximity.near:
                    self.suitcaseImage.isHidden = false
                    self.proximityLabel.text = "Near"
                    self.suitcaseWidthConstraint.constant = self.suitcaseSizeMedium.width
                    self.suitcaseHeightConstraint.constant = self.suitcaseSizeMedium.height
                    self.suitcaseTopConstraint.constant = self.suitcaseTopNear
                case CLProximity.immediate:
                    self.suitcaseImage.isHidden = false
                    self.proximityLabel.text = "Immediate"
                    self.suitcaseWidthConstraint.constant = self.suitcaseSizeLarge.width
                    self.suitcaseHeightConstraint.constant = self.suitcaseSizeLarge.height
                    self.suitcaseTopConstraint.constant = self.suitcaseTopImmediate
                case CLProximity.unknown:
                    print("unknown proximity...")
                    return
                }
                
                print("view height: \(self.view.frame.height)")
                print("image height: \(self.suitcaseImage.frame.height)")
                print("top constraint: \(self.suitcaseTopConstraint.constant)")
                
                self.view.layoutIfNeeded()
            }
//            ,
//            completion: { (finished) in
//                self.suitcaseImage.isHidden = true
//            }
        )

        
    }
    
    
}
