import SwiftUI
import WidgetKit

@main
struct MonthReminderApp: App {
    @StateObject private var store = EventStore.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            MonthView()
                .environmentObject(store)
        }
        .onChange(of: scenePhase) { phase in
            // 回到前台时兜底刷新小组件，防止个别环境下 reload 通知丢失
            if phase == .active {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}
