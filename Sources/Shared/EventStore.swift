import Foundation
import SwiftUI
#if canImport(WidgetKit)
import WidgetKit
#endif

/// App 与 Widget 共用的数据存储（App Group）
/// 双通道写入：UserDefaults suite + 共享容器文件，任一通道可用即可互通
final class EventStore: ObservableObject {
    static let appGroupID = "group.com.indie.monthremind"
    static let shared = EventStore()
    private static let storageKey = "month.events.v1"
    private static let fileName = "events.json"

    @Published var events: [MonthEvent] = [] {
        didSet { persist() }
    }

    /// 诊断信息：widget 空态时显示，便于定位共享通道是否可用
    let diagnostic: String

    private let defaults: UserDefaults?

    private var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupID)?
            .appendingPathComponent(Self.fileName)
    }

    init() {
        let d = UserDefaults(suiteName: Self.appGroupID)
        defaults = d

        let suiteBytes = d?.data(forKey: Self.storageKey)?.count ?? -1
        let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupID)?
            .appendingPathComponent(Self.fileName)
        let fileBytes = (url.flatMap { try? Data(contentsOf: $0) })?.count ?? -1

        let loaded = Self.load(defaults: d, fileURL: url)
        diagnostic = "suite=\(d == nil ? "nil" : "ok")/\(suiteBytes)B file=\(fileBytes)B n=\(loaded?.count ?? 0)"
        events = loaded ?? []
    }

    private static func load(defaults d: UserDefaults?, fileURL: URL?) -> [MonthEvent]? {
        let decoder = JSONDecoder()
        if let d, let data = d.data(forKey: storageKey),
           let v = try? decoder.decode([MonthEvent].self, from: data) {
            return v
        }
        if let url = fileURL, let data = try? Data(contentsOf: url),
           let v = try? decoder.decode([MonthEvent].self, from: data) {
            return v
        }
        return nil
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
        let data = try? JSONEncoder().encode(events)
        defaults?.set(data, forKey: Self.storageKey)
        if let url = fileURL {
            try? data?.write(to: url, options: .atomic)
        }
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    /// 小组件占位预览数据
    static let previewEvents: [MonthEvent] = [
        MonthEvent(name: "房贷", day: 10, colorKey: .green, iconKey: .ticket),
        MonthEvent(name: "信用卡账单", day: 22, colorKey: .teal, iconKey: .wallet),
        MonthEvent(name: "水电费", day: 5, colorKey: .orange, iconKey: .ticket)
    ]
}
