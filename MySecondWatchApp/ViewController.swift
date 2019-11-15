//
//  ViewController.swift
//  MySecondWatchApp
//
//  Created by Karen Galindo on 11/13/19.
//  Copyright © 2019 UPC. All rights reserved.
//

import UIKit
import WatchConnectivity
import HealthKit

class ViewController: UIViewController, WCSessionDelegate {
    
    var wcSession: WCSession! = nil
    let heartRateType: HKQuantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
    let health: HKHealthStore = HKHealthStore()
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var watchLabel: UILabel!
    @IBOutlet weak var btnSend: UIButton!
    @IBOutlet weak var bpmLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        textField.text = "example"
        wcSession = WCSession.default
        wcSession.delegate = self
        wcSession.activate()
        
        //self.subscribeToHeartBeatChages()
        self.requestAuthorization()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("recieved message 3")
        DispatchQueue.main.async {
            if let mss = message["btnMM"] as? Int {
                self.watchLabel.text = "\(mss)"
            }
            if let quantity = message["bpm"] as? Int {
                self.bpmLabel.text = "\(quantity) bpm"
            }
        }
    }
    
    // heart rate
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // print("recieved message 1")
        DispatchQueue.main.async {
            if let mss = message["btnMM"] as? Int {
                self.watchLabel.text = "\(mss)"
            }
            if let quantity = message["bpm"] as? Int {
                self.bpmLabel.text = "\(quantity) bpm"
            }
        }
    }
    
    // counter
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        // print("recieved message 2")
        DispatchQueue.main.async {
            if let mss = applicationContext["btnMM"] as? Int {
                self.watchLabel.text = "\(mss)"
            }
            if let quantity = applicationContext["bpm"] as? Int {
                self.bpmLabel.text = "\(quantity) bpm"
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("sessionDidBecomeInactive on iPhone")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("sessionDidDeactivate on iPhone")
    }
    
    
    @IBAction func sendtext(_ sender: UIButton) {
        let txt = textField.text!
        let message = ["name": txt]
        
        if wcSession.isReachable {
            wcSession.sendMessage(message, replyHandler: nil, errorHandler: { err in
                print(err.localizedDescription)
            })
        }
    }
    
    func requestAuthorization() {
        let readingTypes: Set = Set([heartRateType])
        let writingTypes: Set = Set([heartRateType])
        
        health.requestAuthorization(toShare: writingTypes, read: readingTypes, completion: {
            (success, err) in
            if err != nil {
                print("error: \(err?.localizedDescription ?? "error null")")
            }
            else if success {
                print("I have authrization")
            }
        })
    }
    
    /*var heartRateQuery: HKObserverQuery!
    var healStore: HKHealthStore = HKHealthStore()
    public func subscribeToHeartBeatChages() {
        guard let sampleType: HKSampleType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            return
        }
        
        self.heartRateQuery = HKObserverQuery(sampleType: sampleType, predicate: nil) {
            _, _, err in
            guard err == nil else {
                print(err!.localizedDescription)
                self.bpmLabel.text = err!.localizedDescription
                return
            }
            // update
            
            self.fetchLastestHeartRateSample(completion: { sample in
                guard let sample = sample else {
                    return
                }
                
                DispatchQueue.main.async {
                    let heartRateUnit = HKUnit(from: "count/min")
                    let heartRate = sample.quantity.doubleValue(for: heartRateUnit)
                    
                    self.bpmLabel.text = "\(Int(heartRate))"
                }
            })
        }
    }
    
    public func fetchLastestHeartRateSample(completion: @escaping (_ sample: HKQuantitySample?) -> Void) {
        guard let sampleType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion(nil)
            return
        }
        
        let predicate = HKQuery
            .predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictEndDate)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(
        sampleType: sampleType, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: [sortDescriptor]) { (_, results, error) in
            guard error == nil else {
                print("Error: \(error!.localizedDescription)")
                return
            }
            
            completion(results?[0] as? HKQuantitySample)
        }
        self.healStore.execute(query)
    }*/
}

// extension ViewController: WCSessionDelegate {}
