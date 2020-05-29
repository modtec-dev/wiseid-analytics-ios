//
//  RotinaAtualizacao.swift
//  wiseid
//
//  Created by DigitalOwns on 29/02/2020.
//  Copyright © 2020 GoOn. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseStorage

class RotinaAtualizacao: NSObject {
    var view : UIViewController!
    
    func verificar(){
        if(ConfigUtil.ultimaAtualizacao != nil){
            let dtAtual = Date()
            
            let calendar = Calendar.current
            let dateUltima = calendar.startOfDay(for: ConfigUtil.ultimaAtualizacao)
            let dateAtual = calendar.startOfDay(for: dtAtual)
            
            let difDays = calendar.dateComponents([.day], from: dateUltima, to: dateAtual)
            let horaAtual = calendar.dateComponents([.hour], from:dtAtual);
            
            if(difDays.day != 0 && horaAtual.hour! > 3){
                ConfigUtil.background = true
                self.atualizarDiretorioVideos()
                self.atualizarDiretorioBanner()
                self.atualizarInformacoes()
            }
        }
    }
    
    func atualizarDiretorioVideos(){
        if(UserDefaults.standard.object(forKey: "activeCampaign") != nil){
            if let obj = UserDefaults.standard.object(forKey: "activeCampaign") as? Data{
                let decoder = JSONDecoder()
                if let loaded = try? decoder.decode(Campaign.self, from: obj) {
                    ConfigUtil.activeCampaign = loaded
                    
                    for url in ConfigUtil.activeCampaign.destinationUrls {
                        let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                        
                        let destinationUrl = documentsDirectoryURL.appendingPathComponent(url.lastPathComponent)
                        
                        let index = ConfigUtil.activeCampaign.destinationUrls.index(where: {$0.absoluteString == url.absoluteString })
                        
                        ConfigUtil.activeCampaign.destinationUrls[index!] = destinationUrl
                    }
                }
            }
        }
    }
    
    func atualizarDiretorioBanner(){
        if(UserDefaults.standard.object(forKey: "activeBanner") != nil){
            if let obj = UserDefaults.standard.object(forKey: "activeBanner") as? Data{
                let decoder = JSONDecoder()
                if let loaded = try? decoder.decode(Banner.self, from: obj) {
                    ConfigUtil.activeBanner = loaded
                
                    if(ConfigUtil.activeBanner.destinationUrls != nil){
                        let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                        
                        let destinationUrl = documentsDirectoryURL.appendingPathComponent(ConfigUtil.activeBanner.destinationUrls.lastPathComponent)
                        
                        ConfigUtil.activeBanner.destinationUrls = destinationUrl
                    }
                }
            }
        }
    }
    
    func atualizarInformacoes(){
        self.apagarVideosCampanha()
        self.apagarImagemBanner()
        self.consultarEtiquetaFirestore()
        
        ConfigUtil.ultimaAtualizacao = Date()
        
        UserDefaults.standard.set(ConfigUtil.ultimaAtualizacao, forKey: "ultimaAtualizacao")
    }
    
    func atualizarInformacoes(view : UIViewController){
        self.view = view
        self.atualizarInformacoes()
    }
    
    func apagarVideosCampanha(){
        ConfigUtil.indexOfVideo = 0
        UserDefaults.standard.removeObject(forKey: "activeCampaign")
        if(ConfigUtil.activeCampaign != nil && ConfigUtil.activeCampaign.videos.count > 0){
            
            for url in ConfigUtil.activeCampaign.destinationUrls {
                
                do {
                    try FileManager.default.removeItem(at: url)
                    print("deletou")
                } catch {
                    print(url.path)
                    print(error)
                    print("nao deletou")
                }
            }
        }
        ConfigUtil.activeCampaign = Campaign()
    }
    
