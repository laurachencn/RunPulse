import SwiftUI

struct SettingsView: View {
    @AppStorage("userAge") private var userAge: Int = 30
    @AppStorage("userWeight") private var userWeight: Double = 70.0
    @AppStorage("userHeight") private var userHeight: Double = 175.0
    @AppStorage("restingHeartRate") private var restingHeartRate: Int = 60
    @AppStorage("useCustomMaxHR") private var useCustomMaxHR: Bool = false
    @AppStorage("customMaxHR") private var customMaxHR: Int = 190
    
    var calculatedMaxHR: Int {
        220 - userAge
    }
    
    var alertThreshold: Int {
        Int(Double(activeMaxHR) * 0.90)
    }
    
    var activeMaxHR: Int {
        useCustomMaxHR ? customMaxHR : calculatedMaxHR
    }
    
    var body: some View {
        Form {
            Section(header: Text("Profile")) {
                Stepper("Age: \(userAge)", value: $userAge, in: 18...100)
                Stepper("Weight: \(userWeight, specifier: "%.1f") kg", value: $userWeight, in: 30...200, step: 0.5)
                Stepper("Height: \(userHeight, specifier: "%.0f") cm", value: $userHeight, in: 100...250, step: 1)
                Stepper("Resting HR: \(restingHeartRate) BPM", value: $restingHeartRate, in: 40...100)
            }
            
            Section(header: Text("Heart Rate Zones")) {
                Toggle("Use Custom Max HR", isOn: $useCustomMaxHR)
                
                if useCustomMaxHR {
                    Stepper("Max HR: \(customMaxHR) BPM", value: $customMaxHR, in: 120...220)
                } else {
                    HStack {
                        Text("Calculated Max HR")
                        Spacer()
                        Text("\(calculatedMaxHR) BPM")
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                HStack {
                    Text("Alert Threshold (90%)")
                    Spacer()
                    Text("\(alertThreshold) BPM")
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                }
            }
            
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: alertThreshold) { _, newValue in
            WatchSessionManager.shared.sendSettingsUpdate(threshold: newValue)
        }
    }
}

#Preview {
    SettingsView()
}
