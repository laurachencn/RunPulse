import HealthKit
import Foundation

@MainActor
final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    
    private let typesToRead: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.quantityType(forIdentifier: .walkingRunningCadence)!,
        HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        HKObjectType.workoutType()
    ]
    
    private let typesToWrite: Set<HKSampleType> = [
        HKObjectType.workoutType(),
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
    ]
    
    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    func requestAuthorization() async throws {
        guard isHealthKitAvailable else {
            throw HealthKitError.healthDataNotAvailable
        }
        
        try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
        isAuthorized = true
    }
    
    func checkAuthorizationStatus() async {
        var authorized = true
        for type in typesToRead {
            let status = await healthStore.authorizationStatus(for: type)
            if status != .sharingAuthorized {
                authorized = false
                break
            }
        }
        isAuthorized = authorized
    }
}

enum HealthKitError: LocalizedError {
    case healthDataNotAvailable
    case authorizationDenied
    
    var errorDescription: String? {
        switch self {
        case .healthDataNotAvailable:
            return "HealthKit is not available on this device"
        case .authorizationDenied:
            return "HealthKit authorization was denied"
        }
    }
}
