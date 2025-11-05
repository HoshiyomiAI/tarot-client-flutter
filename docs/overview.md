# 项目概览（Overview）

本仓库提供一个「最小可运行」的 Flutter 客户端模板，重点演示：
- 路由架构与底部导航（使用 `go_router` 与 `ShellRoute`）
- 基础页面骨架与占位模块（`home/chat/profile/calendar/settings/detail`）
- 轻量主题与基本代码规范（空安全、分析选项）

## 目标与适用场景
- 作为新项目的起步模板：快速拉起路由与页面结构
- 作为组件与交互实验场：在 `screens/` 与 `widgets/` 下追加你的模块
- 作为构建/发布流程的演示：参考 `docs/build_deploy.md`

## 环境要求
- Flutter：3.x 及以上（推荐）
- Dart：2.19+（随 Flutter 安装）
- IDE：Android Studio / VS Code（推荐）
- 可选平台：Web、Android、iOS、Windows、macOS、Linux

## 快速开始
1. 安装依赖：`flutter pub get`
2. 运行：
   - IDE：使用 Run/Debug（推荐）
   - 命令行：`flutter run` 或指定设备 `flutter run -d chrome`
3. 目录感知：从 `lib/router.dart` 与 `lib/screens/` 开始阅读

## 项目结构说明
- `lib/app.dart`：App 根部件（主题与顶层配置）
- `lib/main.dart`：入口函数（运行 `runApp`）
- `lib/router.dart`：`GoRouter` 路由表与 `ShellRoute` 底部导航容器
- `lib/screens/`：页面模块；每个页面一个文件或子目录
- `lib/widgets/`：可复用组件；通用 UI 与交互逻辑

## 下一步建议（Roadmap）
- 状态管理：引入 `provider` / `riverpod` / `bloc`
- 主题扩展：暗色模式、排版与组件统一规范
- 组件库：通用卡片、按钮、弹窗与列表，沉淀到 `widgets/`
- 路由扩展：深链接、权限与守卫、参数解析与恢复
- 测试加强：Widget 测试与路由跳转测试（见 `test/widget_test.dart`）

## 维护与贡献
- 代码风格：参考 `analysis_options.yaml`
- 分支与提交流程：按团队约定（此模板不强制）
- 文档维护：在 `docs/` 中追加你的模块说明与变更记录

