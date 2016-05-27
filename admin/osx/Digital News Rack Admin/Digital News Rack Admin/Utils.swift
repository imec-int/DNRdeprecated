//
//  Utils.swift
//
//  Created by Sam Decrock on 29/04/16.
//  Copyright © 2016 Sam. All rights reserved.
//

import Foundation

func setTimeout(delay: Double, complete: () -> Void) {
    let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_MSEC)))
    dispatch_after(delayTime, dispatch_get_main_queue()) {
        complete()
    }
}

class JSON {
    class func stringify(jsonObject: [String: AnyObject]) -> String {
        let jsonData = try? NSJSONSerialization.dataWithJSONObject(jsonObject, options: NSJSONWritingOptions())
        let jsonString = NSString(data: jsonData!, encoding: NSUTF8StringEncoding) as! String
        return jsonString
    }
    
    class func stringify(jsonArray: [AnyObject]) -> String {
        let jsonData = try? NSJSONSerialization.dataWithJSONObject(jsonArray, options: NSJSONWritingOptions())
        let jsonString = NSString(data: jsonData!, encoding: NSUTF8StringEncoding) as! String
        return jsonString
    }
    
    
    class func parse(text: String) -> NSDictionary {
        let nsdata = text.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        let data = (try! NSJSONSerialization.JSONObjectWithData(nsdata!, options: [])) as! NSDictionary
        return data
    }
    
    class func parseAsArray(text: String) -> [NSDictionary] {
        let nsdata = text.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        let data = (try! NSJSONSerialization.JSONObjectWithData(nsdata!, options: [])) as! [NSDictionary]
        return data
    }
    
    class func parse(nsdata: NSData) -> NSDictionary {
        let data = (try! NSJSONSerialization.JSONObjectWithData(nsdata, options: [])) as! NSDictionary
        return data
    }
}