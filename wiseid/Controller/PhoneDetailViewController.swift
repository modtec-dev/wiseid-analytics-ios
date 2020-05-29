//
//  PhoneDetailViewController.swift
//  wiseid
//
//  Created by Digital Owns  on 06/02/2020.
//  Copyright © 2020 GoOn. All rights reserved.
//

import UIKit
import FirebaseFirestore

class PhoneDetailViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var modeloAparelho: UILabel!
    @IBOutlet weak var nomeCampanha: UILabel!
    @IBOutlet weak var dtInicioCampanha: UILabel!
    @IBOutlet weak var dtFinalCampanha: UILabel!
    @IBOutlet weak var tfIdAparelho: UITextField!
    @IBOutlet weak var lbInternet: UILabel!
    @IBOutlet weak var idLoja: UITextField!    
    @IBOutlet weak var nmLoja: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.isUserInteractionEnabled = true
        
        let tapGestureBackground = UITapGestureRecognizer(target: self, action: #selector(self.backgroundTapped(_:)))
        self.view.addGestureRecognizer(tapGestureBackground)
        
        let iddpgc = UserDefaults.standard.string(forKey: "iddpgc")
        
        if (iddpgc != nil && iddpgc != "" && self.tfIdAparelho != nil) {
            self.tfIdAparelho.text = iddpgc!
            self.popularInformacoes()
        }
        self.idLoja.text = ConfigUtil.pinLoja
        self.nmLoja.text = ConfigUtil.nmLoja + " "
        _ = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(self.marqueeNmLoja), userInfo: nil, repeats: true)
        
        _ = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(self.marqueeModeloAparelho), userInfo: nil, repeats: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        isConnectedToNetwork()
        
        let iddpgc = UserDefaults.standard.string(forKey: "iddpgc")
        
        if (iddpgc != nil && iddpgc != "" && ConfigUtil.masterPassword != "") {
            exibirPopUp()
        }
    }
    
    func isConnectedToNetwork(){
        
        self.lbInternet.text = "Sem sinal •"
        self.lbInternet.textColor = UIColor.red
        
        let url = NSURL(string: "http://google.com/")
        let request = NSMutableURLRequest(url: url! as URL)
        request.httpMethod = "HEAD"
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 10.0
        let session = URLSession.shared
        
        session.dataTask(with: request as URLRequest, completionHandler: {(data, response, error) in
            print("data \(data)")
            print("response \(response)")
            print("error \(error)")
            
            if let httpResponse = response as? HTTPURLResponse {
                print("httpResponse.statusCode \(httpResponse.statusCode)")
                if httpResponse.statusCode == 200 {
                    self.lbInternet.text = "Conectado •"
                    self.lbInternet.textColor = UIColor.green
                }
            }
            
        }).resume()
    }
    
    func exibirPopUp(){
        let alertController = UIAlertController(title: "Alerta", message:
            
            "Entre com a masterPassword.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        
        let ac = UIAlertController(title: "masterPassword:", message: nil, preferredStyle: .alert)
        ac.addTextField()
        
        let submitAction = UIAlertAction(title: "OK", style: .default) { [unowned ac] _ in
            if(ConfigUtil.masterPassword != ac.textFields![0].text!){
                self.exibirPopUp()
            }
        }
        ac.addAction(submitAction)
        present(ac, animated: true)
    }
    
    func abrirWebView(){
        let newController = self.storyboard?.instantiateViewController(withIdentifier: "webView") as! WebViewViewController
        
        self.present(newController, animated: false, completion: nil)
        view.removeFromSuperview()
    }
    
    @IBAction func btAtualizarInformacoes(_ sender: Any) {
        
        if self.idLoja != nil && ConfigUtil.pinLoja != self.idLoja.text {
            atualizaPinLoja(pinLoja: self.idLoja.text!)
        }else{
            self.idLoja.resignFirstResponder()
            self.tfIdAparelho.resignFirstResponder()
            ConfigUtil.iddpgc = self.tfIdAparelho.text!
            ConfigUtil.pinLoja = self.idLoja.text!
            self.showSpinner(onView: self.view)
            RotinaAtualizacao().atualizarInformacoes(view : self)
        }
    }
    
    func popularInformacoes(){
        if(self.idLoja != nil){
            self.idLoja.text = ConfigUtil.pinLoja
            self.modeloAparelho.text = ConfigUtil.tag.device.model + " "
            self.nmLoja.text = ConfigUtil.nmLoja + " "
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
            dateFormatter.calendar = Calendar(identifier: .gregorian)
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
            if(ConfigUtil.activeCampaign.startDate != nil){
                self.dtInicioCampanha.text = dateFormatter.string(from: ConfigUtil.activeCampaign.startDate)
            }
            if(ConfigUtil.activeCampaign.endDate != nil){
                self.dtFinalCampanha.text = dateFormatter.string(from: ConfigUtil.activeCampaign.endDate)
            }
            self.nomeCampanha.text = ConfigUtil.activeCampaign.name
        }
    }
    
    @objc func marqueeNmLoja(){
        if(self.nmLoja.text != nil && self.modeloAparelho.text != ""){
            let str = self.nmLoja.text!
            let indexFirst = str.index(str.startIndex, offsetBy: 0)
            let indexSecond = str.index(str.startIndex, offsetBy: 1)
            self.nmLoja.text = String(str.suffix(from: indexSecond)) + String(str[indexFirst])
        }
    }
    
    @objc func marqueeModeloAparelho(){
        if(self.modeloAparelho.text != nil && self.modeloAparelho.text != ""){
            let str = self.modeloAparelho.text!
            let indexFirst = str.index(str.startIndex, offsetBy: 0)
            let indexSecond = str.index(str.startIndex, offsetBy: 1)
            self.modeloAparelho.text = String(str.suffix(from: indexSecond)) + String(str[indexFirst])
        }
    }
    
    @objc func backgroundTapped(_ sender: UITapGestureRecognizer)
    {
        self.tfIdAparelho.resignFirstResponder()
        self.idLoja.resignFirstResponder()
    }
    
    func atualizaPinLoja(pinLoja :String){
        
        //Busca no Firestore
        var docId: String = ""
        var docData: [String: Any]!
        
        Firestore.firestore().collection("stores")
            .whereField("pin", isEqualTo: pinLoja)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for document in
                        querySnapshot!.documents {
                            docId = document.documentID
                            docData = document.data()
                    }
                    self.validaLoja(pin:pinLoja, pDocId:docId, pDocData:docData)
                }
        }
    }
    
    func validaLoja(pin:String, pDocId:String, pDocData:[String: Any]!){
        
        if pDocId != "" {
            
            ConfigUtil.pinLoja = pin
            UserDefaults.standard.set(pin, forKey: "PIN")
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
            
            self.tfIdAparelho.resignFirstResponder()
            self.idLoja.resignFirstResponder()
            ConfigUtil.iddpgc = self.tfIdAparelho.text!
            ConfigUtil.pinLoja = self.idLoja.text!
            self.showSpinner(onView: self.view)
            RotinaAtualizacao().atualizarInformacoes(view : self)

        }else{
            let alertController = UIAlertController(title: "Alerta", message:
                "PIN incorreto.", preferredStyle: .alert)
            
            let submitAction = UIAlertAction(title: "OK", style: .default) { action in
                
            }
            alertController.addAction(submitAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
}

var vSpinner : UIView?

extension UIViewController {
    func showSpinner(onView : UIView) {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView.init(style: .whiteLarge)
        ai.startAnimating()
        ai.center = spinnerView.center
        
        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }
        
        vSpinner = spinnerView
    }
    
    func removeSpinner() {
        DispatchQueue.main.async {
            vSpinner?.removeFromSuperview()
            vSpinner = nil
        }
    }
}
