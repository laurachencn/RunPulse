import SwiftUI

struct AudioCuesSection: View {
    @AppStorage("audioCueVoiceEnabled") private var voiceEnabled = AudioCueConfig.default.voiceEnabled
    @AppStorage("audioCueAnnouncePace") private var announcePace = AudioCueConfig.default.announcePace
    @AppStorage("audioCueAnnounceHR") private var announceHR = AudioCueConfig.default.announceHeartRate
    @AppStorage("audioCueAnnounceDistance") private var announceDistance = AudioCueConfig.default.announceDistance
    @AppStorage("audioCueAnnounceCalories") private var announceCalories = AudioCueConfig.default.announceCalories
    @AppStorage("audioCueDistanceInterval") private var distanceIntervalRaw = AudioCueConfig.default.distanceInterval.rawValue
    @AppStorage("audioCueTimeInterval") private var timeIntervalRaw = AudioCueConfig.default.timeInterval.rawValue
    
    var body: some View {
        Section(header: Text("Audio Cues")) {
            Toggle("Enable Audio Cues", isOn: $voiceEnabled)
            Text("Spoken announcements during runs")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        
        Section(header: Text("Announcement Types")) {
            Toggle("Pace", isOn: $announcePace)
            Text("Announce current pace")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Toggle("Heart Rate", isOn: $announceHR)
            Text("Announce current heart rate")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Toggle("Distance Milestones", isOn: $announceDistance)
            Text("Announce at distance intervals")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Toggle("Calories", isOn: $announceCalories)
            Text("Announce calories burned")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        
        Section(header: Text("Announcement Frequency")) {
            Picker("Distance Interval", selection: $distanceIntervalRaw) {
                ForEach(DistanceInterval.allCases, id: \.self) { interval in
                    Text(interval.displayString).tag(interval.rawValue)
                }
            }
            
            Picker("Time Interval", selection: $timeIntervalRaw) {
                ForEach(TimeIntervalInterval.allCases, id: \.self) { interval in
                    Text(interval.displayString).tag(interval.rawValue)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        Form {
            AudioCuesSection()
        }
    }
}
