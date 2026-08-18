---
name: yrpp-syringe-hook
description: 在 YRpp + SyringeEx 生态下编写 Hook 的规范与宏用法。This skill should be used when writing DEFINE_HOOK / DEFINE_HOOK_AGAIN, using REGISTERS / GET / GET_STACK / LEA_STACK / REF_STACK macros, implementing SyringeHandshake, or resolving the correct hook address in gamemd.exe.
agent_created: true
---

# YRpp + SyringeEx Hook 编写规范

## Overview

SyringeEx 把扩展 DLL 注入 `gamemd.exe`，通过 `DEFINE_HOOK` 在运行时改写目标函数 prologue 跳板。本技能汇总握手流程、宏语义与地址来源约束，避免凭猜测下地址。

## 注入握手（SyringeEx）

- `SYR_VER=2` 预处理器定义（工程 props 已设）。
- 在导出/初始化处使用 `SYRINGE_HANDSHAKE(pInfo)` 声明本 DLL 支持的特性；`pInfo` 提供 `cbSize`、`SyringeVersion`、`SyringeFeatures` 等字段。
- 特性标志 `SyringeFeatures` 决定可用能力（例如允许重复 Hook → `DEFINE_HOOK_AGAIN`）。

## Hook 宏

- `DEFINE_HOOK(addr, Name, size)`：在 `addr` 处放置 `size` 字节跳板，原函数前 `size` 字节被覆盖。`size` 需 ≥ 5（jmp 指令长度）且不被中间指令截断。
- `DEFINE_HOOK_AGAIN(addr, Name, size)`：同地址二次 Hook（需 SyringeEx 特性支持）。
- 进入 Hook 后通过 `REGISTERS* R = MakeRegs(...)`（具体签名随 SyringeEx 版本）获取寄存器上下文，用 `R->GET(REG_EAX)` 等读取/改写；用 `GET_STACK` / `LEA_STACK` / `REF_STACK` / `STACK_OFFSET` 访问栈参数；`GET_BASE` 取 `this`。

## 寄存器/栈访问宏（自包含，见 src/Core/Macro.h）

- `GET(REG_xxx)`、`GET_STACK(offset, type)`、`LEA_STACK(offset)`、`REF_STACK(offset, type)`、`STACK_OFFSET(var)`、`GET_BASE`。
- **这些宏不在 YRpp**，是 Phobos 风格实现，模板已自带 `Core/Macro.h`。

## 地址来源（关键约束）

- `addr` 必须是 `gamemd.exe` 在**目标版本**（如 YR 1.001）的 RVA/文件偏移，来自 IDA Pro / Ghidra 反汇编。绝不可凭内存地址或猜测。
- 定位方法见 ra2yr-ida-address 技能。
- 模板示例 Hook 使用 `FallingStars.version.h` 中的 `FALLINGSTARS_TECHNOTYPE_LOAD_ADDR` 占位，默认 `0` → 不参与编译。

## 最小可用 Hook 骨架

```cpp
#include <Syringe.h>
#include <FallingStars.version.h>

DEFINE_HOOK(0x00401234, MyHookName, 5)
{
    GET_STACK(/* type, offset */);
    // 业务逻辑
    return 0;
}
```

## 验证

- 编译 0 error → SyringeEx 注入 → 调试器 / DebugView 确认 Hook 命中且不崩溃。
- 若函数前几字节包含非对齐指令，调大 `size`，但保持不超过原函数可用范围；用 IDA 确认 prologue 长度。
