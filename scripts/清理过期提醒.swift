import EventKit
import Foundation

// 删除「训练」列表里到期日早于今天、或已完成的提醒
let store = EKEventStore()
let cal = Calendar.current
let startOfDay = cal.startOfDay(for: Date())

let sem = DispatchSemaphore(value: 0)
var ok = false
store.requestFullAccessToReminders { granted, _ in ok = granted; sem.signal() }
sem.wait()
if !ok { print("ACCESS_DENIED"); exit(1) }

var list: EKCalendar? = nil
for source in store.sources {
    if let c = source.calendars(for: .reminder).first(where: { $0.title == "训练" }) {
        list = c
        break
    }
}
guard let l = list else { print("NO_LIST"); exit(2) }

let sem2 = DispatchSemaphore(value: 0)
var all: [EKReminder] = []
store.fetchReminders(matching: store.predicateForReminders(in: [l])) { rems in
    all = rems ?? []
    sem2.signal()
}
sem2.wait()

var removed = 0
for r in all {
    var isPast = false
    if let comps = r.dueDateComponents, let d = cal.date(from: comps) {
        isPast = d < startOfDay
    }
    if isPast || r.isCompleted {
        try? store.remove(r, commit: false)
        removed += 1
    }
}
try? store.commit()
print("已清理过期提醒 \(removed) 条（原有 \(all.count) 条）")
