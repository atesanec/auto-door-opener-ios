//
//  ViewController.swift
//  AutoDoorOpener
//
//  Created by VI_Business on 10.10.22.
//

import UIKit

class ViewController: UIViewController {
    let manager = AutoDoorOpenManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func onStart() {
        manager.start()
    }
    
    @IBAction func onStop() {
        manager.stop()
    }
    
    @IBAction func onTestDoorOpen() {
        manager.runDoorOpen()
    }
}

