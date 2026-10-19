# 月月提醒 (MonthReminder)

仿「时光提醒」的“月”功能：每月固定日期提醒 + 桌面小组件。

## 功能
- App 主界面：圆形月历盘（日期环、事件气泡、本月已过百分比指针）+ 双列事件卡片（N天后 / 名称 / 每月N日）+ 添加/编辑/删除
- 桌面小组件（WidgetKit，小/中/大三档）：列表显示「名称 / 每月N日 / 剩 N 天」，长按桌面 → 添加小组件 → 搜索「月月提醒」
- App 与小组件通过 App Group (`group.com.indie.monthremind`) 共享数据

## 云端构建 IPA（无需 Mac）
1. 推送到 GitHub 后，Actions 会自动运行 `.github/workflows/build-ipa.yml`（macOS runner + XcodeGen + xcodebuild）
2. 在仓库 Actions 页面打开对应 run，下载产物 `MonthReminder-ipa` 即得到 `MonthReminder.ipa`
3. 也可手动触发：Actions → Build IPA → Run workflow

## 安装说明
- IPA 为 ad-hoc 签名（含 App Group entitlements）：
  - 越狱设备 / TrollStore：可直接安装，小组件数据互通正常
  - AltStore / Sideloadly 等重签名工具：可以安装，但免费个人证书不含 App Group 权限，重签后小组件可能读不到 App 内数据（显示“打开 App 添加每月提醒”）
- 有 Mac 的话：`brew install xcodegen && xcodegen generate` 后用 Xcode 打开，选择自己的 Team 签名真机运行，小组件功能完整

## 工程结构
- `Sources/App`：App 主界面（SwiftUI）
- `Sources/Widget`：WidgetKit 小组件
- `Sources/Shared`：数据模型 / 存储 / 日期计算（双 target 共用）
- `Config/`：Info.plist 与 App Group entitlements
- `project.yml`：XcodeGen 工程描述
