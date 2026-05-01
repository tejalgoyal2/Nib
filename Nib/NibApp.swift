import SwiftUI

@main
struct NibApp: App {
    @State private var storage = StorageService()

    var body: some Scene {
        MenuBarExtra("Nib", systemImage: "pencil.tip") {
            ScratchpadView()
                .environment(storage)
        }
        .menuBarExtraStyle(.window)
    }
}
