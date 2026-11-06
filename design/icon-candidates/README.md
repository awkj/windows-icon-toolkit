# 应用图标候选

由内置 image_gen 生成，属于设计方向候选，尚未作为应用正式图标使用。用户最终明确：保留颜色，但减少造型复杂度。最新提示词在 simple-color-prompts.json。

## 当前候选：简洁彩色

用户后续选择第三款的方向，要求改成田字格，右下角为圆球，并统一使用 Windows 蓝色。最新版本：

![Windows 蓝色田字格与圆球](K-windows-blue-grid.png)

上图提示词：windows-blue-grid-prompt.json。

最新调整：按用户要求缩小形状、加大间距，并要求纯 Windows 蓝色。设计稿：

![蓝色加宽间距版](L-windows-blue-spaced.png)

提示词：windows-blue-spaced-prompt.json。尚未接入程序图标。

| 候选 | 含义 | 图像 |
| --- | --- | --- |
| H 蓝色图标＋橙色角标 | 轮廓清楚，突出角标 | ![H](H-blue-badge.png) |
| I 青绿图标＋编辑短笔 | 直接表达编辑 | ![I](I-teal-edit.png) |
| J 紫色图标＋切角 | 以缺角与分离方块表达角标调整 | ![J](J-violet-corner.png) |

## 单色探索（未采用）

| 候选 | 含义 | 图像 |
| --- | --- | --- |
| E 方框切角 | 图标边框与可移除角标 | ![E](E-corner.png) |
| F 两个角框 | 两个角框与修改标记 | ![F](F-brackets.png) |
| G 图标擦除 | 擦除图标角部 | ![G](G-erase.png) |

本轮为白底设计草图；方向确定后再制作透明底、检查小尺寸并导出 ICO。

## 已否定的上一轮

用户认为 A–D 太复杂、配色花哨，不采用。原始提示词保存在 prompts.json，仅留作设计历史。

| 候选 | 含义 | 图像 |
| --- | --- | --- |
| A 揭角 | 揭开外层，露出干净图标 | ![A](A-peel.png) |
| B 像素重组 | 通过像素重排改变图标 | ![B](B-pixels.png) |
| C 角标剥离 | 从图标主体取下角标 | ![C](C-detach.png) |
| D 负形切角 | 用切角、留白表达定制 | ![D](D-cut.png) |

用户已否定此前“蓝色方块加白色铅笔”的初版，该版未接入应用，也未放入本目录。
