import Foundation

@MainActor
final class StorageManager: ObservableObject {
    static let shared = StorageManager()
    
    @Published var savedRuns: [RunSession] = []
    
    private let fileManager = FileManager.default
    private var runsURL: URL {
        let directory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent("RunPulseRuns")
    }
    
    init() {
        loadRuns()
    }
    
    func saveRun(_ run: RunSession) async {
        do {
            if !fileManager.fileExists(atPath: runsURL.path) {
                try fileManager.createDirectory(at: runsURL, withIntermediateDirectories: true)
            }
            
            let fileURL = runsURL.appendingPathComponent("\(run.id.uuidString).json")
            let data = try JSONEncoder().encode(run)
            try data.write(to: fileURL)
            
            await loadRuns()
        } catch {
            print("Failed to save run: \(error)")
        }
    }
    
    func loadRuns() async {
        do {
            guard fileManager.fileExists(atPath: runsURL.path) else {
                savedRuns = []
                return
            }
            
            let files = try fileManager.contentsOfDirectory(at: runsURL, includingPropertiesForKeys: nil)
            var runs: [RunSession] = []
            
            for file in files where file.pathExtension == "json" {
                let data = try Data(contentsOf: file)
                let run = try JSONDecoder().decode(RunSession.self, from: data)
                runs.append(run)
            }
            
            savedRuns = runs.sorted { $0.startDate > $1.startDate }
        } catch {
            print("Failed to load runs: \(error)")
            savedRuns = []
        }
    }
    
    func deleteRun(_ run: RunSession) async {
        let fileURL = runsURL.appendingPathComponent("\(run.id.uuidString).json")
        do {
            try fileManager.removeItem(at: fileURL)
            await loadRuns()
        } catch {
            print("Failed to delete run: \(error)")
        }
    }
}
