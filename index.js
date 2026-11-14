import { readFileSync } from 'node:fs'
import { dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

const base = dirname(fileURLToPath(import.meta.url))

const content = readFileSync(new URL('./SKILL.md', import.meta.url), 'utf8')
  .replace(/^---\n[\s\S]*?\n---\n?/, '')
  .trim()

export default function (ctx) {
  // 硬依赖注入：等待 skills 服务就绪后再注册，避免启动阶段取不到服务而静默跳过。
  return ctx.inject(['skills'], (skills) => {
    return skills.register({
      name: 'garmin-coach',
      description:
        'Garmin 训练教练。用户消息以「garmin」开头时必须使用本技能（如「garmin 今天训练计划」「garmin 下雨不跑了」「garmin 周复盘」）。读取 Garmin 原始数据与训练日志，五信号评级出当日处方并写日历与提醒；处理复盘、下雨改计划、进度更新。首次使用先运行 setup.sh。',
      source: 'runtime',
      content,
      resourceBase: { kind: 'directory', path: base },
      invocation: { modelInvocable: true, userInvocable: true },
    })
  })
}
