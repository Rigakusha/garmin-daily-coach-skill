import EventKit
import Foundation

// 用法: swift 写今日日程.swift <标题> <开始小时> <开始分钟> <时长分钟> <备注>
let args = CommandLine.arguments
guard args.count >= 6 else {
    print("usage: 写今日日程.swift <标题> <开始小时> <开始分钟> <时长分钟> <备注>")
    exit(2)
}
let title = args[1]
let hour = Int(args[2]) ?? 19
let minute = Int(args[3]) ?? 30
let durationMin = Int(args[4]) ?? 40
let notes = args[5]

let store = EKEventStore()
let sem = DispatchSemaphore(value: 0)
var granted = false
store.requestFullAccessToEvents { ok, _ in granted = ok; sem.signal() }
sem.wait()
if !granted { print("ACCESS_DENIED"); exit(1) }

var target: EKCalendar? = nil
for source in store.sources where source.sourceType == .calDAV {
    if let c = source.calendars(for: .event).first(where: { $0.title == "训练日程" }) {
        target = c
        break
    }
}
guard let schedCal = target else { print("NO_CAL"); exit(2) }

let cal0 = Calendar.current
let startOfDay = cal0.startOfDay(for: Date())
let endOfDay = cal0.date(byAdding: .day, value: 1, to: startOfDay)!
let pred = store.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: [schedCal])
for ev in store.events(matching: pred) {
    try? store.remove(ev, span: .thisEvent, commit: true)
}

var comps = cal0.dateComponents([.year, .month, .day], from: Date())
comps.hour = hour
comps.minute = minute
comps.second = 0
let start = cal0.date(from: comps)!
let end = start.addingTimeInterval(TimeInterval(durationMin * 60))

let ev = EKEvent(eventStore: store)
ev.calendar = schedCal
ev.title = title
ev.startDate = start
ev.endDate = end
ev.notes = notes
do { try store.save(ev, span: .thisEvent, commit: true) } catch { print("SAVE_FAIL \(error)"); exit(3) }
print("OK \(title) @ \(start) - \(end)")
