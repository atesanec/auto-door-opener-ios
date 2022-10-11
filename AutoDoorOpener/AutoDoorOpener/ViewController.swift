//
//  ViewController.swift
//  AutoDoorOpener
//
//  Created by VI_Business on 10.10.22.
//

import UIKit
import Combine

class ViewController: UIViewController {
    let manager = AutoDoorOpenManager()
    var disposeBag = Set<AnyCancellable>()
    
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var logTextView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        manager.isRunning.sink { [weak self] isRunning in
            self?.startButton.isEnabled = !isRunning
            self?.stopButton.isEnabled = isRunning
        }.store(in: &disposeBag)
        
        manager.eventMessages.sink { [weak self] msg in
            let text = self?.logTextView.text ?? ""
            self?.logTextView.text = text + "\(Date()): \(msg)"
        }.store(in: &disposeBag)
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

