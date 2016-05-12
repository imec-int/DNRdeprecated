//
//  ViewController.swift
//  Digital News Rack
//
//  Created by Sam Decrock on 11/05/16.
//  Copyright © 2016 KrookLab. All rights reserved.
//

import UIKit
import CoreLocation
import WebKit

class ViewController: UIViewController, WKNavigationDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var labelStatus: UILabel!
    @IBOutlet weak var viewBrowserPlaceholder: UIView!
    
    let locationManager = CLLocationManager()
    var newsracks: [NewsRack] = []
    var webView = WKWebView()
    
    @IBOutlet weak var labelProximity: UILabel!
    
    var currentNewsrack: NewsRack?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        
    
        // Webview stuff:
        let webViewConfiguration: WKWebViewConfiguration = WKWebViewConfiguration()
        webViewConfiguration.allowsInlineMediaPlayback = true
        webViewConfiguration.mediaPlaybackRequiresUserAction = false
        webView = WKWebView(frame: self.viewBrowserPlaceholder.bounds, configuration: webViewConfiguration)
        webView.navigationDelegate = self
        viewBrowserPlaceholder.addSubview(webView)
        webView.allowsBackForwardNavigationGestures = true
        webView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        
        // Create some news racks:
        newsracks.append(NewsRack(name: "Dokter De Geyter", accessToName: "De Morgen", accessToUrl: "http://www.demorgen.be", uuid: NSUUID(UUIDString: "D0D3FA86-CA76-45EC-9BD9-6AF41F47666B")!, majorValue: 36206, minorValue: 59382))
        
        
        newsracks.append(NewsRack(name: "Dokter Decrock", accessToName: "De Morgen", accessToUrl: "http://www.demorgen.be", uuid: NSUUID(UUIDString: "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0")!, majorValue: 1234, minorValue: 5678))
        
        
        newsracks.append(NewsRack(name: "Dokter Wauters", accessToName: "Het Laatste Nieuws", accessToUrl: "http://www.hln.be", uuid: NSUUID(UUIDString: "b28122f2-182a-11e6-b6ba-3e1d05defe78")!, majorValue: 4321, minorValue: 5678))

        
        
        
        // Start checking for news racks:
        for newsrack in newsracks {
            startMonitoringNewsrack(newsrack)
        }
    }
    
    func beaconRegionWithNewsrack(newsrack: NewsRack) -> CLBeaconRegion {
        let beaconRegion = CLBeaconRegion(proximityUUID: newsrack.uuid,
            major: newsrack.majorValue,
            minor: newsrack.minorValue,
            identifier: newsrack.name)
        
        newsrack.beaconRegion = beaconRegion
        
        return beaconRegion
    }
    
    func startMonitoringNewsrack(newsracks: NewsRack) {
        let beaconRegion = beaconRegionWithNewsrack(newsracks)
        locationManager.startMonitoringForRegion(beaconRegion)    // 2 manieren om te checken of een beacon in de buurt is
        locationManager.startRangingBeaconsInRegion(beaconRegion) // via range: is redelijk snel, via monitoring van region: duurt soms een minuut voor hij door heeft dat je de region verlaten hebt. Beide methodes zijn geïmplenteerd.
    }
    
    func stopMonitoringNewsrack(newsracks: NewsRack) {
        let beaconRegion = beaconRegionWithNewsrack(newsracks)
        locationManager.stopMonitoringForRegion(beaconRegion)
        locationManager.stopRangingBeaconsInRegion(beaconRegion)
    }
    
    func activateNewsrack(newsrack: NewsRack) {
        if newsrack === currentNewsrack { return }

        
        let alert = UIAlertController(title: "Welkom bij \(newsrack.name)", message: "U krijgt nu toegang tot \(newsrack.accessToName)", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
        
        
        self.labelStatus.text = "Welkom bij \(newsrack.name), u krijgt nu toegang tot \(newsrack.accessToName)"
        webView.loadRequest(NSURLRequest(URL: NSURL(string: newsrack.accessToUrl)!))
        
        currentNewsrack = newsrack
    }
    
    func deactivateNewsrack(newsrack: NewsRack) {
        if currentNewsrack !== newsrack { return }
        
        currentNewsrack = nil
        webView.loadHTMLString("", baseURL: nil)
        self.labelStatus.text = "Wij kijken uit naar uw volgend bezoek!"
        
        
        
        let alert = UIAlertController(title: "U verlaat \(newsrack.name)", message: "Bedankt en tot ziens!", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
        print("Failed monitoring region: \(error.description)")
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Location manager failed: \(error.description)")
    }
    
    func locationManager(manager: CLLocationManager, didStartMonitoringForRegion region: CLRegion) {
        print("started monitoring region", region)
        locationManager.requestStateForRegion(region)
    }
    

    
    func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        
        func newsRackNotClose(newsrack: NewsRack) {
            newsrack.lastSeenCounter--
            print(newsrack.lastSeenCounter)
            if newsrack.lastSeenCounter == 0 {
                newsrack.resetLastSeenCounter()
                print("deactivating newsrack by leaving range", newsrack.name)
                deactivateNewsrack(newsrack)
            }
        }
        
        
        for newsrack in newsracks {
            let matchingBeacons = beacons.filter({ (beacon) -> Bool in
                return newsrack.matchesBeacon(beacon)
            })
            
            
            
            if let matchingBeacon = matchingBeacons.first {
                
                // debug distance on screen:
                switch matchingBeacon.proximity {
                case CLProximity.Unknown:
                    self.labelProximity.text = "Unknown"
                case CLProximity.Immediate:
                    self.labelProximity.text = "Immediate"
                case CLProximity.Near:
                    self.labelProximity.text = "Near"
                case CLProximity.Far:
                    self.labelProximity.text = "Far"
                    
                }
                
                if matchingBeacon.proximity == CLProximity.Immediate || matchingBeacon.proximity == CLProximity.Near {
                    newsrack.lastSeenBeacon = matchingBeacon
                    print("activating newsrack by entering range", newsrack.name, matchingBeacon.accuracy)
                    newsrack.resetLastSeenCounter()
                    activateNewsrack(newsrack)
                }else{
                    newsRackNotClose(newsrack)
                }
            }else{
                newsRackNotClose(newsrack)
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        let n = newsracks.filter { (newsrack) -> Bool in
            return newsrack.beaconRegion == region
        }
        if let newsrack = n.first {
            print("activating newsrack by entering region")
            activateNewsrack(newsrack)
        }
    }
    
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        let n = newsracks.filter { (newsrack) -> Bool in
            return newsrack.beaconRegion == region
        }
        if let newsrack = n.first {
            print("deactivating newsrack by leaving region")
            deactivateNewsrack(newsrack)
        }
    }
}