    func apagarImagemBanner(){
        UserDefaults.standard.removeObject(forKey: "activeBanner")
        if(ConfigUtil.activeBanner != nil && ConfigUtil.activeBanner.destinationUrls != nil){
            do {
                try FileManager.default.removeItem(at: ConfigUtil.activeBanner.destinationUrls)
                print("deletou")
            } catch {
                print(ConfigUtil.activeBanner.destinationUrls.path)
                print(error)
                print("nao deletou")
            }
        }

        ConfigUtil.activeBanner = Banner()
    }
    
    func consultarEtiquetaFirestore(){
        var docData: [String: Any]!
        var tagRegion: [String: Any]!
        var tagStore: [String: Any]!
        var tagNational: [String: Any]!

        var docId: String!
        var docIdStore: String!
        var docIdRegional: String!
        var docIdNational: String!
        var batch: Bool = true
        
        Firestore.firestore().collection("tags").whereField("device.iddpgc", isEqualTo: ConfigUtil.iddpgc)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                    self.consultarGadgetFirestore()
                } else {
                    var date = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "dd/MM/yyyy"
                    dateFormatter.calendar = Calendar(identifier: .gregorian)
                    dateFormatter.timeZone = TimeZone(identifier: "UTC")
                    
                    let dateStd = dateFormatter.string(from: date)
                    date = dateFormatter.date(from: dateStd)!
                    
                    for document in querySnapshot!.documents {
                        if(document.data()["batch"] != nil){
                            batch = document.data()["batch"] as! Bool
                        }
                        
                        if (document.data()["store"] as? String == ConfigUtil.idLoja){
                            if(batch) {
                                if (UInt64(date.timeIntervalSince1970 * 1000) > document.data()["updateDate"] as! UInt64) {
                                    docIdStore = document.documentID
                                    tagStore = document.data()
                                }
                            }else{
                                docIdStore = document.documentID
                                tagStore = document.data()
                            }
                        }else if(document.data()["region"] as? String == ConfigUtil.regiao){
                            if(batch) {
                                if (UInt64(date.timeIntervalSince1970 * 1000) > document.data()["updateDate"] as! UInt64) {
                                    docIdRegional = document.documentID
                                    tagRegion = document.data()
                                }
                            }else{
                                docIdRegional = document.documentID
                                tagRegion = document.data()
                            }
                        }else if((document.data()["region"] as? String == "" || document.data()["region"] as? String == "NACIONAL") && document.data()["store"] as? String == ""){
                            if(batch) {
                                if (UInt64(date.timeIntervalSince1970 * 1000) > document.data()["updateDate"] as! UInt64) {
                                    docIdNational = document.documentID
                                    tagNational = document.data()
                                }
                            }else{
                                docIdNational = document.documentID
                                tagNational = document.data()
                            }
                        }
                    }
                    if(tagStore != nil){
                        docId = docIdStore
                        docData = tagStore
                    }else{
                        if(tagRegion != nil){
                            docId = docIdRegional
                            docData = tagRegion
                        }else {
                            if(tagNational != nil) {
                                docId = docIdNational
                                docData = tagNational
                            }
                        }
                    }
                    
                    if docData == nil {
                        self.consultarGadgetFirestore()
                    }else{
                        var docPriceArray: [[String : Any]] = Array()
                        Firestore.firestore().collection("tags").document(docId).collection("prices")
                            .getDocuments() { (querySnapshot, err) in
                                if let err = err {
                                    print("Error getting documents: \(err)")
                                } else {
                                    
                                    for document in querySnapshot!.documents {
                                        docPriceArray.append(document.data())
                                    }
                                    self.popularInformacoesEtiqueta(pDocId:docId, pDocData:docData, pDocPriceArray:docPriceArray)
                                }
                        }
                    }
                    
                }
        }
    }
    
    func consultarCampanhaFirestore(){
        ConfigUtil.activeCampaign = Campaign()
        
        Firestore.firestore().collection("campaigns").whereField("active", isEqualTo: true)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                    if(self.view != nil){
                        let phoneDetail = self.view as! PhoneDetailViewController
                        phoneDetail.popularInformacoes()
                        phoneDetail.removeSpinner()
                        phoneDetail.abrirWebView()
                    }
                    ConfigUtil.background = false
                } else {
                    var campaign:Campaign!
                    var campaignRegion:Campaign!
                    var campaignUf:Campaign!
                    var campaignStore:Campaign!
                    var campaignManufacturer:Campaign!
                    var campaignDevice:Campaign!
                    
                    for document in querySnapshot!.documents {
                        
                        campaign = self.castToCampaign(pDocData: document.data())
                        campaign.id = document.documentID
                        if(campaign.region.count > 0 &&
                            campaign.region.contains(ConfigUtil.regiao) &&
                            campaign.uf.count == 0){
                            campaignRegion = campaign
                        }
                        if(campaign.isValid() &&
                            campaign.uf.contains(ConfigUtil.uf) &&
                            campaign.stores.count == 0){
                            
                            campaignUf = campaign
                        }
                        if(campaign.isValid() &&
                            campaign.stores.contains(ConfigUtil.idLoja) &&
                            campaign.manufacturer.count == 0){
                            
                            campaignStore = campaign
                        }
                        if(campaign.isValid() &&
                            campaign.manufacturer.contains(ConfigUtil.tag.device.manufacturer) &&
                            campaign.devices.count == 0){
                            
                            campaignManufacturer = campaign
                        }
                        
                        if(campaign.isValid()
                            && campaign.devices.contains(ConfigUtil.iddpgc)
                            && campaign.stores.contains(ConfigUtil.idLoja)){
                            campaignDevice = campaign
                            break;
                        }
                    }
                    
                    if(campaignDevice != nil){
                        if(campaignDevice.isValid()){
                            ConfigUtil.activeCampaign = campaignDevice
                        }
                    }else if(campaignManufacturer != nil){
                        if( campaignManufacturer.isValid()){
                            ConfigUtil.activeCampaign = campaignManufacturer ;
                        }
                    }else if (campaignStore != nil){
                        if(campaignStore.isValid()){
                            ConfigUtil.activeCampaign = campaignStore ;
                        }
                    }else if (campaignUf != nil){
                        if(campaignUf.isValid()) {
                            ConfigUtil.activeCampaign = campaignUf;
                        }
                    }else if(campaignRegion != nil){
                        if(campaignRegion.isValid()){
                            ConfigUtil.activeCampaign = campaignRegion ;
                        }
                    }
                    if ConfigUtil.activeCampaign.id == "" {
                        if(self.view != nil){
                            let phoneDetail = self.view as! PhoneDetailViewController
                            phoneDetail.popularInformacoes()
                            phoneDetail.removeSpinner()
                            phoneDetail.abrirWebView()
                        }
                        ConfigUtil.background = false
                    }else{
                        self.consultarCampanhaStoraged()
                        if(self.view != nil){
                            let phoneDetail = self.view as! PhoneDetailViewController
                            phoneDetail.popularInformacoes()
                        }
                    }
                }
        }
        
    }
    func getPathVideos()->String{
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        let docURL = URL(string: documentsDirectory)!
        let dataPath = docURL
        if !FileManager.default.fileExists(atPath: dataPath.absoluteString) {
            do {
                try FileManager.default.createDirectory(atPath: dataPath.absoluteString, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription);
            }
        }
        return dataPath.absoluteString;
    }
    
    func consultarCampanhaStoraged(){
        
        let dataPath = getPathVideos()
        
        if(ConfigUtil.activeCampaign.videos.count > 0){
            var cont:Int = 1
            for nomeVideo in ConfigUtil.activeCampaign.videos {
                let caminhoVideo = ConfigUtil.activeCampaign.id + "/" + nomeVideo
                let storage = Storage.storage()
                let storageRef = storage.reference()
                let arquivo = storageRef.child("/Campaigns/" + caminhoVideo )
                let localURL = URL(fileURLWithPath: dataPath + "/" + nomeVideo)
                let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let destinationUrl = documentsDirectoryURL.appendingPathComponent(localURL.lastPathComponent)
                ConfigUtil.activeCampaign.destinationUrls.append(destinationUrl)
                
                if FileManager.default.fileExists(atPath: destinationUrl.path) {
                    print("The file already exists at path")
                    if(self.view != nil){
                        let phoneDetail = self.view as! PhoneDetailViewController
                        phoneDetail.removeSpinner()
                        phoneDetail.abrirWebView()
                    }
                    ConfigUtil.background = false
                } else {
                    arquivo.downloadURL { url, error in
                        if error != nil {
                            print("error")
                            if(cont == ConfigUtil.activeCampaign.videos.count){
                                if(self.view != nil){
                                    let phoneDetail = self.view as! PhoneDetailViewController
                                    phoneDetail.removeSpinner()
                                    phoneDetail.abrirWebView()
                                }
                                ConfigUtil.background = false
                            }
                            cont += 1
                        } else{
                            let httpsReference = storage.reference(forURL: (url?.absoluteString)!)
                            httpsReference.write(toFile: localURL){ url, error in
                                if error != nil {
                                    print("error")
                                } else {
                                    print("Archive Downloaded in folder: " + (url?.absoluteString)!)
                                    
                                }
                                if(cont == ConfigUtil.activeCampaign.videos.count){
                                    if(self.view != nil){
                                        let phoneDetail = self.view as! PhoneDetailViewController
                                        phoneDetail.removeSpinner()
                                        phoneDetail.abrirWebView()
                                    }
                                    ConfigUtil.background = false
                                }
                                cont += 1
                            }
                        }
                    }
                }
            }
        }else{
            if(self.view != nil){
                let phoneDetail = self.view as! PhoneDetailViewController
                phoneDetail.removeSpinner()
                phoneDetail.abrirWebView()
            }
            ConfigUtil.background = false
        }
        self.armazenarCampanha()
    }
    
    func armazenarCampanha(){
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(ConfigUtil.activeCampaign) {
            let defaults = UserDefaults.standard
            defaults.set(encoded, forKey: "activeCampaign")
        }
    }
    
    func castToCampaign(pDocData:[String: Any])->Campaign{
        let campaign:Campaign = Campaign()
        if(pDocData["active"] != nil){
            campaign.active = pDocData["active"] as! Bool
        }
        if(pDocData["name"] != nil){
            campaign.name = pDocData["name"] as! String
        }
        if(pDocData["startDate"] != nil){
            let inicio = pDocData["startDate"] as! UInt64
            campaign.startDate = Date(timeIntervalSince1970: (Double(inicio) / 1000.0))
        }
        
        if(pDocData["endDate"] != nil){
            let fim = pDocData["endDate"] as! UInt64
            campaign.endDate = Date(timeIntervalSince1970: (Double(fim) / 1000.0))
        }
        
        if(pDocData["devices"] != nil){
            let infosArray:NSArray = pDocData["devices"]  as! NSArray
            if (infosArray.count > 0){
                for info in infosArray {
                    campaign.devices.append(info as! String)
                }
            }
        }
        if(pDocData["manufacturer"] != nil){
            let infosArray:NSArray = pDocData["manufacturer"]  as! NSArray
            if (infosArray.count > 0){
                for info in infosArray {
                    campaign.manufacturer.append(info as! String)
                }
            }
        }
        if(pDocData["region"] != nil){
            let infosArray:NSArray = pDocData["region"]  as! NSArray
            if (infosArray.count > 0){
                for info in infosArray {
                    campaign.region.append(info as! String)
                }
            }
        }
        if(pDocData["stores"] != nil){
            let infosArray:NSArray = pDocData["stores"]  as! NSArray
            if (infosArray.count > 0){
                for info in infosArray {
                    campaign.stores.append(info as! String)
                }
            }
        }
        if(pDocData["uf"] != nil){
            let infosArray:NSArray = pDocData["uf"]  as! NSArray
            if (infosArray.count > 0){
                for info in infosArray {
                    campaign.uf.append(info as! String)
                }
            }
        }
        if(pDocData["videos"] != nil){
            let infosArray:NSArray = pDocData["videos"]  as! NSArray
            if (infosArray.count > 0){
                for info in infosArray {
                    campaign.videos.append(info as! String)
                }
            }
        }
        return campaign
        
    }
    
    func popularInformacoesEtiqueta(pDocId: String, pDocData:[String: Any], pDocPriceArray:[[String: Any]]){
        ConfigUtil.tag = Tag()
        
        var device: [String: Any] = (pDocData["device"] as? [String: Any])!
        var header: [String: Any] = (pDocData["header"] as? [String: Any])!
        if(header["infos"] != nil){
            let infosArray:NSArray = header["infos"] as! NSArray
            if (infosArray.count > 0){
                for info in infosArray {
                    ConfigUtil.tag.header.infos.append(info as! String)
                }
            }
        }
        
        if(header["title"] != nil){
            ConfigUtil.tag.header.title = header["title"] as! String
        }
        
        if(device["model"] != nil){
            ConfigUtil.tag.device.model = device["model"] as! String
        }
        if(device["manufacturer"] != nil){
            ConfigUtil.tag.device.manufacturer = device["manufacturer"] as! String
        }
        if(device["name"] != nil){
            ConfigUtil.tag.device.name = device["name"] as! String
        }
        if(device["iddpgc"] != nil){
            ConfigUtil.tag.device.iddpgc = device["iddpgc"] as! String
        }
        
        if (pDocPriceArray.count > 0){
            for docMap in pDocPriceArray{
                var tagPrice: TagPrice = TagPrice()
                if(docMap["legal_info"] != nil){
                    tagPrice.legal_info = docMap["legal_info"] as! String
                }
                if(docMap["title"] != nil){
                    tagPrice.title = docMap["title"] as! String
                }
                if(docMap["subtitle"] != nil){
                    tagPrice.subtitle = docMap["subtitle"] as! String
                }
                
                if(docMap["priceLines"] != nil){
                    let priceLineArray:NSArray = docMap["priceLines"] as! NSArray
                    if (priceLineArray.count > 0){
                        for priceLine in priceLineArray {
                            var tagPriceLine: TagPriceLine = TagPriceLine()
                            
                            tagPriceLine.disclaimer = (priceLine as! [String: Any])["disclaimer"] as! String
                            tagPriceLine.label = (priceLine as! [String: Any])["label"] as! String
                            tagPriceLine.value = (priceLine as! [String: Any])["value"] as! String
                            tagPrice.priceLines.append(tagPriceLine)
                        }
                        ConfigUtil.tag.prices.append(tagPrice)
                    }
                }
            }
        }
        consultarGadgetFirestore()
    }
    
    func consultarGadgetFirestore(){
        var docGadgetArray: [[String : Any]] = Array()
        Firestore.firestore().collection("gadgets").whereField("active", isEqualTo: true).whereField("device.iddpgc", isEqualTo: ConfigUtil.iddpgc).whereField("store", isEqualTo: ConfigUtil.idLoja)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    
                    for document in querySnapshot!.documents {
                        docGadgetArray.append(document.data())
                    }
                    self.popularInformacoesGadget(pDocGadgetArray:docGadgetArray)
                }
        }
    }
    
    func popularInformacoesGadget(pDocGadgetArray:[[String: Any]]){
        if (pDocGadgetArray.count > 0){
            for docMap in pDocGadgetArray{
                var tagGadget: TagGadget = TagGadget()
                if(docMap["legal_info"] != nil){
                    tagGadget.legal_info = docMap["legal_info"] as? String
                }
                if(docMap["title"] != nil){
                    tagGadget.title = docMap["title"] as? String
                }
                if(docMap["infos"] != nil){
                    let infosArray:NSArray = docMap["infos"] as! NSArray
                    if (infosArray.count > 0){
                        for info in infosArray {
                            tagGadget.infos.append(info as! String)
                        }
                    }
                }
                
                if(docMap["gadgetLines"] != nil){
                    let gadgetLineArray:NSArray = docMap["gadgetLines"] as! NSArray
                    if (gadgetLineArray.count > 0){
                        for gadgetLine in gadgetLineArray {
                            var tagGadgetLine: TagGadgetLine = TagGadgetLine()
                            
                            tagGadgetLine.disclaimer = (gadgetLine as! [String: Any])["disclaimer"] as! String
                            tagGadgetLine.label = (gadgetLine as! [String: Any])["label"] as! String
                            tagGadgetLine.value = (gadgetLine as! [String: Any])["value"] as! String
                            tagGadget.gadgetLines.append(tagGadgetLine)
                        }
                    }
                }
                ConfigUtil.tag.gadgets.append(tagGadget)
            }
        }
        
        UserDefaults.standard.set(ConfigUtil.iddpgc, forKey: "iddpgc")
        
        let encoder = JSONEncoder()
        
        if let encoded = try? encoder.encode(ConfigUtil.tag) {
            let defaults = UserDefaults.standard
            defaults.set(encoded, forKey: "tag")
        }
        
        consultarBannerFirestore()
    }
    
    func consultarBannerFirestore(){
        ConfigUtil.activeBanner = Banner()
        
        Firestore.firestore().collection("banners").whereField("regions", arrayContains: ConfigUtil.regiao)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    var banner:Banner!
                    var bannerRegion:Banner!
                    var bannerUf:Banner!
                    var bannerStore:Banner!
                    var bannerManufacturer:Banner!
                    var bannerDevice:Banner!
                    
                    for document in querySnapshot!.documents {
                        
                        banner = self.castToBanner(pDocData: document.data())
                        banner.id = document.documentID
                        if(banner.regions.count > 0 &&
                            banner.regions.contains(ConfigUtil.regiao) &&
                            banner.ufs.count == 0){
                            bannerRegion = banner
                        }
                        if(banner.isValid() &&
                            banner.ufs.contains(ConfigUtil.uf) &&
                            banner.stores.count == 0){
                            
                            bannerUf = banner
                        }
                        if(banner.isValid() &&
                            banner.stores.contains(ConfigUtil.idLoja) &&
                            banner.manufacturers.count == 0){
                            
                            bannerStore = banner
                        }
                        if(banner.isValid() &&
                            banner.manufacturers.contains(ConfigUtil.tag.device.manufacturer) &&
                            banner.devices.count == 0){
                            
                            bannerManufacturer = banner
                        }
                        
                        if(banner.isValid()
                            && banner.devices.contains(ConfigUtil.iddpgc)
                            && banner.stores.contains(ConfigUtil.idLoja)){
                            bannerDevice = banner
                            break;
                        }
                    }
                    
                    if(bannerDevice != nil){
                        if(bannerDevice.isValid()){
                            ConfigUtil.activeBanner = bannerDevice
                        }
                    }else if(bannerManufacturer != nil){
                        if( bannerManufacturer.isValid()){
                            ConfigUtil.activeBanner = bannerManufacturer ;
                        }
                    }else if (bannerStore != nil){
                        if(bannerStore.isValid()){
                            ConfigUtil.activeBanner = bannerStore ;
                        }
                    }else if (bannerUf != nil){
                        if(bannerUf.isValid()) {
                            ConfigUtil.activeBanner = bannerUf;
                        }
                    }else if(bannerRegion != nil){
                        if(bannerRegion.isValid()){
                            ConfigUtil.activeBanner = bannerRegion ;
                        }
                    }
                    if ConfigUtil.activeBanner.id == "" {
                        self.consultarCampanhaFirestore()
                        ConfigUtil.atualizarEtiqueta = true
                    }else{
                        self.consultarBannerStoraged()
                    }
                }
        }
    }
    
    func consultarBannerStoraged(){
        let dataPath = getPathVideos()
        
        if(ConfigUtil.activeBanner.id != nil){
            let nomeVideo = ConfigUtil.activeBanner.fileName
            let caminhoVideo = ConfigUtil.activeBanner.id + "/" + nomeVideo
            let storage = Storage.storage()
            let storageRef = storage.reference()
            let arquivo = storageRef.child("/banners/" + caminhoVideo )
            let localURL = URL(fileURLWithPath: dataPath + "/" + nomeVideo)
            let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let destinationUrl = documentsDirectoryURL.appendingPathComponent(localURL.lastPathComponent)
            ConfigUtil.activeBanner.destinationUrls = destinationUrl
            
            if FileManager.default.fileExists(atPath: destinationUrl.path) {
                print("The file already exists at path")
                self.consultarCampanhaFirestore()
                ConfigUtil.atualizarEtiqueta = true
            } else {
                arquivo.downloadURL { url, error in
                    if error != nil {
                        print("error")
                        
                        self.consultarCampanhaFirestore()
                        ConfigUtil.atualizarEtiqueta = true
                    } else{
                        let httpsReference = storage.reference(forURL: (url?.absoluteString)!)
                        httpsReference.write(toFile: localURL){ url, error in
                            if error != nil {
                                print("error")
                            } else {
                                print("Archive Downloaded in folder: " + (url?.absoluteString)!)
                            }
                            self.consultarCampanhaFirestore()
                            ConfigUtil.atualizarEtiqueta = true
                        }
                    }
                }
            }
        }else{
            self.consultarCampanhaFirestore()
            ConfigUtil.atualizarEtiqueta = true
        }
        self.armazenarBanner()
    }
    
    func armazenarBanner(){
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(ConfigUtil.activeBanner) {
            let defaults = UserDefaults.standard
            defaults.set(encoded, forKey: "activeBanner")
        }
    }
    
    func castToBanner(pDocData:[String: Any])->Banner{
        let banner:Banner = Banner()
        
        if(pDocData["name"] != nil){
            banner.name = pDocData["name"] as! String
        }
        if(pDocData["fileName"] != nil){
            banner.fileName = pDocData["fileName"] as! String
        }
        
        if(pDocData["devices"] != nil){
            let infosArray:NSArray = pDocData["devices"]  as! NSArray
            if (infosArray.count > 0){
                for info in infosArray {
                    banner.devices.append(info as! String)
                }
            }
        }
        if(pDocData["stores"] != nil){
            let infosArray:NSArray = pDocData["stores"]  as! NSArray
            if (infosArray.count > 0){
                for info in infosArray {
                    banner.stores.append(info as! String)
                }
            }
        }
        if(pDocData["ufs"] != nil){
            let infosArray:NSArray = pDocData["ufs"]  as! NSArray
            if (infosArray.count > 0){
                for info in infosArray {
                    banner.ufs.append(info as! String)
                }
            }
        }
        if(pDocData["manufacturers"] != nil){
            let infosArray:NSArray = pDocData["manufacturers"]  as! NSArray
            if (infosArray.count > 0){
                for info in infosArray {
                    banner.manufacturers.append(info as! String)
                }
            }
        }
        if(pDocData["regions"] != nil){
            let infosArray:NSArray = pDocData["regions"]  as! NSArray
            if (infosArray.count > 0){
                for info in infosArray {
                    banner.regions.append(info as! String)
                }
            }
        }
        if(pDocData["images"] != nil){
            let infosArray:NSArray = pDocData["images"]  as! NSArray
            if (infosArray.count > 0){
                for info in infosArray {
                    banner.images.append(info as! String)
                }
            }
        }
        if(pDocData["startDate"] != nil){
            let inicio = pDocData["startDate"] as! UInt64
            banner.startDate = Date(timeIntervalSince1970: (Double(inicio) / 1000.0))
        }
        
        if(pDocData["endDate"] != nil){
            let fim = pDocData["endDate"] as! UInt64
            banner.endDate = Date(timeIntervalSince1970: (Double(fim) / 1000.0))
        }
        if(pDocData["active"] != nil){
            banner.active = pDocData["active"] as! Bool
        }
        
        return banner
        
    }
}
