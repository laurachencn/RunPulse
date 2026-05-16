import Foundation
import HealthKit
import WatchKit
import CoreLocation

@MainActor
final class WorkoutManager: NSObject, ObservableObject {
    @Published var runState = WatchRunState.idle
    @Published var splits: [KilometerSplit] = []
    
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var locationProvider = LocationProvider()
    
    private var currentKilometerDistance: Double = 0
    private var currentKilometerStartTime: Date?
    private var currentKilometerHeartRates: [Double] = []
    private var totalDistance: Double = 0
    private var lastLocation: CLLocation?
    
    private var currentHeartRate: Double = 0
    private var allHeartRates: [Double] = []
    
    private var timer: Timer?
    private(set) var startDate: Date?
    private(set) var currentSession: RunSession?
    private var isPaused = false
    private var pauseStartTime: Date?
    
    func calculatePace(duration: TimeInterval, distance: Double) -> TimeInterval {
        guard distance > 0 else { return 0 }
        let km = distance / 1000.0
        return duration / km
    }
    
    func metersToKilometers(_ meters: Double) -> Double {
        meters / 1000.0
    }
    
    func currentKilometer(for distance: Double) -> Int {
        Int(distance / 1000.0) + 1
    }
    
    func startWorkout() async {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            
            workoutSession?.delegate = self
            workoutBuilder?.delegate = self
            
            workoutSession?.startActivity(with: Date())
            workoutBuilder?.beginCollection(withStart: Date()) { success, error in
                if success {
                    Task { @MainActor in
                        self.runState.state = .running
                        self.startDate = Date()
                        self.currentKilometerStartTime = Date()
                        self.startTimer()
                    }
                }
            }
        } catch {
            print("Failed to start workout: \(error)")
        }
    }
    
    func pauseWorkout() {
        isPaused = true
        pauseStartTime = Date()
        runState.state = .paused
        timer?.invalidate()
        workoutSession?.pause()
    }
    
    func resumeWorkout() {
        isPaused = false
        if let pauseStart = pauseStartTime {
            let pauseDuration = Date().timeIntervalSince(pauseStart)
            startDate = Date().addingTimeInterval(-pauseDuration)
        }
        runState.state = .running
        startTimer()
        workoutSession?.resume()
        pauseStartTime = nil
    }
    
    func endWorkout() async -> RunSession? {
        timer?.invalidate()
        workoutSession?.end()
        
        let endDate = Date()
        let duration = startDate.map { endDate.timeIntervalSince($0) } ?? 0
        
        let session = RunSession(
            id: UUID(),
            startDate: startDate ?? Date(),
            endDate: endDate,
            totalDuration: duration,
            totalDistance: totalDistance,
            totalCalories: 0,
            averageHeartRate: allHeartRates.isEmpty ? 0 : allHeartRates.reduce(0, +) / Double(allHeartRates.count),
            maxHeartRate: allHeartRates.max() ?? 0,
            averagePace: calculatePace(duration: duration, distance: totalDistance),
            splits: splits,
            isCompleted: true
        )
        
        currentSession = session
        runState.state = .completed
        return session
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateDuration()
            }
        }
    }
    
    private func updateDuration() {
        guard let startTime = startDate else { return }
        runState.currentDuration = Date().timeIntervalSince(startTime)
    }
    
    func processHeartRate(_ heartRate: Double) {
        currentHeartRate = heartRate
        allHeartRates.append(heartRate)
        currentKilometerHeartRates.append(heartRate)
        runState.currentHeartRate = heartRate
        
        if heartRate > Double(runState.alertThreshold) && !runState.isAlerting {
            triggerHeartRateAlert()
        } else if heartRate < Double(runState.alertThreshold) - 5 && runState.isAlerting {
            runState.isAlerting = false
        }
        
        runState.averageHeartRate = allHeartRates.isEmpty ? 0 : allHeartRates.reduce(0, +) / Double(allHeartRates.count)
    }
    
    private func triggerHeartRateAlert() {
        runState.isAlerting = true
        WKInterfaceDevice.current().play(.heartbeat)
    }
    
    func processLocation(_ location: CLLocation) {
        guard let lastLocation = lastLocation else {
            self.lastLocation = location
            return
        }
        
        let distance = location.distance(from: lastLocation)
        totalDistance += distance
        currentKilometerDistance += distance
        
        runState.currentDistance = totalDistance
        runState.currentKilometer = currentKilometer(for: totalDistance)
        
        if currentKilometerDistance >= 1000 {
            completeKilometer()
        }
        
        if let startTime = currentKilometerStartTime {
            let kmDuration = Date().timeIntervalSince(startTime)
            runState.currentPace = calculatePace(duration: kmDuration, distance: currentKilometerDistance)
        }
        
        self.lastLocation = location
    }
    
    private func completeKilometer() {
        guard let kmStartTime = currentKilometerStartTime else { return }
        
        let kmDuration = Date().timeIntervalSince(kmStartTime)
        let avgHR = currentKilometerHeartRates.isEmpty ? 0 : currentKilometerHeartRates.reduce(0, +) / Double(currentKilometerHeartRates.count)
        let maxHR = currentKilometerHeartRates.max() ?? 0
        let minHR = currentKilometerHeartRates.min() ?? 0
        
        let split = KilometerSplit(
            id: UUID(),
            kilometerNumber: splits.count + 1,
            duration: kmDuration,
            averageHeartRate: avgHR,
            maxHeartRate: maxHR,
            minHeartRate: minHR,
            pace: kmDuration / (currentKilometerDistance / 1000.0),
            distance: currentKilometerDistance,
            calories: 0,
            timestamp: Date()
        )
        
        splits.append(split)
        runState.lastSplit = split
        
        WKInterfaceDevice.current().play(.notification(.success))
        
        currentKilometerDistance = 0
        currentKilometerStartTime = Date()
        currentKilometerHeartRates = []
    }
}

