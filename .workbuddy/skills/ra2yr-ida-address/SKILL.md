---
name: ra2yr-ida-address
description: 用 IDA Pro / Ghidra 定位 gamemd.exe（RA2/YR 1.001）函数地址、虚表与成员偏移，为 SyringeEx Hook 提供正确地址。This skill should be used when finding the hexadecimal hook address for a DEFINE_HOOK, locating a vtable, or resolving a member offset in the YR game binary.
agent_created: true
---

# 用 IDA / Ghidra 定位 gamemd.exe 地址

## Overview

Hook 地址必须是目标 exe 版本的 RVA/文件偏移。本技能给出定位函数、虚表、成员偏移的实用流程，是 yrpp-syringe-hook 的前置步骤。

## 前置

- 目标 `gamemd.exe`（明确版本，如 YR 1.001 / 经 Ares 补丁后）。
- IDA Pro（强烈推荐，配合 IDA Pro MCP 可让 AI 直接查询函数/反汇编）或 Ghidra。
- YRpp 头文件（`TechnoClass.h` 等）对照结构体布局。

## 定位函数地址

1. 在 IDA 中加载 `gamemd.exe`（32-bit，镜像基址 `0x00400000`）。
2. 用字符串、导入表或已知符号（Ares/Phobos 文档常给出近似地址）缩小范围，定位目标函数。
3. 函数入口的 `0x004xxxxx` 即为 `DEFINE_HOOK` 的 `addr`（取后段 RVA；SyringeEx 按镜像基址 + 偏移）。
4. 确认该地址前 `size` 字节是完整指令（不被截断）；必要时在 IDA 中查看 prologue 长度。

## 定位虚表（vtable）

- MSVC 虚表符号命名形如 `??_7ClassName@@6B@`。在 IDA 的 Names 窗口搜索 `??_7TechnoClass`。
- 虚函数偏移 = 虚表基址 + index × 4；用于 `GET_BASE` 或虚调用。

## 定位成员偏移

- 在 YRpp 头中对照类布局；IDA 中观察构造函数 / 成员访问的 `[ecx+offset]`。
- 注意打包对齐（结构体对齐、编译选项）可能导致偏移随构建变化——以目标 exe 反汇编为准。

## 衔接 yrpp-syringe-hook

- 拿到的地址填入 `FallingStars.version.h` 对应宏（如 `FALLINGSTARS_TECHNOTYPE_LOAD_ADDR`），并把 `FALLINGSTARS_ENABLE_EXAMPLE_HOOKS` 置 `1` 启用。

## 注意

- 不同 exe 版本地址不同；文档中的地址务必标注版本。
- 优先使用 IDA Pro MCP（若已连接）直接 `get_function_by_name` / `disassemble_function`，减少人工查找。
