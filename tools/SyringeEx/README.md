# SyringeEx（必需依赖）

FallingStars 是一个**注入式 DLL**，本身不含启动器。它必须由 **SyringeEx（`Syringe.exe`）** 注入到
`gamemd.exe` 才能运行。

## 是什么

- **SyringeEx** 是 Phobos 团队维护的 Syringe 分支（https://github.com/Phobos-developers/SyringeEx）。
- 支持 `SYR_VER=2` 的 hook 声明协议（`.syhks00` 段）与特性标志（FallingStars 已在
  `FallingStars.props` 中定义 `SYR_VER=2` 以启用）。
- 注入流程（读 SyringeEx 源码 `SyringeDebugger.cpp` 确认）：
  1. 扫描**目标 exe 所在目录**下的 DLL（无 `-i=` 时默认 `*.dll`）；
  2. 读取 DLL 的 `.syhks00` 段中的 hook 声明；
  3. 游戏运行到 hook 断点地址时，加载 DLL 并调用对应的 hook 函数。

## 与 Phobos 完全相同的用法

FallingStars 默认带一个**真实入口 Hook**（`DEFINE_HOOK(0x7CD810, FallingStars_ExeRun, 0x9)`，
与 `Phobos.cpp` 的 `ExeRun` 同一地址）。因此它的注入方式与 Phobos 完全一致，**不需要任何额外参数**：

1. 从 SyringeEx 仓库 Release 下载 **`Syringe.exe`**（注入器本体；注意文件名不是 `SyringeEx.exe`）。
2. 把 `Syringe.exe` 与编译好的 `FallingStars.dll`（可带 `.pdb`）放到**游戏根目录**，即与 `gamemd.exe` 同目录。
3. 用 Syringe.exe 启动游戏：

   ```bat
   Syringe.exe gamemd.exe
   ```

   - 只注入本 DLL（目录里还有其它 Syringe 兼容扩展时推荐）：
     ```bat
     Syringe.exe gamemd.exe -i=FallingStars.dll
     ```
   - DLL 不在 gamemd.exe 目录时，可用 `-pathlnject=<目录>` 指定额外搜索目录。
   - **不要直接双击 `gamemd.exe` 启动**——那样注入器不会运行，扩展全部失效。
   - **不要把 `FallingStars.dll` 放进 `Patches\` 子目录**（Ares 的 mod DLL 加载目录）。Ares 会扫描 `Patches\*.dll` 并尝试调用约定的导出 ordinal（典型如 345），FallingStars.dll 不是 Ares mod DLL、也没有这些导出 → 会弹「Game.exe - 找不到函数 无法定位函数 345 于...FallingStars.dll 上」。FallingStars 必须放在 gamemd.exe 同目录，由 Syringe 加载，Ares 不要碰。

> 可选：`--handshakes`（调用 DLL 的 `SyringeHandshake`）。FallingStars 默认不依赖握手——
> 初始化在 ExeRun 入口 Hook 里完成（同 Phobos 的 `Phobos::ExeRun()`）；握手仅作为兼容性增强保留。

## 验证

启动后用 **DebugView**（或任意附加到 `gamemd.exe` 的调试器）观察输出。看到：

```
[FallingStars] v0.1.0 (commit dev, branch local) injected. ... module(s) registered.
```

即注入成功；**Debug** 构建还会弹出「FallingStars - 调试提醒」窗口（点确定继续游戏）。
