# FallingStars 繁星落幕

面向《命令与征服：尤复的复仇》（Yuri's Revenge / RA2 YR）的**注入式扩展平台框架**。

参照 Ares / Phobos 的 **SyringeEx 注入** 思路，把代码注入 `gamemd.exe`，但在“易用性”上做了系统性改进，让新增功能更快、更安全。

> 本仓库是**模板 / 平台骨架**，已带一个最小可编译示例（启动横幅 + 一个扩展类示例）。
>
> 你只需往 `src/` 里加文件、填好 IDA 反汇编出的真实 Hook 地址，即可扩展游戏。

---

## 相比 Ares / Phobos 的改进

| # | 改进点               | 说明                                                                                                                      |
| - | ----------------- | ----------------------------------------------------------------------------------------------------------------------- |
| 1 | **模块自动注册**        | 新功能 = 写一个 `IModule` 子类 + 一行 `REGISTER_MODULE(...)`，**无需编辑任何中央注册表文件**（Phobos 需改 `Phobos.Ext.cpp`）。                       |
| 2 | **自包含扩展容器**       | `FS::Extension<T>` + `FS::ExtensionContainer<T,Ext>` 提供 `Find/Fetch/TryFetch/Remove`，不依赖 Phobos 内部 `Container` 机制，复制即用。 |
| 3 | **INI 读取辅助**      | `FS::INI::ReadBool/ReadInt/ReadDouble/ReadString` 全部**空指针安全**；配套 `FS_INI_READ_*` 宏直接写成员变量。                              |
| 4 | **项目文件自动生成**      | `scripts/gen_project.py` 扫描 `src/` 自动刷新 `.vcxproj` 的源文件列表，**永远不用手动加文件**。                                                |
| 5 | **安全的示例 Hook**    | 示例 Hook 默认关闭；未填真实地址前不会注入，避免 `gamemd.exe` 启动即崩。                                                                          |
| 6 | **中文文档 + 复制即用示例** | 降低上手门槛，结构说明见 `docs/`。                                                                                                   |

---

## 环境要求

- **Visual Studio 2022**（MSVC **v143**，Win32/x86）
- **Windows 10/11 SDK**（如 `10.0.20348.0`）
- **SyringeEx**（注入器，必需，见 `tools/SyringeEx/README.md`）
- `YRpp/` 子模块（游戏类型头文件，已随本仓库就位）

---

## 构建

**方式一：Visual Studio**

直接打开 `FallingStars.sln`，`Ctrl+Shift+B` 构建。配置下拉选 `Debug` 或 `Release`。

**方式二：脚本**

```bat
scripts\build_debug.bat      :: 输出 Debug\FallingStars.dll (+ .pdb)
scripts\build_release.bat    :: 输出 Release\FallingStars.dll (+ .pdb)
scripts\clean.bat            :: 清理
```

> 脚本通过 `vswhere.exe` 自动定位 VS2022，并调用 `VsDevCmd.bat` 初始化 x86 构建环境——**普通 `cmd` 即可直接运行，不必先打开 Developer Command Prompt**。仅依赖 VS2022（含 MSVC v143 + Windows SDK），其余无需手动配置。

---

## 注入是怎么生效的（Syringe.h 契约）

- 模板**默认启用一个真实入口 Hook**：`DEFINE_HOOK(0x7CD810, FallingStars_ExeRun, 0x9)`——与 Phobos 完全相同的地址与用法（`Phobos.cpp` 的 `ExeRun`）。SyringeEx 从 `.syhks00` 段读到该断点，游戏一启动执行到 `0x7CD810` 就加载 `FallingStars.dll` 并调用此函数：**与 Phobos 一样的注入方式，不需要 `--handshakes`**。
- 模块初始化（启动横幅、Debug 弹窗）就在这个入口 Hook 里执行（对应 Phobos 的 `Phobos::ExeRun()`）。
- `src/FallingStars.cpp` 另留了一个被跳过的 `.syhks00` 占位（`hookName=nullptr`）作兜底：即使所有真实 Hook 都被禁用，段仍存在，DLL 仍能被识别。
- 新增真实 Hook 后断点自动注册；地址必须来自 IDA/Ghidra 且落在指令边界。

---

## 运行与验证

1. 用 **Syringe.exe** 启动游戏（`FallingStars.dll` 须与 `gamemd.exe` 同目录）：
   ```bat
   Syringe.exe gamemd.exe
   ```
   只注入本 DLL：`Syringe.exe gamemd.exe -i=FallingStars.dll`。**不要直接双击 `gamemd.exe`**（注入器不会运行）。详见 `tools/SyringeEx/README.md`。
