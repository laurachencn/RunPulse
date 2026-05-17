import SwiftUI

struct HistoryView: View {
    @StateObject private var storageManager = StorageManager.shared
    
    var body: some View {
        Group {
            if storageManager.savedRuns.isEmpty {
                emptyState
            } else {
                runList
            }
        }
        .navigationTitle("Run History")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await storageManager.loadRuns()
        }
        .navigationDestination(for: RunSession.self) { session in
            RunDetailView(runSession: session)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No Runs Yet")
                .font(.title3)
                .fontWeight(.bold)
            
            Text("Start a run on your Apple Watch to see it here.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var runList: some View {
        List(storageManager.savedRuns) { session in
            NavigationLink(value: session) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(session.startDate, style: .date)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(session.durationString)
                            .font(.caption)
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
