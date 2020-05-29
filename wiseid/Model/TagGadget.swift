//
//  TagGadget.swift
//  wiseid
//
//  Created by Ana Luiza Boldrini  on 29/03/2020.
//  Copyright © 2020 GoOn. All rights reserved.
//

import UIKit

struct TagGadget: Codable {

    var title: String!
    var legal_info: String!
    var infos = [String]()
    var gadgetLines = [TagGadgetLine]()
}
