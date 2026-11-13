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
        '通用 Garmin 教练：读取 Garmin 原始数据（睡眠/HRV/晨脉/负荷/活动）+ 训练日志日历，用五信号评级综合裁决（不照搬 Garmin 结论），输出当日训练处方并写入 Mac 日历与提醒事项；也处理周复盘/月复盘。当用户说「今天训练计划」「今天练什么」「周复盘」「月复盘」时使用。首次使用请先运行本技能目录下的 setup.sh。',
      source: 'runtime',
      content,
      resourceBase: { kind: 'directory', path: base },
      invocation: { modelInvocable: true, userInvocable: true },
    })
  })
}
