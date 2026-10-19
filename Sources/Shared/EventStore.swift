import Foundation
import SwiftUI
#if canImport(WidgetKit)
import WidgetKit
#endif

/// App 与 Widget 共用的数据存储（App Group）
final class EventStore: ObservableObject {
    static let appGroupID = "group.com.indie.monthremind"
    static let shared = EventStore()
    private static let storageKey = "month.events.v1"

    @Published var events: [MonthEvent] = [] {
        didSet { persist() }
    }

    private let defaults: UserDefaults

    init() {
        defaults = UserDefaults(suiteName: Self.appGroupID) ?? .standard
        if let data = defaults.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([MonthEvent].self, from: data) {
            events = decoded
        }
    }

    func upsert(_ event: MonthEvent) {
        if let i = events.firstIndex(where: { $0.id == event.id }) {
            events[i] = event
        } else {
            events.append(event)
        }
    }

    func delete(_ event: MonthEvent) {
        events.removeAll { $0.id == event.id }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(events) {
            defaults.set(data, forKey: Self.storageKey)
        }
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: monthWidgetKind)
        #endif
    }

    /// 小组件占位预览数据
    static let previewEvents: [MonthEvent] = [
        MonthEvent(name: "房贷", day: 10, colorKey: .green, iconKey: .ticket),
        MonthEvent(name: "信用卡账单", day: 22, colorKey: .teal, iconKey: .wallet),
        MonthEvent(name: "水电费", day: 5, colorKey: .orange, iconKey: .ticket)
    ]
}
