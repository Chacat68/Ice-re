<div align="center">
    <img src="Ice/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" width=200 height=200>
    <h1>Ice</h1>
</div>

Ice 是一款强大的 macOS 菜单栏管理工具。它的核心功能是隐藏和显示菜单栏项目，同时还提供了丰富的附加功能，使其成为最全面的菜单栏工具之一。

> 本项目 Fork 自 [jordanbaird/Ice](https://github.com/jordanbaird/Ice)，在原项目基础上进行了改进和本地化。

![Banner](https://github.com/user-attachments/assets/4423085c-4e4b-4f3d-ad0f-90a217c03470)

![Platform](https://img.shields.io/badge/platform-macOS-blue?style=flat-square)
![Requirements](https://img.shields.io/badge/requirements-macOS%2026%2B-fa4e49?style=flat-square)
[![License](https://img.shields.io/github/license/jordanbaird/Ice?style=flat-square)](LICENSE)

## 安装

### 手动安装

从 [Releases](../../releases/latest) 页面下载最新的 `Ice.dmg`，将 App 拖入 `Applications` 文件夹。

### 从源码构建

```sh
git clone https://github.com/<your-username>/Ice-re.git
cd Ice-re
open Ice.xcodeproj
```

在 Xcode 中设置你自己的 Development Team，然后 `Cmd+R` 运行。

### 构建 DMG

```sh
./package_dmg.sh
```

构建完成后 DMG 文件位于 `build/Ice.dmg`。

## 功能特性 / 路线图

### 菜单栏项目管理

- [x] Hide menu bar items
- [x] "Always-hidden" menu bar section
- [x] Show hidden menu bar items when hovering over the menu bar
- [x] Show hidden menu bar items when an empty area in the menu bar is clicked
- [x] Show hidden menu bar items by scrolling or swiping in the menu bar
- [x] Automatically rehide menu bar items
- [x] Hide application menus when they overlap with shown menu bar items
- [x] Drag and drop interface to arrange individual menu bar items
- [x] Display hidden menu bar items in a separate bar (e.g. for MacBooks with the notch)
- [x] Search menu bar items
- [x] Menu bar item spacing (BETA)
- [ ] Profiles for menu bar layout
- [ ] Individual spacer items
- [ ] Menu bar item groups
- [ ] Show menu bar items when trigger conditions are met

### 菜单栏外观

- [x] Menu bar tint (solid and gradient)
- [x] Menu bar shadow
- [x] Menu bar border
- [x] Custom menu bar shapes (rounded and/or split)
- [ ] Remove background behind menu bar
- [ ] Rounded screen corners
- [ ] Different settings for light/dark mode

### 快捷键

- [x] Toggle individual menu bar sections
- [x] Show the search panel
- [x] Enable/disable the Ice Bar
- [x] Show/hide section divider icons
- [x] Toggle application menus
- [ ] Enable/disable auto rehide
- [ ] Temporarily show individual menu bar items

### 其他

- [x] Launch at login
- [x] Automatic updates
- [ ] Menu bar widgets

## 为什么 Ice 只支持 macOS 26 及以上？

Ice 使用了 macOS 26 才提供的系统 API，因此不计划支持更早版本的 macOS。

## 截图展示

#### 在菜单栏下方显示隐藏的项目

![Ice Bar](https://github.com/user-attachments/assets/f1429589-6186-4e1b-8aef-592219d49b9b)

#### 拖拽排列菜单栏项目

![Menu Bar Layout](https://github.com/user-attachments/assets/095442ba-f2d0-4bb4-9632-91e26ef8d45b)

#### 自定义菜单栏外观

![Menu Bar Appearance](https://github.com/user-attachments/assets/8c22c185-c3d2-49bb-971e-e1fc17df04b3)

#### 菜单栏项目搜索

![Menu Bar Item Search](https://github.com/user-attachments/assets/d1a7df3a-4989-4077-a0b1-8e7d5a1ba5b8)

#### 自定义菜单栏项目间距

![Menu Bar Item Spacing](https://github.com/user-attachments/assets/b196aa7e-184a-4d4c-b040-502f4aae40a6)

## 贡献

欢迎任何形式的贡献！请阅读 [贡献指南](CONTRIBUTING.md) 了解详情。

## 致谢

本项目 Fork 自 [jordanbaird/Ice](https://github.com/jordanbaird/Ice)，感谢原作者 [Jordan Baird](https://github.com/jordanbaird) 的出色工作。

项目使用的开源依赖：

- [Sparkle](https://github.com/sparkle-project/Sparkle) — 自动更新框架
- [LaunchAtLogin-Modern](https://github.com/sindresorhus/LaunchAtLogin-Modern) — 开机启动支持
- [AXSwift](https://github.com/tmandry/AXSwift) — 辅助功能 API 封装
- [CompactSlider](https://github.com/buh/CompactSlider) — 紧凑滑块控件

## 许可证

Ice 基于 [GPL-3.0 许可证](LICENSE) 发布。
