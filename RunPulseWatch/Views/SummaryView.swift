import SwiftUI

struct SummaryView: View {
    let runSession: RunSession?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
                
                Text("Workout Complete!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                summaryStats
                
                if let session = runSession, !session.splits.isEmpty {
                    Text("Splits")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ForEach(session.splits) { split in
                        splitRow(split)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Summary")
    }
    
    private var summaryStats: some View {
        Group {
            HStack {
                statCard(title: "Distance", value: runSession?.totalDistanceKmString ?? "0.00 km")
                statCard(title: "Duration", value: runSession?.durationString ?? "0:00")
            }
            
            HStack {
                statCard(title: "Avg Pace", value: runSession?.averagePaceString ?? "0:00")
                statCard(title: "Avg HR", value: "\(Int(runSession?.averageHeartRate ?? 0)) BPM")
            }
        }
    }
    
    private func statCard(title: String, value: String) -> some View {
        VStack {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
    
    private func splitRow(_ split: KilometerSplit) -> some View {
        HStack {
            Text("KM \(split.kilometerNumber)")
                .fontWeight(.medium)
            Spacer()
            Text(split.paceString)
            Text("\(Int(split.averageHeartRate)) BPM")
                .foregroundColor(.pink)
        }
        .font(.caption)
        .padding(.vertical, 2)
    }
}

extension RunSession {
    var totalDistanceKmString: String {
        String(format: "%.2f km", totalDistanceKm)
    }
}

#Preview {
    SummaryView(runSession: RunSession.newSession())
}
