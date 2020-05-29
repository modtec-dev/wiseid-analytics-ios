//
//  Campaign.swift
//  wiseid
//
//  Created by Digital Owns  on 18/02/2020.
//  Copyright © 2020 GoOn. All rights reserved.
//

import UIKit

class Campaign: NSObject, Codable{
    
    var id : String = ""
    var active : Bool = false
    var devices = [String]()
    var manufacturer = [String]()
    var name:String = ""
    var region = [String]()
    var stores = [String]()
    var uf = [String]()
    var videos = [String]()
    var destinationUrls = [URL]()
    var startDate:Date!
    var endDate:Date!
    
    
    func Campaign(){
        
    }
    
    func isValid()->Bool{
        let now:Date = Date()
        
        return self.startDate <= now && self.endDate >= now && self.active == true
 
    }
}
