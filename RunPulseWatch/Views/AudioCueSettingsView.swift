import SwiftUI

struct AudioCueSettingsView: View {
    @AppStorage("audioCueVoiceEnabled") private var voiceEnabled = AudioCueConfig.default.voiceEnabled
    @AppStorage("audioCueAnnouncePace") private var announcePace = AudioCueConfig.default.announcePace
    @AppStorage("audioCueAnnounceHR") private var announceHR = AudioCueConfig.default.announceHeartRate
    @AppStorage("audioCueAnnounceDistance") private var announceDistance = AudioCueConfig.default.announceDistance
    @AppStorage("audioCueAnnounceCalories") private var announceCalories = AudioCueConfig.default.announceCalories
    @AppStorage("audioCueDistanceInterval") private var distanceIntervalRaw = AudioCueConfig.default.distanceInterval.rawValue
    @AppStorage("audioCueTimeInterval") private var timeIntervalRaw = AudioCueConfig.default.timeInterval.rawValue
    
    var distanceInterval: DistanceInterval {
        get { DistanceInterval(rawValue: distanceIntervalRaw) ?? .km1 }
        set { distanceIntervalRaw = newValue.rawValue }
    }
    
    var timeInterval: TimeIntervalInterval {
        get { TimeIntervalInterval(rawValue: timeIntervalRaw) ?? .off }
        set { timeIntervalRaw = newValue.rawValue }
    }
    
    var body: some View {
        Form {
            Section {
                Toggle("Voice Cues", isOn: $voiceEnabled)
            }
            
            Section("Announcements") {
                Toggle("Pace", isOn: $announcePace)
                Toggle("Heart Rate", isOn: $announceHR)
                Toggle("Distance", isOn: $announceDistance)
                Toggle("Calories", isOn: $announceCalories)
            }
            
            Section("Frequency") {
                Picker("Distance", selection: $distanceIntervalRaw) {
                    ForEach(DistanceInterval.allCases, id: \.self) { interval in
                        Text(interval.displayString).tag(interval.rawValue)
                    }
                }
                
                Picker("Time", selection: $timeIntervalRaw) {
                    ForEach(TimeIntervalInterval.allCases, id: \.self) { interval in
                        Text(interval.displayString).tag(interval.rawValue)
                    }
                }
            }
        }
        .navigationTitle("Audio Cues")
    }
}

#Preview {
    AudioCueSettingsView()
}