2. 打开 **DebugView**（或 VS 的输出窗口 / 任意附加到进程的调试器）。
3. 启动游戏，应看到调试输出：
   ```
   [FallingStars] v0.1.0 (commit dev, branch local) injected. 1 module(s) registered.
   [FallingStars] ExampleModule ready. ...
   ```
   看到这一行即证明 DLL 已成功注入、模块自动注册生效。

---

## Debug 调试提醒弹窗

- **Debug 构建**（`_DEBUG`）：DLL 注入、游戏到达入口 Hook（`0x7CD810`）后立即弹出 MessageBox「FallingStars - 调试提醒」，提示当前是调试/测试进程；点「确定」继续游戏。**Release 构建不弹窗**。
- 实现：`src/Hooks/DebugNotice.cpp` 的 `DebugNoticeModule::OnLoad()`，由 `ModuleRegistry::OnLoadAll()`（入口 Hook 调用）触发，零地址依赖。

---

## 快速上手

### 1) 增加一个 Hook

参考 `src/Extensions/TechnoType/Hooks.cpp`：

- 在 IDA/Ghidra 中找到目标函数地址（必须落在**指令边界**）。
- 把它填到 `src/FallingStars.version.h` 的 `FALLINGSTARS_TECHNOTYPE_LOAD_ADDR`。
- 把 `FALLINGSTARS_ENABLE_EXAMPLE_HOOKS` 改为 `1`（在 `.props` 或 `version.h` 中）。
- `DEFINE_HOOK` 的 `size` 必须覆盖完整的指令（含被 5 字节 JMP 覆盖的部分）。

### 2) 增加一个扩展类

直接**复制 `src/Extensions/TechnoType/` 文件夹**，重命名，把游戏类型（`TechnoTypeClass`）换成你要扩展的类型，实现 `LoadFromINIFile` 即可。`src/Extensions/TechnoType/Body.h` 的注释里有完整模板说明。

### 3) 读取 INI

在模块的 `LoadFromINI` 或扩展的 `LoadFromINIFile` 中：

```cpp
FS_INI_READ_BOOL(pINI, "MySection", "MyFlag", this->MyFlag, false);
// 或空指针安全地：
bool b = FS::INI::ReadBool(pINI, "MySection", "MyFlag", false);
```

### 4) 新增 / 删除源文件后

运行一次即可刷新工程：

```bat
python scripts/gen_project.py
```

---

## 故障排查

### MSB8037：找不到适用于桌面 C++ Win32 应用的 Windows SDK 版本 10.0.x

- **现象**：`Microsoft.Cpp.WindowsSDK.targets(52,5): error MSB8037: 找不到适用于桌面 C++ Win32 应用的 Windows SDK 版本 10.0.26100.0…`，即使 SDK 已安装、文件齐全、注册表也正确。
- **根因**：`FallingStars.props` 中的 `<PlatformTarget>` 必须是 **`x86`**，不能写成 `Win32`。MSBuild 对 Win32 平台默认映射 `PlatformTarget=x86`（见 VS 安装目录 `MSBuild\Microsoft\VC\v170\Platforms\Win32\Platform.Default.props`）；一旦被覆盖成 `Win32`，`Microsoft.Cpp.WindowsSDK.targets` 会检查 `Lib\<版本>\um\Win32\gdi32.lib`——而 SDK 实际目录叫 `x86`，于是判定"桌面 C++ Win32 支持未安装"，直接报 MSB8037。
- **修复**：确认 `FallingStars.props` 中是 `<PlatformTarget>x86</PlatformTarget>`（本仓库已修复）。若你改过它，改回即可。
- **自查**：MSB8037 的判定条件是以下**两个文件同时存在**（路径来自 `WindowsSDK_Desktop_Support`）：
  - `Include\<版本>\shared\sdkddkver.h`
  - `Lib\<版本>\um\x86\gdi32.lib`
  缺任一即报 MSB8037，与注册表无关。

---

## 注意事项

- **Hook 地址必须真实**：来自对 `gamemd.exe` 的反汇编，且必须落在指令边界；填错地址会导致游戏崩溃。
- **不要整体覆盖 `IncludePath`**：`FallingStars.props` 用 `AdditionalIncludeDirectories` **追加**包含路径，避免把 `$(WindowsSDK_IncludePath)` 丢掉而导致 `windows.h` 找不到（经典的 C2447 错误）。
- **无异常、无 RTTI**：工程关闭了 `/EHsc` 与 RTTI，不要用 `try/catch/throw`、`dynamic_cast`。
- **静态 CRT (`/MT`)**：DLL 使用独立堆，扩展数据用普通 `new/delete`，不要跨 DLL 边界传递 STL 对象。

详见 `docs/Structure.md` 与 `docs/INI-Keys.md`。
