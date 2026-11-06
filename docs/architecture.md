# 技术决策

日期：2026-11-07。名称：Windows Icon Toolkit；仓库：windows-icon-toolkit。

选择 C#、.NET 10 LTS、WinUI 3、Windows App SDK 稳定通道、CommunityToolkit.Mvvm。核对时 Microsoft.WindowsAppSDK 最新稳定 NuGet 为 2.6.5，CommunityToolkit.Mvvm 为 8.4.2。依赖固定版本，升级前重新验证。

WinUI 3 是微软推荐的新 Windows 桌面应用原生 UI 方案。使用紧凑单页、真实图标前后对比、CheckBox、ContentDialog、Mica 和系统主题。WPF 更适合已有 WPF 代码资产；本项目没有该负担。当前功能仅针对 Windows，跨平台框架和 WebView 容器不会带来直接收益。

## 权限边界

主界面 asInvoker 普通权限启动。仅执行预定义的角标修改和恢复命令时，通过系统 UAC 提升 Windows PowerShell 进程权限。命令使用固定枚举映射，不从界面接收任意命令、注册表路径或下载地址。

v0.1 复用 PowerShell 后端，避免同时重写已经验证的操作逻辑。后续可将后端迁移为独立的 C# 操作进程，改进结构化错误、日志、取消与并发控制；不能把这些后续项描述成当前已经实现。

UI 与系统服务通过 OverlayService 分离，MainViewModel 管理异步操作与状态。配置读取结果不被当作视觉验证结果。操作异常会显示失败，取消 UAC 不显示成功。

## 分发

首版使用非 MSIX 自包含目录，优先 x64。保留 WinUI 和 .NET 所需输出文件及 Backend 脚本。发布阶段再考虑签名、安装器和自动更新；当前没有静默安装、自动联网更新或开机常驻。

## 下一步

1. 图标方案 A/B 测试，优先定位本机盾牌问题。
2. 将脚本错误以结构化结果返回界面，加入操作日志。
3. 针对并发、部分失败与恢复冲突加入事务测试。
4. 支持箭头、盾牌分别恢复；补充操作预览。
5. 在不同 DPI、Windows 构建和 ARM64 真机上验证。

首版只管理桌面角标。不会因为“优化”而批量更改 UAC、Defender、系统服务或隐私选项。
