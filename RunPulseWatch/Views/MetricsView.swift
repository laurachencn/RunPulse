import SwiftUI

struct MetricsView: View {
    let splits: [KilometerSplit]
    @AppStorage("alertThreshold") private var alertThreshold: Int = 171
    
    var body: some View {
        List(splits) { split in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("KM \(split.kilometerNumber)")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(split.paceString)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Label("\(Int(split.averageHeartRate)) BPM", systemImage: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.pink)
                    
                    Spacer()
                    
                    if split.maxHeartRate > Double(alertThreshold) {
                        Label("High", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Splits")
    }
}

#Preview {
    MetricsView(splits: [
        KilometerSplit(
            id: UUID(),
            kilometerNumber: 1,
            duration: 300,
            averageHeartRate: 145,
            maxHeartRate: 155,
            minHeartRate: 135,
            pace: 300,
            distance: 1000,
            calories: 50,
            timestamp: Date()
        )
    ])
}
