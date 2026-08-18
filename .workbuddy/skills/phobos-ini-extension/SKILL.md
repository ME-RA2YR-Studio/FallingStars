---
name: phobos-ini-extension
description: 为 RA2/YR 扩展（Phobos/Ares 风格或 FallingStars）新增 INI 键与扩展逻辑的规范，含语法、合法取值、默认值、作用对象/类型，以及必须同步更新的文档文件。This skill should be used when adding a new INI key, documenting an INI statement, or writing the accompanying docs (New-or-Enhanced-Logics.md, Whats-New.md, CREDITS.md).
agent_created: true
---

# INI 键扩展与文档化规范

## Overview

新增功能常通过 INI 配置暴露。本技能给出"实现 + 文档"双交付规范，确保使用者拿到功能时同时拿到可查的 INI 语句说明。

## 实现侧（读取）

- 用 `CCINIClass`：`ReadBool` / `ReadInteger` / `ReadDouble` / `ReadString` / `Exists`。
- FallingStars 提供空指针安全的 `FS::INI::ReadBool/ReadInt/ReadDouble/ReadString` 与 `FS_INI_READ_*` 宏。
- 在扩展类的 `LoadFromINIFile(CCINIClass*)` 中读取；Section 用明确前缀（如 `[FallingStars]`、或在既有 `[TechnoType]` 下用 `FallingStars.ExampleFlag`）。

## 文档侧（必须同步）

参照 Phobos：

- `docs/New-or-Enhanced-Logics.md`：新增 / 增强逻辑的条目。
- `docs/Whats-New.md`：版本变更摘要。
- `docs/CREDITS.md`：贡献者。

每条 INI 键文档化以下字段：

- 键名（含 Section）
- 合法取值与类型（bool / int / double / string / 枚举）
- 默认值
- 作用对象（全局 / 某 TypeClass / 某 Object）
- 适用版本 / 前提条件

## 示例文档条目

```ini
[FallingStars]
ExampleFlag=false  ; bool; 默认 false; 作用于全局; 控制示例行为开关
```

## 校验

- 默认值必须保证"未配置"时行为合理（不崩溃、无异常）。
- 读取前用 `Exists` 或空指针安全辅助，避免缺键导致异常。
- 交付功能时，INI 键文档与源码一并提交，缺文档视为未完成。
