---
name: fallingstars-dev
description: FallingStars 注入式扩展平台（SyringeEx + gamemd.exe）的开发手册。This skill should be used when adding a Module / Extension class / Hook / INI key to the FallingStars template, understanding its directory layout, or running the build-and-verify loop.
agent_created: true
---

# FallingStars 开发手册

## Overview

FallingStars 是参照 Ares/Phobos 的 SyringeEx 注入式扩展 DLL 模板（VS2022 MSBuild，Win32/x86，C++20，`/MT`，`SYR_VER=2`）。本技能说明其目录结构、四大扩展点与构建验证闭环，目标是在 Ares/Phobos 之上做到"更方便"。

## 目录结构

- `FallingStars.sln` / `FallingStars.vcxproj` / `FallingStars.props` — 工程与全局编译选项。
- `src/Core/` — 基础能力：
  - `Module.h`：模块自注册（`FS::IModule` + `ModuleRegistry` + `REGISTER_MODULE`）。
  - `Extension.h`：`FS::Extension<T>` 基类 + `FS::ExtensionContainer<TGameObject,TExt>`（`unordered_map`，Find/TryFetch/Fetch/Remove）。
  - `INIHelpers.h`：空指针安全的 `FS::INI::ReadBool/ReadInt/ReadDouble/ReadString` 与 `FS_INI_READ_*` 宏。
  - `Macro.h`：自包含的 `GET`/`GET_STACK`/`LEA_STACK`/`REF_STACK`/`GET_BASE`/`STACK_OFFSET` 寄存器访问宏（**不在 YRpp**）。
  - `Logging.h`：`FS::Log::Print` 经 `OutputDebugStringA`；`FS_LOG` 宏。
  - `Patch.h`：`FS::Patch::Apply_LJMP`/`Apply_CALL`/`Apply_RAW`（VirtualProtect + memcpy 运行时补丁）。
- `src/FallingStars.h` / `FallingStars.cpp` / `FallingStars.version.h` — 引导（`SYRINGE_HANDSHAKE`）、版本号与开关宏。
- `src/Hooks/Startup.cpp` — 示例模块（`ExampleModule`）。
- `src/Extensions/TechnoType/` — 示例扩展类（`TechnoTypeExt`）。
- `scripts/` — `run_msbuild.bat`（自动 `VsDevCmd.bat` + `vswhere`）、`build_debug.bat`、`build_release.bat`、`clean.bat`、`gen_project.py`（刷新 vcxproj 源文件列表）。

## 四大扩展点

1. **Module（模块自注册）**：继承 `FS::IModule`，实现 `Name()` / `OnLoad()` / `LoadFromINI(CCINIClass*)`，文件末尾 `REGISTER_MODULE(YourModule)`。免改中央注册表。
2. **Extension 类**：继承 `FS::Extension<TGameObject>`，内置 `Container`（`FS::ExtensionContainer`），在 `LoadFromINIFile(CCINIClass*)` 中读取配置。仿 Phobos 但自包含。
3. **Hook**：`DEFINE_HOOK(addr, Name, size)`，地址必须来自 IDA/Ghidra；用 `REGISTERS* R` + `GET/GET_STACK`。详见 yrpp-syringe-hook 技能。
4. **INI 键**：用 `FS::INI::ReadBool/ReadInt/...` 读取，配套文档。详见 phobos-ini-extension 技能。

## 构建验证闭环

1. 安装 VS2022（"使用 C++ 的桌面开发" 工作负载：MSVC v143 + Windows 10/11 SDK）。
2. 任意 `cmd` 中运行 `scripts\build_debug.bat` → 期望 **0 error**，产出 `Debug\FallingStars.dll`（+ .pdb）。
3. 用 SyringeEx 把 DLL 注入 `gamemd.exe`，DebugView 看启动横幅。
4. 新增源文件后运行 `scripts\gen_project.py` 刷新 `vcxproj`（或手动加 `<ClCompile>`/`<ClInclude>`）。
5. 示例 Hook 默认关闭（`FALLINGSTARS_ENABLE_EXAMPLE_HOOKS=0` 且 `FALLINGSTARS_TECHNOTYPE_LOAD_ADDR=0`），不影响构建。
6. **注入前置条件（Syringe.h 契约）**：模板**默认启用真实入口 Hook** `DEFINE_HOOK(0x7CD810, FallingStars_ExeRun, 0x9)`——与 Phobos 完全相同（`Phobos.cpp:247` 的 `ExeRun`，gamemd 主运行入口）。SyringeEx 从 `.syhks00` 段读到断点，游戏一执行到该地址就加载 DLL 并调用 hook（`Phobos::ExeRun` 同款初始化点）。`src/FallingStars.cpp` 另留 `hookName=nullptr` 占位作兜底（全部 hook 被禁用时段仍存在、仍可识别）。`FallingStars.h` 显式 `#include <Syringe.h>`。
7. **启动命令**：`Syringe.exe gamemd.exe`（DLL 与 gamemd.exe 同目录；无需 `--handshakes`，与 Phobos 完全一致的用法）。可 `-i=FallingStars.dll` 只注入本 DLL、`-pathlnject=<目录>` 加搜索路径；**不要直接双击 gamemd.exe**。注入器默认扫描 exe 目录下 `*.dll`（无 -i= 时）。`--handshakes` 仅可选（调用 `SyringeHandshake`，非必需——初始化在 ExeRun hook 里）。

## 关键约束

- Include 路径必须**追加**（`%(AdditionalIncludeDirectories)`），禁止整体覆盖 `$(IncludePath)`，否则丢失 `$(WindowsSDK_IncludePath)` → `windows.h` 找不到（经典 C2447）。
- **`<PlatformTarget>` 必须是 `x86`，绝不能写 `Win32`**（陷阱，曾致 MSB8037）：MSBuild 对 Win32 平台默认映射 `PlatformTarget=x86`（`MSBuild\Microsoft\VC\v170\Platforms\Win32\Platform.Default.props`）；覆盖成 `Win32` 后，`Microsoft.Cpp.WindowsSDK.targets` 检查 `Lib\<ver>\um\$(PlatformTarget)\gdi32.lib`（实际目录是 `x86`）→ 不存在 → 报 `MSB8037: 找不到适用于桌面 C++ Win32 应用的 Windows SDK 版本`。**MSB8037 只看两个文件**：`Include\<ver>\shared\sdkddkver.h` + `Lib\<ver>\um\x86\gdi32.lib`，与注册表无关。
- 无异常、无 RTTI、C++20；**CRT 必须与配置匹配**：Debug=`MultiThreadedDebug`(/MTd)+`_DEBUG`，Release=`MultiThreaded`(/MT)+`NDEBUG`。`_DEBUG` 激活 CRT 断言/STL 迭代器调试，引用 `__CrtDbgReport`（在 libcmtd.lib）——Debug 若链 /MT 会 LNK2001/LNK2019 `__CrtDbgReport`。中文源码需 `/utf-8`（否则 C2001/C2143）。
- `GET` 等寄存器宏位于 `src/Core/Macro.h`，不在 YRpp。
