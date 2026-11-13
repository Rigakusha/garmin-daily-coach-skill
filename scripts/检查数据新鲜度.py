#!/usr/bin/env python3
"""Garmin 数据新鲜度检查。

用法：
  python3 检查数据新鲜度.py <今天YYYY-MM-DD> <睡眠记录date> <准备度timestampLocal> <HRV最后一条calendarDate> [<HRV最后一条createTimeStamp>]

全部是今天 → 输出 OK；否则输出 STALE 并列出问题，提示同步手表。
"""
import os
import sys
from datetime import datetime, timezone, timedelta


def main() -> int:
    if len(sys.argv) < 5:
        print("用法: 检查数据新鲜度.py <今天> <sleep.date> <readiness.timestampLocal> <hrv.date> [<hrv.createTimeStamp>]")
        return 2

    today = sys.argv[1].strip()
    sleep_date = sys.argv[2].strip()
    readiness_local = sys.argv[3].strip()
    hrv_date = sys.argv[4].strip()
    hrv_created = sys.argv[5].strip() if len(sys.argv) > 5 else ""

    issues = []

    if not sleep_date or sleep_date == "None":
        issues.append("没有今天的睡眠记录（可能手表未同步）")
    elif sleep_date != today:
        issues.append(f"睡眠记录日期是 {sleep_date}，不是今天 {today}")

    if not readiness_local.startswith(today):
        issues.append(f"准备度更新时间是 {readiness_local or '空'}，不是今天")

    if not hrv_date or hrv_date == "None":
        issues.append("没有今天的 HRV 记录")
    elif hrv_date != today:
        issues.append(f"HRV 日期是 {hrv_date}，不是今天 {today}")

    if hrv_created:
        try:
            # 时区偏移（小时）：默认 +8（北京时间）。其他时区设环境变量 HR_TZ_OFFSET，如 HR_TZ_OFFSET=9。
            tz_offset = float(os.environ.get('HR_TZ_OFFSET', '8'))
            utc = datetime.fromisoformat(hrv_created.replace("Z", "+00:00")).replace(tzinfo=timezone.utc)
            local = utc.astimezone(timezone(timedelta(hours=tz_offset)))
            if local.strftime("%Y-%m-%d") != today:
                issues.append(f"HRV 生成时间是 {local.strftime('%Y-%m-%d %H:%M')}（UTC+{tz_offset:g}），不是今天早上")
        except ValueError:
            pass

    if issues:
        print("STALE")
        for i in issues:
            print(" -", i)
        print("→ 请打开 Garmin Connect App 下拉同步手表，然后告诉我，我重读。")
        return 1

    print("OK 数据是今天的（睡眠 / 准备度 / HRV 都对得上）")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
