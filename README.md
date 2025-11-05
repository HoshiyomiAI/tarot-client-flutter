# Tarot Minimal

最小可运行的 Flutter 项目：仅包含路由、底部导航与占位页面。

## 依赖安装

```bash
flutter pub get
```

## 运行

```bash
# 任选其一设备
flutter run

# 如需 Web 预览（已安装 Flutter Web）：
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080
```

## 页面结构

- 底部导航（ShellRoute）：`/home`、`/chat`、`/profile`
- 额外路由：`/calendar`（自顶下落转场）、`/settings`、`/detail`

## 验证

- 打开应用，底部导航切换三个占位页
- 点击 AppBar 的日历图标，查看下落转场到 Calendar
- 点击 AppBar 的设置图标，进入设置占位页

