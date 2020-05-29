//
//  Banner.swift
//  wiseid
//
//  Created by Ana Luiza Boldrini  on 30/03/2020.
//  Copyright © 2020 GoOn. All rights reserved.
//

import UIKit

class Banner: NSObject, Codable{
    
    var id: String = ""
    var name: String = ""
    var fileName: String = ""
    var bannerURL: String = ""
    var devices = [String]()
    var stores = [String]()
    var ufs = [String]()
    var manufacturers = [String]()
    var regions = [String]()
    var images = [String]()
    var startDate:Date!
    var endDate:Date!
    var active: Bool = false
    var destinationUrls:URL!
    
    func Banner(merda: String){
        
    }
    
    func isValid()->Bool{
        let now:Date = Date()
        
        return self.startDate <= now && self.endDate >= now && self.active == true
    }
}
