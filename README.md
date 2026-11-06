# Windows Icon Toolkit

Windows 图标工具箱。使用 WinUI 3 原生界面，调整桌面快捷方式箭头与管理员盾牌角标，并支持恢复修改前的设置。

当前提供：箭头与盾牌分别勾选、真实系统图标的修改前后预览、应用选项、恢复原设置、刷新状态、确认后重启当前会话的资源管理器。界面为紧凑单页，支持系统浅色/深色主题、Mica 背景和 Per-Monitor V2 DPI。

预览在运行时读取本机记事本图标和 Windows 原生角标，不随仓库分发 Windows 图像资源。勾选只改变预览，点击“应用到系统”才会修改设置。

## 技术选型

| 层 | 选择 | 原因 |
| --- | --- | --- |
| 界面 | WinUI 3 / XAML / Fluent Design | 微软推荐的新 Windows 桌面应用原生界面方案 |
| 平台 | Windows App SDK 2.6.5，稳定通道 | 已核对微软发布页与 NuGet 可用版本 |
| 语言与运行时 | C# / .NET 10 LTS | 适合持续维护的小型系统工具 |
| 视图状态 | CommunityToolkit.Mvvm 8.4.2 | 分离界面、状态和系统操作 |
| 系统操作 | 独立提升权限的 Windows PowerShell 5.1 进程 | 复用已验证的恢复脚本；界面本身以普通权限运行 |
| 首版分发 | 非 MSIX、自包含 x64 目录 | 简化系统设置工具的启动与部署；ARM64 需单独构建验证 |

本项目主要针对 Windows 11。项目最低 API 基线为 Windows 10 2004，不代表已经在所有满足基线的系统上测试。

## 构建与运行

安装 .NET 10 SDK；首次构建需要联网还原 NuGet 包。构建脚本也会识别项目 `.tools/dotnet` 内的便携 SDK。

```powershell
.\scripts\build.ps1 -Run
```

默认构建 x64 Debug。发布自包含目录：

```powershell
dotnet publish .\src\WindowsIconToolkit.App\WindowsIconToolkit.App.csproj -c Release -r win-x64 -p:Platform=x64 -o .\artifacts\publish
```

应用需要保留完整输出目录，不能只复制 EXE。源代码中的操作脚本会随构建输出，运行时不下载第三方程序。

也可独立双击 `scripts/Desktop-IconOverlays.cmd` 使用命令行菜单。

## 状态与恢复

“已配置”只表示注册表指向透明图标，不是对桌面渲染结果的保证。快捷方式箭头已在当前电脑经用户确认消失；盾牌尚未确认成功。

修改前的值保存在 `%ProgramData%\DesktopIconOverlayBackup`，重复应用不会覆盖最初备份。恢复只操作本工具备份过的值，发现其他工具改写后会停止恢复。原值不存在时，恢复会删除本工具添加的值；不会删除整个 `Shell Icons` 注册表键。

脚本使用 `29` 和可选的 `77`，不修改 UAC、不修改可执行文件、不删除 `IsShortcut`。隐藏盾牌不会消除管理员授权弹窗。

GUI 应用选项时：勾选的角标配置为隐藏；取消勾选的角标恢复本工具备份的原设置，没有本工具备份的值保持不变。“恢复原设置”处理本工具备份的两项设置。独立命令行菜单保留旧 Hide 行为，单独隐藏箭头不会撤销之前配置的盾牌隐藏。

## 结构

```text
src/WindowsIconToolkit.App/     WinUI 界面、MVVM 状态、系统操作入口
  Backend/                     随应用分发的操作脚本（构建时从 scripts 同步）
scripts/                       命令行入口、构建与只读验证
docs/                          技术决策、Dism++ 实现核对
```

## 资料

- [微软 WinUI 3 文档](https://learn.microsoft.com/en-us/windows/apps/winui/winui3/)
- [Windows App SDK 稳定版本](https://learn.microsoft.com/en-us/windows/apps/windows-app-sdk/release-channels)
- [.NET 发布与支持](https://learn.microsoft.com/en-us/dotnet/core/releases-and-support)
- [Dism++ 对比记录](docs/dism-comparison.md)
- [架构与后续工作](docs/architecture.md)

GitHub：[awkj/windows-icon-toolkit](https://github.com/awkj/windows-icon-toolkit)。应用图标正在选型，候选见 [design/icon-candidates](design/icon-candidates)。项目名是否与现有产品或商标冲突尚未核查。
