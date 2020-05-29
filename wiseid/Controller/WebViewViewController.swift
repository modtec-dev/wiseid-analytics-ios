//
//  WebViewViewController.swift
//  wiseid
//
//  Created by Digital Owns  on 09/02/2020.
//  Copyright © 2020 GoOn. All rights reserved.
//

import UIKit
import WebKit
import AVKit
import AVFoundation

class WebViewViewController: UIViewController, WKUIDelegate, UIGestureRecognizerDelegate, WKScriptMessageHandler {
    
    var webView: WKWebView!
    var player: AVPlayer!
    var controller: AVPlayerViewController!
    var exibindoVideo:Bool = false;
        
    override func loadView() {
        ConfigUtil.exibindoEtiqueta = true
        let webConfiguration = WKWebViewConfiguration()
        let controller = WKUserContentController()
        controller.add(self, name: "loadTag")
        webConfiguration.userContentController = controller
        webConfiguration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        view = webView
    }
    
    override func viewDidLoad(){
        super.viewDidLoad()
        webView.uiDelegate = self
        
        let tapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(self.goToback))
        tapGestureRecognizer.delegate = self
        tapGestureRecognizer.numberOfTapsRequired = 2
        webView.isUserInteractionEnabled = true
        webView.addGestureRecognizer(tapGestureRecognizer)
        
        let lpgr = UILongPressGestureRecognizer(target:self, action:#selector(self.handleLongPress))
        lpgr.minimumPressDuration = 3
        lpgr.delaysTouchesBegan = true
        lpgr.delegate = self
        webView.addGestureRecognizer(lpgr)
        
        self.chamaEtiqueta()
        
        Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(self.chamaVideo), userInfo: nil, repeats: false)
        
        Timer.scheduledTimer(timeInterval: 3600, target: self, selector: #selector(self.verificarRotina), userInfo: nil, repeats: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(enterBackground),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    @objc func verificarRotina(){
        RotinaAtualizacao().verificar()
    }
    
    @objc func enterBackground(){
       self.pararVideo()
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        jsonEtiqueta(message: message)
    }
    
    func jsonEtiqueta(message: WKScriptMessage) {
        
        let jsonEncoder = JSONEncoder()
        if(ConfigUtil.activeBanner.destinationUrls != nil){
            let imageData = try! Data(contentsOf: ConfigUtil.activeBanner.destinationUrls)
            
            let image = UIImage(data: imageData)
            if(image != nil){
                let strBase64 =  image!.pngData()!.base64EncodedString()
                ConfigUtil.tag.bannerUrl = strBase64
            }
        }
        let jsonData = try! jsonEncoder.encode(ConfigUtil.tag)
        let jsonStringTag = String(data: jsonData, encoding: String.Encoding.utf8)!
        
        let dict = [
            "tag":jsonStringTag
            
        ]
        let jsonDataDict = try! JSONSerialization.data(withJSONObject: dict, options: [])
        let jsonStringDict = String(data: jsonDataDict, encoding: String.Encoding.utf8)!
        
        self.webView.evaluateJavaScript("carregarJsonEtiqueta(\(jsonStringDict))") { result, error in
            guard error == nil else {
                return
            }
        }
    }
    
    @objc func chamaVideo(){
        if(ConfigUtil.activeCampaign.destinationUrls.count > 0 && !ConfigUtil.background && !exibindoVideo && ConfigUtil.exibindoEtiqueta){
            self.exibindoVideo = true
            let index = ConfigUtil.indexOfVideo
            let finalIndex = ConfigUtil.activeCampaign.destinationUrls.endIndex - 1
            
            self.player = AVPlayer(url: ConfigUtil.activeCampaign.destinationUrls[index])
            
            if finalIndex == index{
                ConfigUtil.indexOfVideo = 0
            }else{
                ConfigUtil.indexOfVideo = index + 1
            }
            
            self.controller = AVPlayerViewController()
            self.controller.player = player
            self.controller.showsPlaybackControls = false
            
            self.present(controller, animated: false) {
                self.player.play()
                
                let btn : UIButton = UIButton()
                btn.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
                btn.addTarget(self, action: #selector(self.touchVideoDetect), for: .touchUpInside)
                btn.backgroundColor  = UIColor.clear
                self.controller?.contentOverlayView?.addSubview(btn)
            }
            
            NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying(note:)),
                                                   name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player.currentItem)
        }else if(!self.exibindoVideo){
            self.pararVideo()
        }
    }
    
    @objc func touchVideoDetect(){
        self.pararVideo()
    }
    
    @objc func playerDidFinishPlaying(note: NSNotification) {
        self.pararVideo()
    }
    
    func pararVideo(){
        self.exibindoVideo = false
        if(player != nil){
            player.replaceCurrentItem(with: nil)
        }
        if(controller != nil){
            controller.player = nil
            controller.dismiss(animated: false, completion: nil)
        }
        Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(self.chamaVideo), userInfo: nil, repeats: false)
       
        if(ConfigUtil.atualizarEtiqueta){
            self.chamaEtiqueta()
            ConfigUtil.atualizarEtiqueta = false
        }else{
            if(self.webView != nil){
                self.webView.evaluateJavaScript("start()") { result, error in
                    guard error == nil else {
                        return
                    }
                }
            }
        }
    }
    
    func chamaEtiqueta(){
        do {
            guard let filePath = Bundle.main.path(forResource: "index", ofType: "html")
                else {
                    print ("File reading error")
                    return
            }
            
            let contents =  try String(contentsOfFile: filePath, encoding: .utf8)
            let baseUrl = URL(fileURLWithPath: filePath)
            webView.loadHTMLString(contents as String, baseURL: baseUrl)
        }
        catch {
            print ("File HTML error")
        }
    }
    
    func gestureRecognizer(_: UIGestureRecognizer,  shouldRecognizeSimultaneouslyWith:UIGestureRecognizer) -> Bool {
        return true
    }

    @objc func goToback() {
        ConfigUtil.background = true
        UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
        
    }
    
    @objc func handleLongPress(gesture : UILongPressGestureRecognizer){
        ConfigUtil.exibindoEtiqueta = false
        
        let newController = self.storyboard?.instantiateViewController(withIdentifier: "phoneDetail") as! PhoneDetailViewController
        self.present(newController, animated: true, completion: nil)
        view.removeFromSuperview()
    }
}
