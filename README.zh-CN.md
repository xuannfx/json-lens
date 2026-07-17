# Json Lens

[English](README.md)

Json Lens 是一个轻量的 macOS 菜单栏 JSON 查看器。复制或选中 JSON 后，即可在悬浮窗口中查看、搜索和浏览，不占用 Dock。

## 功能

- 自动识别 JSON、JSONC、JSON Lines 及常见 JSON 文本格式
- Raw、Tree、Columns 三种查看方式
- 支持格式化、语法高亮、自动换行、搜索、展开与折叠
- 提供路径、类型、子节点检查器，以及可调节宽度的分栏
- 支持剪贴板监听、可配置全局快捷键与可选的选中文本检测
- 支持浅色/深色模式与四套配色主题

## 使用

1. 从 [Releases](https://github.com/xuannfx/json-lens/releases/latest) 下载并打开 `Json Lens.dmg`。
2. 将 `Json Lens.app` 拖入 `Applications`，然后启动应用。
3. 点击菜单栏 `{}` 图标，或复制一段 JSON；开启剪贴板监听时会自动打开查看器。
4. 默认快捷键为 `Command-Shift-J`，会尝试读取当前选中文本或剪贴板中的 JSON。
5. 在查看器右上角点击设置图标，可修改快捷键、检测行为、外观与主题。

`Tree` 适合层级查看，`Raw` 支持行号、语法高亮与换行，`Columns` 适合逐层钻取。按 `Esc` 关闭悬浮窗口。

## 权限与安全提示

- **辅助功能权限**仅在开启“自动检测选中文本”或需要读取其他应用的选中内容时使用。普通剪贴板查看不需要它。
- 当前公开构建为 ad-hoc 签名。首次从网络下载后，macOS 可能提示无法验证开发者：在 Finder 中右键应用，选择“打开”并确认即可。

## 开发与构建

```bash
swift run JsonLens

# 构建应用
Scripts/build-app.sh
open ".build/Json Lens.app"

# 构建 DMG（首次执行需安装）
python3 -m pip install --user dmgbuild
Scripts/build-dmg.sh
open ".build/Json Lens.dmg"
```

## 许可证

[MIT License](LICENSE)
