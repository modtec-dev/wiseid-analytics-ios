//
//  ConfigUtil.swift
//  wiseid
//
//  Created by Digital Owns  on 08/02/2020.
//  Copyright © 2020 GoOn. All rights reserved.
//

import UIKit

class ConfigUtil: NSObject {
    
    static var pinLoja:String = ""
    static var idLoja:String = ""
    static var nmLoja:String = ""
    static var masterPassword:String = ""
    static var iddpgc:String = ""
    static var regiao:String = ""
    static var uf:String = ""
    static var tag: Tag = Tag()
    static var activeCampaign:Campaign = Campaign()
    static var activeBanner:Banner = Banner()
    static var indexOfVideo: Int = 0
    static var background:Bool = false
    static var ultimaAtualizacao:Date!
    static var exibindoEtiqueta:Bool = false
    static var atualizarEtiqueta:Bool = false
}
