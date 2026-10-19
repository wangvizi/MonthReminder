import Foundation
import SwiftUI

/// 小组件 kind，App 与 Widget 共用
let monthWidgetKind = "MonthListWidget"

/// 每月固定日期提醒事件
struct MonthEvent: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var day: Int // 每月几号 1...31
    var colorKey: ColorKey = .green
    var iconKey: IconKey = .ticket

    enum ColorKey: String, Codable, CaseIterable {
        case green, teal, orange, blue, purple

        var base: Color {
            switch self {
            case .green:
                return Color(red: 0.42, green: 0.78, blue: 0.35)
            case .teal:
                return Color(red: 0.45, green: 0.82, blue: 0.76)
            case .orange:
                return Color(red: 0.97, green: 0.64, blue: 0.25)
            case .blue:
                return Color(red: 0.35, green: 0.64, blue: 0.94)
            case .purple:
                return Color(red: 0.64, green: 0.54, blue: 0.90)
            }
        }

        var gradient: LinearGradient {
            LinearGradient(colors: [base, base.opacity(0.82)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
        }

        var label: String {
            switch self {
            case .green: return "绿"
            case .teal: return "青"
            case .orange: return "橙"
            case .blue: return "蓝"
            case .purple: return "紫"
            }
        }
    }

    enum IconKey: String, Codable, CaseIterable {
        case ticket, wallet

        var symbol: String {
            switch self {
            case .ticket: return "ticket.fill"
            case .wallet: return "wallet.pass.fill"
            }
        }
    }
}
