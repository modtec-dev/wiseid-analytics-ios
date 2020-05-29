//
//  TagPrice.swift
//  wiseid
//
//  Created by Digital Owns  on 16/02/2020.
//  Copyright © 2020 GoOn. All rights reserved.
//

import UIKit

struct TagPrice: Codable {

    var title: String = ""
    var subtitle: String = ""
    var legal_info: String = ""
    var priceLines = [TagPriceLine]()
}
