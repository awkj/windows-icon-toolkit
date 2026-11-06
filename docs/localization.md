# 标准 WinUI 本地化

从 0.2.4 开始，应用文字使用 WinUI 3 / Windows App SDK MRT Core 标准资源机制，不再将“裁剪两种语言依赖”称作应用双语支持。

## 资源与读取

```text
src/WindowsIconToolkit.App/Strings/en-US/Resources.resw
src/WindowsIconToolkit.App/Strings/zh-CN/Resources.resw
```

两份资源各有 42 个键。XAML 固定文字由 x:Uid 与属性资源（例如 Heading.Text、ApplyButton.Content）加载；动态提示、格式化信息及代码创建的弹窗通过 Microsoft.Windows.ApplicationModel.Resources.ResourceLoader 读取。无障碍名称和工具提示使用官方附加属性资源语法。

对于当前非 MSIX、单文件应用，ResourceLoader 显式传入实际解压目录中的应用 PRI 路径及 Resources 子树。SDK 在构建时编译 .resw 到 PRI，再随其余资源内置到 EXE。交付目录不会增加语言文件夹。

## 语言选择

- 每次普通启动读取 Windows 当前 UI 语言，并将该语言标记传入 Microsoft.Windows.Globalization.ApplicationLanguages.PrimaryLanguageOverride。
- 这是当前 SDK 非打包场景的处理：清空该属性会返回参数错误，因此不传空字符串；每次启动重新读取 Windows 语言，避免测试覆盖变成固定偏好。
- 使用 MRT Core 的语言匹配与回退，不在应用代码中编写中英字符串字典或自行选择译文。
- 项目 DefaultLanguage=en-US；没有匹配资源时回退英语。
- 不改变 Windows 的显示语言或语言列表；更改 Windows 显示语言后重新启动应用。

## 测试

静态完整性检查：

```powershell
.\scripts\Test-Localization.ps1
```

检查两种语言的键集合、非空译文、占位符、代码资源调用、XAML x:Uid 覆盖，并检测代码/XAML 中遗留的硬编码中文。

开发测试可在启动时传入 `--language en-US` 或 `--language zh-CN`；传入 `--language de-DE` 检查缺失语言的英语回退。普通启动不传参数，恢复跟随 Windows 当前 UI 语言。此参数仅改变应用资源上下文。

实际验证过：英文主界面、英文刷新提示、英文版本弹窗；德语覆盖时英语回退；正常启动跟随当前 Windows zh-CN 显示中文。没有执行提权修改或重启资源管理器。

参考：[微软本地化文档](https://learn.microsoft.com/en-us/windows/apps/windows-app-sdk/mrtcore/localize-strings)、[PrimaryLanguageOverride](https://learn.microsoft.com/en-us/windows/windows-app-sdk/api/winrt/microsoft.windows.globalization.applicationlanguages.primarylanguageoverride)。
