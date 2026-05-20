import Foundation

enum DistanceInterval: Double, Codable, CaseIterable {
    case kmHalf = 0.5
    case km1 = 1.0
    case km2 = 2.0
    case km5 = 5.0
    
    var displayString: String {
        switch self {
        case .kmHalf: return "0.5 km"
        case .km1: return "1 km"
        case .km2: return "2 km"
        case .km5: return "5 km"
        }
    }
}

enum TimeIntervalInterval: Int, Codable, CaseIterable {
    case off = 0
    case min1 = 60
    case min5 = 300
    case min10 = 600
    case min15 = 900
    
    var displayString: String {
        switch self {
        case .off: return "Off"
        case .min1: return "1 min"
        case .min5: return "5 min"
        case .min10: return "10 min"
        case .min15: return "15 min"
        }
    }
}

struct AudioCueConfig: Codable, Equatable {
    var voiceEnabled: Bool
    var announcePace: Bool
    var announceHeartRate: Bool
    var announceDistance: Bool
    var announceCalories: Bool
    var distanceInterval: DistanceInterval
    var timeInterval: TimeIntervalInterval
    
    static let `default` = AudioCueConfig(
        voiceEnabled: true,
        announcePace: true,
        announceHeartRate: true,
        announceDistance: true,
        announceCalories: false,
        distanceInterval: .km1,
        timeInterval: .off
    )
}
