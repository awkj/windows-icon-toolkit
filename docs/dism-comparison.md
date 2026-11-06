# Dism++ 实现核对

核对日期：2026-11-07。

## 来源和范围

- [规则仓库提交 875bce3](https://github.com/Chuyu-Team/Dism-Multi-language/tree/875bce3511995000ceed38e3b7aba5917e4868cc)
- [Data.xml 的箭头与盾牌规则](https://github.com/Chuyu-Team/Dism-Multi-language/blob/875bce3511995000ceed38e3b7aba5917e4868cc/Data.xml#L3039-L3081)
- [官方发行包 v10.1.1002.1](https://github.com/Chuyu-Team/Dism-Multi-language/releases/tag/v10.1.1002.1)

这个仓库主要包含语言、优化规则和文档，不能据此声称已经审阅 Dism++ 全部核心 C++ 源码。本次实际下载发行 ZIP，仅解压读取资源，没有运行 Dism++。

## 规则确认

箭头写入 `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons` 的 `29`；盾牌写入 `77`。类型均为 `REG_EXPAND_SZ`，路径均为 `%systemroot%\Blank.ico`，不带图标索引后缀。透明图标从 `Config\default.ui.zip/Data/Blank.ico` 释放。

两项均声明重启 Explorer，盾牌额外声明 `ExplorerNotify Type="AssocChanged"`。规则文档称其作用为刷新文件关联；我们的对应实现使用 `SHChangeNotify(SHCNE_ASSOCCHANGED)`。未见通知处理函数的核心实现，不能声称逐字复刻内部调用。

恢复规则删除对应值，没有在这些规则中发现保存、恢复既有自定义值的逻辑。勾选状态依据对应值存在与否，不代表图标实际隐藏。

## 实际图标差异

Dism++ 原始 Blank.ico：19,535 字节，SHA-256：

```text
67915F4B83DCD87CE850716442D613AF8F45828A5138A3AC56BB873482053CAB
```

| 项 | Dism++ 发行包 | 本项目生成器 |
| --- | --- | --- |
| 图像数量 | 5 | 7 |
| 尺寸 | 16、24、32、48、256 | 16、24、32、48、64、128、256 |
| 色深 | 32 位 | 1 位单色 |
| 256 尺寸编码 | PNG | DIB |
| 透明表达 | ARGB + 掩码；小尺寸存在极低 Alpha 像素 | XOR 全 0、AND 全 1，完全透明 |
| 资源路径 | Windows 目录 | ProgramData 独立目录 |

Windows System.Drawing 分别解码每个图像后，16/24/32/48 尺寸分别有 9/17/22/85 个非零 Alpha 像素，最大 Alpha 为 2/255，约 0.78%。256 尺寸 PNG 有 758 个非零 Alpha 像素，最大 Alpha 为 4/255，约 1.57%。Inspect-Icon.ps1 会隔离图像后解码，避免解码器静默选择其他尺寸。

这说明 Dism++ 的图标并非每个像素 Alpha 都为零。但无法仅据此判断它为何这样设计，也不能证明这就是本机盾牌未隐藏的原因。不能把图像数量更多或完全透明当成兼容性更好的证据。

## 谁更好、学习什么

Dism++ 在产品成熟度、资源积累和规则组织上更值得参考；这些优势不等于已经证明它在这台电脑上能隐藏盾牌。本项目目前主要优点是明确保留原值、重复执行不覆盖初始备份、恢复时避免覆盖其他工具的新设置，以及诚实区分配置状态和视觉结果。

优先学习：

1. 将优化规则、资源文件、刷新要求和界面分离。
2. 使用经过实际 Windows 版本测试的固定图标资源，建立资源哈希与格式检查；不要凭理论判断兼容性。
3. 为每条规则记录适用系统、刷新方式与撤销方式。
4. 把“需要管理员权限”限定在执行阶段。
5. 建立图标方案的 A/B 测试记录，确认视觉效果后再调整默认值。

继续保留：原值备份恢复、读写范围限制、并发与失败处理、明确的实验性标识。

## 尚未完成

- 在同一系统上对 Dism++ 原始图标与本项目图标进行受控 A/B 测试。
- 证明盾牌在当前 Windows 版本上的有效隐藏方案。
- 覆盖高 DPI、多显示器及 ARM64 的实际视觉验证。

Dism++ 图标仅作为本地研究资料读取，未放进本项目，也未替换当前系统使用的图标。
