import SwiftUI

struct MonthView: View {
    @EnvironmentObject var store: EventStore
    @State private var now = Date()
    @State private var editing: MonthEvent?
    @State private var showingAdd = false
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var sortedEvents: [MonthEvent] {
        store.events.sorted {
            MonthMath.daysRemaining(untilDay: $0.day, from: now) <
            MonthMath.daysRemaining(untilDay: $1.day, from: now)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                MonthDial(now: now, events: store.events)
                    .frame(height: 340)
                    .padding(.top, 8)

                if store.events.isEmpty {
                    Text("还没有每月提醒，点击下方 + 添加")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)],
                          spacing: 12) {
                    ForEach(sortedEvents) { event in
                        EventCard(event: event,
                                  daysLeft: MonthMath.daysRemaining(untilDay: event.day, from: now))
                            .onTapGesture { editing = event }
                    }
                    AddCard { showingAdd = true }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 24)
        }
        .background(Color(red: 0.96, green: 0.97, blue: 0.97).ignoresSafeArea())
        .onReceive(timer) { now = $0 }
        .sheet(item: $editing) { event in
            EventEditView(event: event).environmentObject(store)
        }
        .sheet(isPresented: $showingAdd) {
            EventEditView(event: nil).environmentObject(store)
        }
    }
}

// MARK: - 月相圆盘

struct MonthDial: View {
    let now: Date
    let events: [MonthEvent]

    private var dim: Int { MonthMath.daysInMonth(containing: now) }
    private var today: Int { Calendar.current.component(.day, from: now) }

    private func angle(for day: Int) -> Double {
        (Double(day - 1) / Double(dim)) * 2 * .pi - .pi / 2
    }

    private func point(center: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
        let ca = cos(angle)
        let sa = sin(angle)
        return CGPoint(x: center.x + ca * radius,
                       y: center.y + sa * radius)
    }

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2 - 46
            let todayAngle = angle(for: today)
            let groups = Dictionary(grouping: events, by: \.day)

            ZStack {
                // 日期环
                Canvas { context, size in
                    let c = CGPoint(x: size.width / 2, y: size.height / 2)
                    for day in 1...dim {
                        let pt = point(center: c, radius: radius, angle: angle(for: day))
                        let passed = day <= today
                        let text = Text("\(day)")
                            .font(.system(size: day == today ? 20 : 17, weight: .bold))
                            .foregroundColor(passed ? Color.black.opacity(0.85) : Color.black.opacity(0.15))
                        context.draw(text, at: pt)
                    }
                }

                // 指针：中心指向今天
                NeedleShape(angle: todayAngle, inner: 26, outer: radius * 0.9)
                    .stroke(Color.black.opacity(0.85),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round))
                Circle()
                    .fill(Color.black.opacity(0.85))
                    .frame(width: 11, height: 11)
                    .position(point(center: center, radius: 26, angle: todayAngle))

                // 中心：本月已过 x%
                VStack(spacing: 2) {
                    Text("本月已过")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text("\(Int(MonthMath.monthProgress(at: now) * 100))%")
                        .font(.system(size: 44, weight: .heavy))
                        .foregroundColor(.black)
                }
                .position(x: center.x, y: center.y - 34)

                // 事件气泡
                ForEach(events) { event in
                    let idx = groups[event.day]?.firstIndex(where: { $0.id == event.id }) ?? 0
                    let a = angle(for: min(max(event.day, 1), dim))
                    Circle()
                        .fill(event.colorKey.base)
                        .frame(width: 7, height: 7)
                        .position(point(center: center, radius: radius + 12 + CGFloat(idx) * 24, angle: a))
                    Text(event.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(event.colorKey.base))
                        .shadow(color: event.colorKey.base.opacity(0.4), radius: 4, y: 2)
                        .position(point(center: center, radius: radius + 34 + CGFloat(idx) * 24, angle: a))
                }
            }
        }
    }
}

struct NeedleShape: Shape {
    let angle: Double
    let inner: CGFloat
    let outer: CGFloat

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let ca = cos(angle)
        let sa = sin(angle)
        var p = Path()
        p.move(to: CGPoint(x: c.x + ca * inner, y: c.y + sa * inner))
        p.addLine(to: CGPoint(x: c.x + ca * outer, y: c.y + sa * outer))
        return p
    }
}

// MARK: - 卡片

struct EventCard: View {
    let event: MonthEvent
    let daysLeft: Int

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(event.colorKey.gradient)

            Text("\(daysLeft)天后")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(event.colorKey.base)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.white))
                .padding(10)

            VStack(spacing: 6) {
                Image(systemName: event.iconKey.symbol)
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                Text(event.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text("每月\(event.day)日")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 36)
            .padding(.bottom, 16)
        }
        .frame(height: 148)
    }
}

struct AddCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                .foregroundColor(Color.gray.opacity(0.45))
                .background(
                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(Color.gray.opacity(0.55))
                )
                .frame(height: 148)
        }
        .buttonStyle(.plain)
    }
}
