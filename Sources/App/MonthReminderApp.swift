import SwiftUI

@main
struct MonthReminderApp: App {
    @StateObject private var store = EventStore.shared

    var body: some Scene {
        WindowGroup {
            MonthView()
                .environmentObject(store)
        }
    }
}
