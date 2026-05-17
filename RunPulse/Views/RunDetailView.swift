import SwiftUI

struct RunDetailView: View {
    let runSession: RunSession
    @AppStorage("userAge") private var userAge: Int = 30
    
    var alertThreshold: Int {
        Int(Double(220 - userAge) * 0.90)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                statsGrid
                splitsSection
            }
            .padding()
        }
        .navigationTitle("Run Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(runSession.startDate, style: .date)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(runSession.startDate, style: .time)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            statCard(title: "Duration", value: runSession.durationString, icon: "stopwatch")
            statCard(title: "Distance", value: String(format: "%.2f km", runSession.totalDistanceKm), icon: "location.fill")
            statCard(title: "Avg Pace", value: runSession.averagePaceString, icon: "speedometer")
            statCard(title: "Avg HR", value: "\(Int(runSession.averageHeartRate)) BPM", icon: "heart.fill")
            statCard(title: "Max HR", value: "\(Int(runSession.maxHeartRate)) BPM", icon: "heart.fill")
            statCard(title: "Calories", value: "\(Int(runSession.totalCalories))", icon: "flame.fill")
        }
    }
    
    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .scaledToFit()
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var splitsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Kilometer Splits")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            ForEach(runSession.splits) { split in
                HStack {
                    Text("KM \(split.kilometerNumber)")
                        .fontWeight(.medium)
                        .frame(width: 50, alignment: .leading)
                    
                    Spacer()
                    
                    Text(split.paceString)
                        .monospacedDigit()
                    
                    Text("\(Int(split.averageHeartRate)) BPM")
                        .foregroundColor(.pink)
                        .frame(width: 70, alignment: .trailing)
                    
                    if split.maxHeartRate > Double(alertThreshold) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    RunDetailView(runSession: RunSession.newSession())
}
