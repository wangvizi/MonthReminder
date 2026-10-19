import WidgetKit
import SwiftUI

struct MonthWidgetEntry: TimelineEntry {
    let date: Date
    let events: [MonthEvent]
}

struct MonthWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MonthWidgetEntry {
        MonthWidgetEntry(date: Date(), events: EventStore.previewEvents)
    }

    func getSnapshot(in context: Context, completion: @escaping (MonthWidgetEntry) -> Void) {
        let events = EventStore.loadCurrentEvents()
        completion(MonthWidgetEntry(date: Date(),
                                    events: events.isEmpty ? EventStore.previewEvents : events))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MonthWidgetEntry>) -> Void) {
        let now = Date()
        // 每次请求都重新读盘，避免扩展进程复用单例缓存导致“只显示第一次的内容”
        let events = EventStore.loadCurrentEvents()
        // 每小时一个 entry，.atEnd 让系统每小时重新读取，reload 通知丢失时也能自愈并跨零点翻转
        var entries: [MonthWidgetEntry] = []
        for h in 0..<24 {
            let t = h == 0 ? now : (Calendar.current.date(byAdding: .hour, value: h, to: now) ?? now)
            entries.append(MonthWidgetEntry(date: t, events: events))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - 视图

struct MonthWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: MonthWidgetEntry

    private var sorted: [MonthEvent] {
        entry.events.sorted {
            MonthMath.daysRemaining(untilDay: $0.day, from: entry.date) <
            MonthMath.daysRemaining(untilDay: $1.day, from: entry.date)
        }
    }

    var body: some View {
        content
            .widgetBackground(Color(red: 0.97, green: 0.97, blue: 0.98))
    }

    @ViewBuilder
    private var content: some View {
        if sorted.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
                Text("打开 App 添加每月提醒")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                // 临时诊断行：定位 App/Widget 共享通道问题，确认后移除
                Text(EventStore.shared.diagnostic)
                    .font(.system(size: 9))
                    .foregroundColor(.gray.opacity(0.7))
            }
        } else if family == .systemSmall {
            SmallWidgetView(event: sorted[0], date: entry.date)
        } else {
            RowListView(events: Array(sorted.prefix(family == .systemLarge ? 6 : 3)),
                        date: entry.date)
        }
    }
}

/// 小尺寸：最近一条
struct SmallWidgetView: View {
    let event: MonthEvent
    let date: Date

    private var daysLeft: Int { MonthMath.daysRemaining(untilDay: event.day, from: date) }

    var body: some View {
        VStack(spacing: 4) {
            Text(event.name)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
                .lineLimit(1)
            Text("每月\(event.day)日")
                .font(.system(size: 12))
                .foregroundColor(.gray)
            Spacer(minLength: 0)
            if daysLeft == 0 {
                Text("今天")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(.black)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("剩")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text("\(daysLeft)")
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundColor(.black)
                    Text("天")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// 中/大尺寸：列表（名称 / 每月N日 / 剩 N 天）
struct RowListView: View {
    let events: [MonthEvent]
    let date: Date

    var body: some View {
        VStack(spacing: 0) {
            ForEach(events.indices, id: \.self) { i in
                let daysLeft = MonthMath.daysRemaining(untilDay: events[i].day, from: date)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(events[i].name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black)
                            .lineLimit(1)
                        Text("每月\(events[i].day)日")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    if daysLeft == 0 {
                        Text("今天")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(.black)
                    } else {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("剩")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                            Text("\(daysLeft)")
                                .font(.system(size: 28, weight: .heavy))
                                .foregroundColor(.black)
                            Text("天")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.vertical, 7)
                if i < events.count - 1 {
                    Divider()
                }
            }
            Spacer(minLength: 0)
        }
    }
}

extension View {
    @ViewBuilder
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(for: .widget) { color }
        } else {
            // iOS 17 以下系统不会自动加内容边距，这里手动补齐，避免文字贴边
            self.padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(color)
        }
    }
}

// MARK: - Widget 声明

struct MonthListWidget: Widget {
    let kind: String = monthWidgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MonthWidgetProvider()) { entry in
            MonthWidgetView(entry: entry)
        }
        .configurationDisplayName("每月提醒")
        .description("查看每月固定日期还剩几天")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct MonthWidgetBundle: WidgetBundle {
    var body: some Widget {
        MonthListWidget()
    }
}
