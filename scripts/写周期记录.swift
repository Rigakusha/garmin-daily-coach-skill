import EventKit
import Foundation

// 用法: swift 写周期记录.swift <日期YYYY-MM-DD> <标题> <正文>
// 在「训练日志」日历里写一条全天事件，作为周期时间线标记（块收官摘要 / 启动标记）。
let args = CommandLine.arguments
guard args.count >= 4 else {
    print("usage: 写周期记录.swift <日期YYYY-MM-DD> <标题> <正文>")
    exit(2)
}
let dateStr = args[1]
let title = args[2]
let body = args[3]

let df = DateFormatter()
df.dateFormat = "yyyy-MM-dd"
df.timeZone = TimeZone.current
guard let day = df.date(from: dateStr) else { print("BAD_DATE"); exit(2) }

let store = EKEventStore()
let sem = DispatchSemaphore(value: 0)
var granted = false
store.requestFullAccessToEvents { ok, _ in granted = ok; sem.signal() }
sem.wait()
if !granted { print("ACCESS_DENIED"); exit(1) }

var target: EKCalendar? = nil
for source in store.sources where source.sourceType == .calDAV {
    if let c = source.calendars(for: .event).first(where: { $0.title == "训练日志" }) {
        target = c
        break
    }
}
guard let logCal = target else { print("NO_CAL"); exit(2) }

let cal0 = Calendar.current
let startOfDay = cal0.startOfDay(for: day)
let endOfDay = cal0.date(byAdding: .day, value: 1, to: startOfDay)!

// 幂等：同一天同标题的旧记录先删掉，避免重复
let pred = store.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: [logCal])
for ev in store.events(matching: pred) where ev.title == title {
    try? store.remove(ev, span: .thisEvent, commit: true)
}

let ev = EKEvent(eventStore: store)
ev.calendar = logCal
ev.title = title
ev.isAllDay = true
ev.startDate = startOfDay
ev.endDate = endOfDay
ev.notes = body
do { try store.save(ev, span: .thisEvent, commit: true) } catch { print("SAVE_FAIL \(error)"); exit(3) }
print("OK \(title) @ \(dateStr)")