extension WorkoutManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        Task { @MainActor in
            switch toState {
            case .running:
                runState.state = .running
            case .paused:
                runState.state = .paused
            case .ended:
                runState.state = .completed
            case .stopped:
                runState.state = .notStarted
            @unknown default:
                break
            }
        }
    }
    
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error)")
    }
}

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
    }
    
    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        Task { @MainActor in
            guard let statisticsCollection = workoutBuilder.statistics else { return }
            
            // Process heart rate
            if let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate),
               let heartRateStats = statisticsCollection[heartRateType] {
                if let heartRateQuantity = heartRateStats.mostRecentQuantity {
                    let heartRate = heartRateQuantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                    processHeartRate(heartRate)
                }
            }
            
            // Process distance
            if let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning),
               let distanceStats = statisticsCollection[distanceType] {
                if let totalDistance = distanceStats.sumQuantity() {
                    let distanceMeters = totalDistance.doubleValue(for: HKUnit.meter())
                    let location = CLLocation(latitude: 0, longitude: 0) // GPS would provide actual coords
                    processLocation(location)
                    // Update total distance from HealthKit
                    self.totalDistance = distanceMeters
                    runState.currentDistance = distanceMeters
                    runState.currentKilometer = currentKilometer(for: distanceMeters)
                    
                    if currentKilometerDistance >= 1000 {
                        completeKilometer()
                    }
                }
            }
            
            // Process calories
            if let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
               let calorieStats = statisticsCollection[calorieType] {
                if let calorieQuantity = calorieStats.sumQuantity() {
                    let calories = calorieQuantity.doubleValue(for: HKUnit.kilocalorie())
                    runState.totalCalories = calories
                }
            }
        }
    }
}

class LocationProvider: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    var locationHandler: ((CLLocation) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5
    }
    
    func startUpdating() {
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdating() {
        locationManager.stopUpdatingLocation()
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        locationHandler?(location)
    }
}
