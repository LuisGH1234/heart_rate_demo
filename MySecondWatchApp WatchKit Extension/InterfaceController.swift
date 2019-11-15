//
//  InterfaceController.swift
//  MySecondWatchApp WatchKit Extension
//
//  Created by Karen Galindo on 11/13/19.
//  Copyright © 2019 UPC. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit
import WatchConnectivity

class InterfaceController: WKInterfaceController, WCSessionDelegate {
    var wcSession: WCSession! = nil
    let health: HKHealthStore = HKHealthStore()
    let hearRateUnit: HKUnit = HKUnit(from: "count/min")
    let heartRateType: HKQuantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
    var heartRateQuery: HKQuery?
    var count = 0
    
    @IBOutlet weak var heartRateLabel: WKInterfaceLabel!
    @IBOutlet weak var labeltext: WKInterfaceLabel!
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        let text = message["name"] as! String
        labeltext.setText(text)
    }
    

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        
        wcSession = WCSession.default
        wcSession.delegate = self
        wcSession.activate()
        
        heartRateQuery = self.createStreamingQuery()
        health.execute(self.heartRateQuery!)
        // subscribeToHeartBeatChages()
    }
    override func didAppear() {
        super.didAppear()
    }
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    
    @IBAction func genButton() {
        /*if self.wcSession.isReachable {
            let message = ["btnMM": count]
            self.wcSession.sendMessage(message, replyHandler: nil) { err in
                print("error sinding message: \(err.localizedDescription)")
            }
        }*/
        if self.wcSession.activationState == .activated {
            do {
                let message = ["btnMM": count]
                try self.wcSession.updateApplicationContext(message)
            } catch let err {
                print("error trying to updateAppContext: \(err.localizedDescription)")
            }
        }
        count+=1
    }
    
    private func createStreamingQuery() -> HKQuery {
        let queryPredicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate)
        let query: HKAnchoredObjectQuery = HKAnchoredObjectQuery(type: self.heartRateType, predicate: queryPredicate, anchor: nil, limit: Int(HKObjectQueryNoLimit), resultsHandler: {
            (query, samples, deletedObject, anchor, error) in
            if let errFound = error {
                print("query error: \(errFound.localizedDescription)")
            }
            else {
                if let samples = samples as? [HKQuantitySample] {
                    if let quantity = samples.last?.quantity {
                        let quanityD: Double = quantity.doubleValue(for: self.hearRateUnit)
                        self.heartRateLabel.setText("\(quanityD) bpm")
                        // option 1
                        if self.wcSession.isReachable {
                            let message = ["bpm": Int(quanityD)]
                            self.wcSession.sendMessage(message, replyHandler: nil) { err in
                                print("error sinding message: \(err.localizedDescription)")
                            }
                        }
                        // option 2
                        /*if self.wcSession.activationState == .activated {
                            do {
                                let message = ["bpm": quantity]
                                try self.wcSession.updateApplicationContext(message)
                            } catch let err {
                                print("error trying to updateAppContext: \(err.localizedDescription)")
                            }
                        }*/
                    }
                }
            }
            
            
        })
        
        query.updateHandler = {
            (query, samples, deletedObjects, anchor, error) in
            if let errFound = error {
                print("query error: \(errFound.localizedDescription)")
            }
            else {
                if let samples = samples as? [HKQuantitySample] {
                    if let quantity = samples.last?.quantity {
                        let quanityD: Double = quantity.doubleValue(for: self.hearRateUnit)
                        self.heartRateLabel.setText("\(quanityD) bpm")
                        
                        if self.wcSession.isReachable {
                            let message = ["bpm": Int(quanityD)]
                            self.wcSession.sendMessage(message, replyHandler: nil) { err in
                                print("error sinding message: \(err.localizedDescription)")
                            }
                        }
                        /*if self.wcSession.activationState == .activated {
                            do {
                                let message = ["bpm": Int(quanityD)]
                                try self.wcSession.updateApplicationContext(message)
                            } catch let err {
                                print("error trying to updateAppContext: \(err.localizedDescription)")
                            }
                        }*/
                    }
                }
            }
        }
        return query
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
            guard err != nil else {
                print(err!.localizedDescription)
                self.heartRateLabel.setText(err!.localizedDescription)
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
                    
                    self.heartRateLabel.setText("\(Int(heartRate))")
                }
            })
        }
        
        /*if let query = self.heartRateQuery {
            self.healStore.execute(query)
        }*/
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
