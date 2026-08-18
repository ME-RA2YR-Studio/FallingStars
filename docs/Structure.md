# 项目结构（FallingStars）

```
FallingStars/
├── FallingStars.sln            # VS2022 解决方案
├── FallingStars.vcxproj        # 工程文件（源文件列表由 gen_project.py 维护）
├── FallingStars.props          # 全局编译选项（/MT, C++20, SYR_VER=2, 包含路径）
├── .editorconfig               # 代码风格（tab / Allman / CRLF）
├── .vsconfig                   # VS 必需组件清单
├── YRpp/                       # 子模块：游戏二进制类型头文件（已就位，勿手改）
├── scripts/
│   ├── run_msbuild.bat         # 用 vswhere 定位 MSBuild 并构建
│   ├── build_debug.bat
│   ├── build_release.bat
│   ├── clean.bat
│   └── gen_project.py          # 扫描 src/ 刷新 vcxproj 源文件列表
├── tools/SyringeEx/README.md   # 注入器依赖说明
├── docs/
│   ├── Structure.md            # 本文件
│   └── INI-Keys.md             # 新增 INI 键的文档模板
└── src/
    ├── FallingStars.version.h  # 版本号 + 构建戳 + 功能开关 + 示例地址占位
    ├── FallingStars.h/.cpp     # 启动引导：SyringeHandshake 横幅 + DispatchLoadFromINI
    ├── Core/                   # “更好用”的自包含基础层
    │   ├── Module.h            # IModule + ModuleRegistry + REGISTER_MODULE
    │   ├── Extension.h         # Extension<T> + ExtensionContainer<T,Ext>
    │   ├── INIHelpers.h        # FS::INI 空指针安全读取 + FS_INI_READ_* 宏
    │   ├── Logging.h           # FS_LOG(...) 经 OutputDebugStringA 输出
    │   ├── Macro.h             # GET / GET_STACK / LEA_STACK / REF_STACK
    │   └── Patch.h             # 运行时补丁 Apply_LJMP / Apply_CALL / Apply_RAW
    ├── Extensions/             # 对每个游戏类型的扩展（复制 TechnoType 起步）
    │   └── TechnoType/
    │       ├── Body.h          # 扩展类声明（ExtData + ExtMap 容器）
    │       ├── Body.cpp        # 容器定义 + LoadFromINIFile 实现
    │       └── Hooks.cpp       # 该类型的 Hook（默认关闭的示例）
    └── Hooks/                  # 自由 Hook / 模块
        └── Startup.cpp         # 示例模块 ExampleModule（自注册 + 横幅 + 读 INI）
```

## 关键数据流

1. **注入**：SyringeEx 把 `FallingStars.dll` 注入 `gamemd.exe`，调用导出的 `SyringeHandshake`。
2. **横幅 + 初始化**：`FallingStars.cpp` 的 `SyringeHandshake` 打印版本横幅，并调用 `FS::ModuleRegistry::OnLoadAll()`（各模块 `OnLoad`）。
3. **读 INI**：在游戏加载 INI 的例程上挂一个 Hook，其函数体调用 `FS::DispatchLoadFromINI(pINI)`，进而 `FS::ModuleRegistry::LoadFromINIAll(pINI)` 让每个模块 / 扩展类读取自己的配置。
4. **运行时 Hook**：`DEFINE_HOOK` 在 `gamemd.exe` 指定地址插入 5 字节 `JMP`，跳进 DLL 内的处理函数。

## 在哪里挂接 `DispatchLoadFromINI`

在 IDA 中定位负责消化 `rulesmd.ini` / `artmd.ini` 的例程（例如 `CCINIClass::LoadFromINI` 的调用点，或 scenario 初始化函数），在其返回前插入：

```cpp
DEFINE_HOOK(<ADDR>, Scenario_Load_FallingStars, 0x5)
{
    GET_STACK(CCINIClass*, pINI, 0x4);
    FS::DispatchLoadFromINI(pINI);
    return 0;
}
```

完成后把 `FALLINGSTARS_ENABLE_EXAMPLE_HOOKS` 相关逻辑启用即可（示例 Hook 已展示同一模式）。
