# 验证记录

日期：2026-11-07；平台：当前 Windows 电脑，x64。

已完成：

- .NET 10.0.403 构建 WinUI 应用，0 警告、0 错误。
- 实际启动应用，检查原生窗口、中文内容、卡片布局、配置状态与实验性提示。
- 点击界面“重新读取当前设置”，确认绑定正常、读取结果与命令行一致。
- 在系统 Windows PowerShell 5.1 中执行 Test-IconGenerator.ps1：解析脚本、隔离解码 7 个尺寸的 ICO、检查全部像素完全透明。该测试不修改注册表。
- Windows PowerShell 5.1 的 Status 读取成功。
- 对 Dism++ 官方发行包中的 5 个图像分别解码，包含 PNG 的 256 尺寸，记录格式与 Alpha 差异。

此前同一会话中，命令行操作已经实际验证过应用、恢复、重新应用，以及资源管理器重启。用户确认快捷方式箭头隐藏成功，盾牌当时未隐藏。该结果不等于新 GUI 的所有修改按钮已经进行端到端验证。

尚未完成：GUI 提权修改与恢复的完整端到端操作、多机兼容性、不同 DPI、ARM64、盾牌视觉隐藏验证。界面启动及读取检查没有再次改动系统角标配置。

## 紧凑单页与 DPI 修复

- 移除侧栏，窗口默认尺寸调整为 640 × 600 逻辑像素，并按显示器 DPI 换算窗口尺寸。
- 旧窗口的系统探测结果：DPI awareness=0，WindowDpi=96；新窗口：DPI awareness=2，PerMonitorV2=true，WindowDpi=192。确认已消除 DPI unaware 位图缩放路径；多显示器切换仍需进一步验证。
- 实际打开检查修改前后预览：记事本图标来自本机 notepad.exe，箭头来自 shell32.dll，盾牌来自 imageres.dll。Windows 资源在运行时加载，不随仓库分发。
- 按用户要求移除配置状态两行、实验性标签、权限说明与空闲时的选择提示。技术限制保留在文档中。
- 勾选只改预览；新增 Apply 操作按两个独立选项分别隐藏或恢复本工具管理的值。该新增组合操作的完整提权端到端测试尚未完成。

## 0.2.1 构建、安装与图标

- 实际执行 just dev，Debug 编译 0 警告、0 错误并启动。
- 实际执行 just build，Release 发布成功；确保包含应用 PRI、App/MainWindow/IconPreview 的 XBF、操作脚本与正式 ICO。
- 首次发布检查发现 SDK 没有复制应用 PRI/XBF，导致 ms-appx:///MainWindow.xaml 无法定位；增加发布 item 后重新构建与安装，确认安装目录版本正常运行。上游问题：https://github.com/microsoft/WindowsAppSDK/issues/6720。
- 在当前账户安装并升级至 0.2.1，验证开始菜单快捷方式目标、安装图标哈希、卸载注册项与版本。卸载脚本从安装目录执行 -WhatIf 成功，未实际卸载。
- ICO 的 16/20/24/32/40/48/64/128/256 共九个 PNG 子图像均可独立解码。
- 原始设计稿画布 1254 × 1254，高 Alpha 主体 662 × 639，宽度仅占 52.8%。ICO 导出仅收紧外围留白，主体最长边目标占比 90%，内部间距不变。对照本机现代记事本 256 图标的高 Alpha 主体为 192 × 256。
- 实际检查安装版窗口：新版记事本图标显示正常，右下角有 v0.2.1；点击版本入口后可访问“版本 0.2.1”和项目主页链接。
- 新版记事本资源来自当前账户注册的 Microsoft.WindowsNotepad 11.2607.14.0 的 unplated 256 图标。未复制该第三方资源到仓库。

图标大小比较基于源图与 ICO 的像素有效面积，未声称已直接观察第三方 Dock 的缓存刷新结果。

## 0.2.3 单文件与目录清理

- 实际执行 just build 和 just dev；Release、Debug 均只生成一个约 90.4 MiB 的 EXE。
- artifacts 与 bin 的目录枚举均确认仅有 WindowsIconToolkit.App.exe，未保留 DLL、语言目录或单独图标/脚本。
- 检查 .build/bundle-files-Release.txt：347 个内置文件中，语言目录仅 en-us 和 zh-CN；MainWindow.xbf、App.xbf、Controls/IconPreview.xbf、Assets/AppIcon.ico、Backend/Desktop-IconOverlays.ps1 均已内置。
- 在只有 EXE 的 artifacts 目录独立启动成功；重新安装 0.2.3 后正常显示窗口。安装目录仅有一个 EXE、卸载脚本及安装标记。
- 安装版本注册为 0.2.3；卸载 -WhatIf 检查通过，未实际卸载。
- 旧源码 bin/obj 与旧 artifacts/publish 已移入回收站；design 当前只有正式 PNG、提示词和说明。旧候选通过 Git 删除，Git 历史保留。
- 单文件模式会在运行时解压所需文件到框架缓存；没有宣称运行时零解压。

## 0.2.4 MRT Core 本地化

- 两份 Resources.resw 各 42 个键，完整性脚本在 Windows PowerShell 5.1 下通过：键集合一致、无空译文、格式占位符一致、XAML/代码引用有效、代码/XAML 无硬编码中文。
- 实际编译的应用 PRI 通过 MakePRI dump 检查，包含 Heading 的中英两组候选值。
- 在已安装的单文件版以 --language en-US 启动：XAML 主界面与无障碍名称显示英文；点击刷新得到 Status refreshed.，版本弹窗显示 Version 0.2.4 / Project on GitHub / Close；英文布局无截断。
- 以 --language de-DE 启动，实际显示英语回退资源。
- 当前 SDK 不接受空 PrimaryLanguageOverride。修正为普通启动读取 Windows UI 语言后，当前 zh-CN 环境下正常显示中文，版本为 v0.2.4。
- 测试未更改 Windows 显示语言，没有执行角标写入或资源管理器重启。
- 最终 just dev 启动通过；bin/artifacts 各保持一个 EXE，源 .resw 未作为松散文件输出。安装版哈希与 Release 产物一致，打包依赖语言仍仅 en-us、zh-CN。
