# 构建与发布（Build & Deploy）

本章整理各平台的构建命令与发布注意事项，并提供常见问题排查。

## 构建命令

Web：
```bash
flutter build web --release
```

Android：
```bash
flutter build apk --release
```

iOS：
```bash
flutter build ios --release
```

Windows：
```bash
flutter build windows --release
```

macOS：
```bash
flutter build macos --release
```

Linux：
```bash
flutter build linux --release
```

> 提示：可在 IDE 中使用「Build/Run」任务，无需命令行。

## 发布建议
- Web：静态资源托管（Nginx/Netlify/Cloudflare Pages），注意 `baseHref`
- Android：签名与版本号管理，遵循商店政策
- iOS：证书与描述文件，TestFlight/审核流程
- 桌面：分发包与自动更新策略（按团队约定）

## 常见问题排查（Troubleshooting）
- 端口占用：变更运行端口或关闭占用进程
- 热重载未生效：确认使用 Debug 模式，检查 `flutter run` 输出
- 平台依赖缺失：按平台提示安装工具链（Xcode/Android SDK）
- 构建失败：清理缓存 `flutter clean` 后重试；检查 `pubspec.yaml`

