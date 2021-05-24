//
//  DefaultLayoutViewController.swift
//  dscan
//
//  Created by zhang on 2021/03/18.
//

import UIKit
import DJISDK

class RootViewController: UIViewController, UITextFieldDelegate, LogCenterListener, MCUser {
    
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    var pref = Preferences.load()
    
    @IBOutlet weak var version: UILabel!
    @IBOutlet weak var registered: UILabel!
    @IBOutlet weak var register: UIButton!
    @IBOutlet weak var connected: UILabel!
    @IBOutlet weak var connect: UIButton!
    @IBOutlet weak var productName: UILabel!
    @IBOutlet weak var useBridgeSwitch: UISwitch!
    @IBOutlet weak var bridgeIDField: UITextField!
    @IBOutlet weak var debugLogView: UITextView!
    @IBOutlet weak var mcConnected: UILabel!
    @IBOutlet weak var mcConnect: UIButton!
    @IBOutlet weak var mcIP: UITextField!
    @IBOutlet weak var mcControlPort: UITextField!
    @IBOutlet weak var mcStreamPort: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(productCommunicationDidChange), name: Notification.Name(rawValue: "ProductCommunicationServiceStateDidChange"), object: nil)
        self.bridgeIDField.delegate = self
        LogCenterService.default.add(listener: self)
        
        self.mcIP.text = pref.serverIPAddr
        self.mcControlPort.text = pref.serverPort
        self.mcStreamPort.text = pref.serverStreamPort
        
        MCCommunicationService.shared.userDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.version.text = "\(DJISDKManager.sdkVersion())"
        self.bridgeIDField.text = ProductCommunicationService.shared.bridgeAppIP
        self.useBridgeSwitch.isOn = ProductCommunicationService.shared.useBridge
    }
    
    @IBAction func registerAction() {
        ProductCommunicationService.shared.registerWithProduct()
    }
    
    @IBAction func connectAction() {
        ProductCommunicationService.shared.connectToProduct()
    }

    @IBAction func mcConnectAction(_ sender: Any) {
        if self.mcConnected.text == "NO" {
            MCCommunicationService.shared.connect()
        } else if self.mcConnected.text == "YES" {
            MCCommunicationService.shared.disconnect()
        }
    }
    
    func MCDisconnected() {
        self.mcConnected.text = "NO"
        self.mcConnect.setTitle("Connect", for: .normal)
        LogCenterService.default.add("Disconnected.")
    }
    
    func MCConnected() {
        self.mcConnected.text = "YES"
        self.mcConnect.setTitle("Disconnect", for: .normal)
    }
    
    @IBAction func useBridgeAction(_ sender: UISwitch) {
        ProductCommunicationService.shared.useBridge = sender.isOn
        ProductCommunicationService.shared.disconnectFromProduct()
    }
    
    @IBAction func pushWidgetList(_ sender: Any) {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WidgetSplitViewController") as? UISplitViewController {
            guard let navCon = vc.viewControllers.first as? UINavigationController else {
                return
            }
            guard let widgetsListViewController = navCon.topViewController as? WidgetsListViewController else {
                return
            }
            guard let singleWidgetViewController = vc.viewControllers.last as? SingleWidgetViewController else {
                return
            }
            widgetsListViewController.delegate = singleWidgetViewController
            present(vc, animated: true, completion: nil)
        }
    }
    
    @objc func productCommunicationDidChange() {
        if ProductCommunicationService.shared.registered {
            self.registered.text = "YES"
            self.register.isHidden = true
        } else {
            self.registered.text = "NO"
            self.register.isHidden = false
        }
        
        if ProductCommunicationService.shared.connected {
            self.connected.text = "YES"
            self.connect.isHidden = true
            
            guard let produtNameKey = DJIProductKey(param: DJIProductParamModelName) else {
                NSLog("Failed to create product name key")
                return;
            }
            
            let currentProductNameValue = DJISDKManager.keyManager()?.getValueFor(produtNameKey)
            
            if currentProductNameValue != nil {
                self.productName.text = currentProductNameValue?.stringValue
            } else {
                self.productName.text = "N/A"
            }
            
            DJISDKManager.keyManager()?.startListeningForChanges(on: produtNameKey, withListener: self, andUpdate: { (oldValue: DJIKeyedValue?, newValue: DJIKeyedValue?) in
                if newValue != nil {
                    self.productName.text = newValue?.stringValue
                } else {
                    self.productName.text = "N/A"
                }
            })
        } else {
            self.connected.text = "NO"
            self.connect.isHidden = false
            self.productName.text = "N/A"
        }
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == self.bridgeIDField {
            ProductCommunicationService.shared.bridgeAppIP = textField.text!
        } else if textField == self.mcIP {
            self.pref.serverIPAddr = self.mcIP.text ?? ""
            Preferences.save(self.pref)
        } else if textField == self.mcControlPort {
            self.pref.serverPort = self.mcControlPort.text ?? ""
            Preferences.save(self.pref)
        } else if textField == self.mcStreamPort {
            self.pref.serverStreamPort = self.mcStreamPort.text ?? ""
            Preferences.save(self.pref)
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - LogCenterListener
    
    func logCenterContentDidChange() {
        self.debugLogView.text = LogCenterService.default.fullLog()
    }
    
}
