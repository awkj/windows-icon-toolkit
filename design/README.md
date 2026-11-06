# 正式应用图标

![Windows Icon Toolkit](app-icon.png)

用户选定的 Windows 蓝色田字格：三个方块、右下角圆形。仅保留本版；原始生成提示词在 prompt.json。由内置 image_gen 生成。

scripts/Export-AppIcon.ps1 使用此 PNG 作为唯一源文件，将外围留白收紧至主体约占 96%，保留内部间距，并导出 src/WindowsIconToolkit.App/Assets/AppIcon.ico。
