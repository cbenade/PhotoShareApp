//
//  MenuViewController.swift
//  PhotoShareApp
//
//  Created by Christian Benade on 2019-11-28.
//  Copyright © 2019 Christian Benade. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController, UITextFieldDelegate{
    
    @IBOutlet var welcomeMessageLabel: UILabel!
    @IBOutlet var iconImageView: UIImageView!
    @IBOutlet var menuMessageLabel: UILabel!
    @IBOutlet var groupTextField: UITextField!
    @IBOutlet var nextViewButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        groupTextField.delegate = self
        iconImageView.image = UIImage(named: "Icon-Alpha")
        groupTextField.text = "CS50"
        
        // Initialization for web services
        AWSManager.shared.configureAWSObjects()
        SocketIOManager.shared.listenForServer()
    }
    
    // Set SocketIO room to nil then reconnect socket when user enters menu view
    override func viewDidAppear(_ animated: Bool) {
        SocketIOManager.shared.disconnect()
        UserDefaults.standard.set(nil, forKey: "groupName")
        SocketIOManager.shared.connect()
    }
    
    // Dismiss keyboard when user taps outside of the text field
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        view.endEditing(true)
    }
    
    // Dismiss keyboard after presses "Done"
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    // Disable text field text field is empty
    @IBAction func textFieldEditingChanged() {
        if groupTextField.text!.isEmpty {
            nextViewButton.isUserInteractionEnabled = false
        } else {
            nextViewButton.isUserInteractionEnabled = true
        }
    }
    
    // Segue view to ContentViewController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PhotoFeedSegue",
            let destination = segue.destination as? ContentViewController,
            
            // Remove spaces from groupName, then pass value to next view controller
            let groupName = groupTextField.text?.lowercased().replacingOccurrences(
            of: " ",
            with: "",
            options: NSString.CompareOptions.literal,
            range:nil) {
                destination.groupName = groupName
            }
    }
}
