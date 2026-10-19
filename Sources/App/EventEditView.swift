import SwiftUI

struct EventEditView: View {
    @EnvironmentObject var store: EventStore
    @Environment(\.dismiss) private var dismiss
    @State private var draft: MonthEvent
    private let isNew: Bool

    init(event: MonthEvent?) {
        let new = event ?? MonthEvent(
            name: "",
            day: Calendar.current.component(.day, from: Date())
        )
        _draft = State(initialValue: new)
        isNew = event == nil
    }

    private var canSave: Bool {
        !draft.name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationView {
            Form {
                Section("名称") {
                    TextField("如：房贷、账单日", text: $draft.name)
                }

                Section("每月日期") {
                    Picker("日期", selection: $draft.day) {
                        ForEach(1...31, id: \.self) { d in
                            Text("\(d)日").tag(d)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                }

                Section("颜色") {
                    HStack(spacing: 16) {
                        ForEach(MonthEvent.ColorKey.allCases, id: \.self) { key in
                            Button {
                                draft.colorKey = key
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(key.base)
                                        .frame(width: 34, height: 34)
                                    if draft.colorKey == key {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("图标") {
                    HStack(spacing: 16) {
                        ForEach(MonthEvent.IconKey.allCases, id: \.self) { key in
                            Button {
                                draft.iconKey = key
                            } label: {
                                Image(systemName: key.symbol)
                                    .font(.system(size: 20))
                                    .foregroundColor(draft.iconKey == key ? draft.colorKey.base : .gray)
                                    .frame(width: 52, height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(draft.iconKey == key
                                                  ? draft.colorKey.base.opacity(0.15)
                                                  : Color.gray.opacity(0.08))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if !isNew {
                    Section {
                        Button(role: .destructive) {
                            store.delete(draft)
                            dismiss()
                        } label: {
                            Text("删除此提醒")
                        }
                    }
                }
            }
            .navigationTitle(isNew ? "添加提醒" : "编辑提醒")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        store.upsert(draft)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}
