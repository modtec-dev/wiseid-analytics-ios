//
//  ViewController.swift
//  wiseid
//
//  Created by Digital Owns  on 01/02/2020.
//  Copyright © 2020 GoOn. All rights reserved.
//

import UIKit
import FirebaseFirestore

class ViewController: UIViewController {
    
    var pin: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let userName = UserDefaults.standard.string(forKey: "PIN")
        
        if (userName != nil && userName != "") {
            self.pin = userName!
            self.realizarLogin()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if(self.pin == ""){
            exibirPopUpPIN()
        }
    }
    
    func exibirPopUpPIN(){
        let ac = UIAlertController(title: "PIN da Loja:", message: nil, preferredStyle: .alert)
        ac.addTextField()
        
        let submitAction = UIAlertAction(title: "OK", style: .default) { [unowned ac] _ in
            if (ac.textFields![0].text != ""){
                self.pin = ac.textFields![0].text!
                
                self.realizarLogin()
            }else{
                let alertController = UIAlertController(title: "Alerta", message:
                    
                    "Entre com o PIN.", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default){ action in
                    self.exibirPopUpPIN()
                })
                
                self.present(alertController, animated: true, completion: nil)
            }
        }
        ac.addAction(submitAction)
        present(ac, animated: true)
    }
    
    func realizarLogin(){
        var docId: String = ""
        var docData: [String: Any]!
        
        Firestore.firestore().collection("stores")
            .whereField("pin", isEqualTo: self.pin)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for document in
                        querySnapshot!.documents {
                            docId = document.documentID
                            docData = document.data()
                    }
                    self.validaLogin(pDocId:docId, pDocData:docData)
                }
        }
    }
    
    func validaLogin(pDocId:String, pDocData:[String: Any]!){
        if pDocId != "" {
            
            ConfigUtil.pinLoja = self.pin
            ConfigUtil.idLoja = pDocId
            
            if(pDocData["name"] != nil){
                ConfigUtil.nmLoja = pDocData["name"] as! String
            }else{
                ConfigUtil.nmLoja = ""
            }
            if(pDocData["region"] != nil){
                ConfigUtil.regiao = pDocData["region"] as! String
            }else{
                ConfigUtil.regiao = ""
            }
            if(pDocData["uf"] != nil){
                ConfigUtil.uf = pDocData["uf"] as! String
            }else{
                ConfigUtil.uf = ""
            }
            if(pDocData["masterPassword"] != nil){
                ConfigUtil.masterPassword = pDocData["masterPassword"] as! String
            }else{
                ConfigUtil.masterPassword = ""
            }
            if(UserDefaults.standard.object(forKey: "ultimaAtualizacao") != nil){
                ConfigUtil.ultimaAtualizacao = (UserDefaults.standard.object(forKey: "ultimaAtualizacao") as! Date)
            }
            
            if(UserDefaults.standard.object(forKey: "tag") != nil){
                if let obj = UserDefaults.standard.object(forKey: "tag") as? Data{
                    let decoder = JSONDecoder()
                    if let loadedTag = try? decoder.decode(Tag.self, from: obj) {
                        ConfigUtil.tag = loadedTag
                    }
                }
            }
            if(UserDefaults.standard.string(forKey: "iddpgc") != nil){
                ConfigUtil.iddpgc = UserDefaults.standard.string(forKey: "iddpgc") ?? ""
                RotinaAtualizacao().verificar()
            }
            RotinaAtualizacao().atualizarDiretorioVideos()
            RotinaAtualizacao().atualizarDiretorioBanner()
            openNewViewController()
        }else{
            let alertController = UIAlertController(title: "Alerta", message:
                "PIN incorreto.", preferredStyle: .alert)
            
            let submitAction = UIAlertAction(title: "OK", style: .default) { action in
                self.exibirPopUpPIN()
            }
            alertController.addAction(submitAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    public func openNewViewController(){
        UserDefaults.standard.set(self.pin, forKey: "PIN")
        let iddpgc = UserDefaults.standard.string(forKey: "iddpgc")
        
        if (iddpgc != nil && iddpgc != "") {
            self.abrirWebView()
        }else{
            let newController = self.storyboard?.instantiateViewController(withIdentifier: "phoneDetail") as! PhoneDetailViewController
            self.present(newController, animated: true, completion: nil)
        }
    }
    
    func abrirWebView(){
        let newController = self.storyboard?.instantiateViewController(withIdentifier: "webView") as! WebViewViewController
        
        self.present(newController, animated: false, completion: nil)
    }
    
}
