//
//  Tag.swift
//  wiseid
//
//  Created by Digital Owns  on 16/02/2020.
//  Copyright © 2020 GoOn. All rights reserved.
//

import UIKit

struct Tag: Codable {

    var id: String!
    var header: TagHeader = TagHeader()
    var device: TagDevice = TagDevice()
    var prices = [TagPrice]()
    var gadgets = [TagGadget]()
    var bannerUrl:String!
    
}
