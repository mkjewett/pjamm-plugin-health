import Foundation
import Capacitor
import HealthKit

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(PJAMMHealthPlugin)
public class PJAMMHealthPlugin: CAPPlugin {
    private let implementation = PJAMMHealth()
    private let heartRateQuantity = HKUnit(from: "count/min")
    private var healthStore:HKHealthStore?
    private var healthAuthorized:Bool = false
    private var activeQuery_HR:HKAnchoredObjectQuery?
    
    public override func load() {
        
        if HKHealthStore.isHealthDataAvailable() {
            self.healthStore = HKHealthStore()
            
            guard
                let energy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
                let heart = HKObjectType.quantityType(forIdentifier: .heartRate) else {
                    return
            }
            
            let reading: Set = [energy, heart]
            let writing: Set = [HKQuantityType.workoutType()]
            
            healthStore?.requestAuthorization(toShare: writing, read: reading) { (success, error) in
                print("Request Authorization -- Success: ", success, " Error: ", error ?? "nil")
                self.healthAuthorized = success
            }
        }
    }

    @objc func getHealthData(_ call: CAPPluginCall) {
        guard let healthStore = healthStore else {
            call.reject("Health kit data not available.")
            return
        }
        
        if !self.healthAuthorized {
            call.reject("Health kit data not authorized")
            return
        }
        
    }

    @objc func startWatchingHealthData(_ call: CAPPluginCall) {
        
        if !self.healthAuthorized {
            return
        }
    
        
        
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            return;
        }
        
        let updateHandler_HR: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = {
            query, samples, deletedObjects, queryAnchor, error in
            
            print("PJAMMHealth - Update Handler Fired")
            
            guard let samples = samples as? [HKQuantitySample] else {
                return
            }
            
            var lastHeartRate = 0.0
            
            for sample in samples {
                lastHeartRate = sample.quantity.doubleValue(for: self.heartRateQuantity)
            }
            
            print("PJAMMHealth - Last Heart Rate = \(lastHeartRate)")
        }

        let query_HR = HKAnchoredObjectQuery(type: heartRateType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit, resultsHandler: updateHandler_HR)
        
        query_HR.updateHandler = updateHandler_HR
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            guard let healthStore = self.healthStore else {
                return
            }
            
            healthStore.enableBackgroundDelivery(for: heartRateType, frequency: .immediate) { (success, error) in }
            healthStore.execute(query_HR)
            
            guard let activeQuery_HR = self.activeQuery_HR else {
                self.activeQuery_HR = query_HR
                return
            }
            
            healthStore.stop(activeQuery_HR)
            self.activeQuery_HR = query_HR
        }

    }

    @objc func stopWatchingHealthData(_ call: CAPPluginCall) {
        guard let activeQuery_HR = activeQuery_HR else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            guard let healthStore = self.healthStore else {
                return
            }
            
            healthStore.disableAllBackgroundDelivery { (success, error) in }
            healthStore.stop(activeQuery_HR)
            self.activeQuery_HR = nil
        }
    }

}