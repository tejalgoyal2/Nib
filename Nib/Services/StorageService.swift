import Foundation

@MainActor
@Observable
final class StorageService {
    var text: String = "" {
        didSet {
            guard !isLoading else { return }
            scheduleSave()
        }
    }

    private let fileURL: URL
    @ObservationIgnored private var isLoading = false
    @ObservationIgnored private var saveTask: Task<Void, Never>?

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let nibDir = appSupport.appendingPathComponent("Nib")
        fileURL = nibDir.appendingPathComponent("scratchpad.json")
        try? FileManager.default.createDirectory(at: nibDir, withIntermediateDirectories: true)
        load()
    }

    private struct Scratchpad: Codable {
        var content: String
        var lastModified: Date
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode(Scratchpad.self, from: data)
            isLoading = true
            text = decoded.content
            isLoading = false
        } catch {
            print("Nib: load failed: \(error)")
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(500))
                save()
            } catch {
                // Cancelled — a newer keystroke will schedule its own save
            }
        }
    }

    private func save() {
        do {
            let encoded = try JSONEncoder().encode(
                Scratchpad(content: text, lastModified: Date())
            )
            try encoded.write(to: fileURL, options: .atomic)
        } catch {
            print("Nib: save failed: \(error)")
        }
    }
}
