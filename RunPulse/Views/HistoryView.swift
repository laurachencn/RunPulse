import SwiftUI

struct HistoryView: View {
    @StateObject private var storageManager = StorageManager.shared
    
    var body: some View {
        NavigationView {
            Group {
                if storageManager.savedRuns.isEmpty {
                    emptyState
                } else {
                    runList
                }
            }
            .navigationTitle("Run History")
            .task {
                await storageManager.loadRuns()
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No Runs Yet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Start a run on your Apple Watch to see it here.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var runList: some View {
        List(storageManager.savedRuns) { session in
            NavigationLink(destination: RunDetailView(runSession: session)) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(session.startDate, style: .date)
                            .font(.headline)
                        Spacer()
                        Text(session.durationString)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label(String(format: "%.2f km", session.totalDistanceKm), systemImage: "location.fill")
                        Spacer()
                        Label(session.averagePaceString + "/km", systemImage: "speedometer")
                        Spacer()
                        Label("\(Int(session.averageHeartRate)) BPM", systemImage: "heart.fill")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
    }
}

#Preview {
    HistoryView()
}
