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
        newsracks.append(NewsRack(name: "Dokter Decrock", accessToName: "De Morgen", accessToUrl: "http://www.demorgen.be", uuid: NSUUID(UUIDString: "D0D3FA86-CA76-45EC-9BD9-6AF41F47666B")!, majorValue: 36206, minorValue: 59382))
        
        
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

        
        self.labelStatus.text = "Welkom bij \(newsrack.name), u krijgt nu toegang tot \(newsrack.accessToName)"
        webView.loadRequest(NSURLRequest(URL: NSURL(string: newsrack.accessToUrl)!))
        
        currentNewsrack = newsrack
    }
    
    func deactivateNewsrack(newsrack: NewsRack) {
        if currentNewsrack == nil { return }
        
        currentNewsrack = nil
        webView.loadHTMLString("", baseURL: nil)
        self.labelStatus.text = "Wij kijken uit naar uw volgend bezoek!"
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
        for newsrack in newsracks {
            let matchingBeacons = beacons.filter({ (beacon) -> Bool in
                return newsrack.matchesBeacon(beacon)
            })
            
            if let matchingBeacon = matchingBeacons.first {
                newsrack.lastSeenBeacon = matchingBeacon
                print("activating newsrack by entering range", matchingBeacon.accuracy)
                newsrack.resetLastSeenCounter()
                activateNewsrack(newsrack)
            }else{
                newsrack.lastSeenCounter--
                print(newsrack.lastSeenCounter)
                if newsrack.lastSeenCounter == 0 {
                    newsrack.resetLastSeenCounter()
                    print("deactivating newsrack by leaving range")
                    deactivateNewsrack(newsrack)
                }
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

