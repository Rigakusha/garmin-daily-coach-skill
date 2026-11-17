import EventKit
import Foundation

// 用法: swift 写今日日程.swift <标题> <开始小时> <开始分钟> <时长分钟> <备注> [<附加标题> <附加开始小时> <附加开始分钟> <附加时长分钟>]
// 主事件 + 可选的附加事件（如训练后的「清水洗脸」）一次写入，自动清理当天旧事件。
let args = CommandLine.arguments
guard args.count >= 6 else {
    print("usage: 写今日日程.swift <标题> <时> <分> <时长min> <备注> [<附加标题> <时> <分> <时长min>]")
    exit(2)
}
let title = args[1]
let hour = Int(args[2]) ?? 19
let minute = Int(args[3]) ?? 30
let durationMin = Int(args[4]) ?? 40
let notes = args[5]

let hasExtra = args.count >= 10
let extraTitle = hasExtra ? args[6] : ""
let extraHour = hasExtra ? (Int(args[7]) ?? 20) : 0
let extraMinute = hasExtra ? (Int(args[8]) ?? 10) : 0
let extraDuration = hasExtra ? (Int(args[9]) ?? 5) : 0

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

func makeEvent(title: String, hour: Int, minute: Int, durationMin: Int, notes: String) throws {
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
    try store.save(ev, span: .thisEvent, commit: true)
    print("OK \(title) @ \(start) - \(end)")
}

do {
    try makeEvent(title: title, hour: hour, minute: minute, durationMin: durationMin, notes: notes)
    if hasExtra {
        try makeEvent(title: extraTitle, hour: extraHour, minute: extraMinute, durationMin: extraDuration, notes: "")
    }
} catch { print("SAVE_FAIL \(error)"); exit(3) }
