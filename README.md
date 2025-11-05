# Tarot Minimal

一个最小可运行的 Flutter 客户端脚手架，聚焦于「路由、底部导航、基础页面」的快速搭建与演示，适合作为项目起步模板。

> 详细文档请查看 `docs/`：
> - `docs/overview.md`（项目概览与目标）
> - `docs/routing.md`（路由架构与扩展实践）
> - `docs/ui.md`（基础 UI/主题约定与组件指引）
> - `docs/build_deploy.md`（构建与发布、常见问题）

## 特性

- 基于 `go_router` 的路由管理，支持嵌套与独立页面转场
- 底部导航（ShellRoute）承载多页面：`home / chat / profile`
- 额外页面：`calendar`（自顶下落转场）、`settings`、`detail`
- 轻量主题与样式约定，支持空安全与基本代码规范

> 当前功能定位为最小化骨架，便于在此基础上扩展业务模块与交互组件。

## 环境要求

- Flutter SDK（3.x+）
- Dart（与 Flutter SDK 配套版本）
- 可选：Android/iOS/Windows/Web 对应的构建环境（按需安装）

## 快速开始

1) 安装依赖：

```bash
flutter pub get
```

2) 运行到任意设备：

```bash
# 自动选择可用设备
flutter run

# 指定平台（示例）
flutter run -d windows
flutter run -d android
flutter run -d chrome
```

3) Web 预览（需启用 Flutter Web）：

```bash
# 首次启用（如未启用）
flutter config --enable-web

# 使用内置浏览器设备或无头 web-server
flutter run -d chrome
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080
```

> 提示：如你使用 IDE（Android Studio / VS Code），可以通过「Run/Debug」直接运行，无需命令行。

## 项目结构

```
lib/
├── app.dart          # 应用根部，主题/路由装配
├── main.dart         # 入口，运行 App
├── router.dart       # go_router 配置及路由声明
├── screens/          # 页面
│   ├── home.dart
│   ├── chat.dart
│   ├── profile.dart
│   ├── calendar.dart # 自顶下落转场演示
│   ├── settings.dart
│   └── detail.dart
└── widgets/          # 公共组件
```

## 路由与导航

- ShellRoute 承载底部导航：
  - `/home`、`/chat`、`/profile`
- 顶层独立页面：
- `/calendar`（自顶下落转场）
  - `/settings`、`/detail`

更多路由说明与扩展方式见 `docs/routing.md`。

## 构建与发布

```bash
# Web（构建到 build/web）
flutter build web

# Windows（需安装 Windows 桌面开发依赖）
flutter build windows

# Android（需配置 Android SDK / 签名按需处理）
flutter build apk
```

更多平台构建细节与发布建议见 `docs/build_deploy.md`。

## 验证清单

- 启动应用后，可在底部导航间切换三个占位页
- 点击 AppBar 的「日历」图标，转场至 Calendar 页（自顶下落）
- 点击 AppBar 的「设置」图标，进入 Settings 占位页

若你正在开发新模块，可在 `docs/overview.md` 的「下一步」章节追加你的目标与里程碑。

## 常见问题

- Web 端口被占用：
  - 变更端口，例如：`flutter run -d web-server --web-port 8081`
- 热重载未生效：
  - 确认使用 `flutter run` 的调试模式，且 IDE/终端显示 `r`/`R` 热重载提示
- Windows/Android 构建失败：
  - 按需安装对应平台的 SDK 与工具链，并执行 `flutter doctor` 以诊断缺少项

## 下一步

- 接入真实数据与状态管理（如 Riverpod/Bloc）
- 丰富主题与组件库，完善 UI 细节
- 根据业务需求扩展路由与页面
