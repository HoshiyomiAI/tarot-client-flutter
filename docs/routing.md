# 路由与导航（Routing）

本项目使用 `go_router` 实现声明式路由，并通过 `ShellRoute` 承载底部导航（Home / Chat / Profile）。

## 路由结构

顶层结构：
- `ShellRoute`（带底部导航的容器）
  - `/home`
  - `/chat`
  - `/profile`
- 独立页面：
  - `/calendar`
  - `/settings`
  - `/detail`

## 关键代码位置
- `lib/router.dart`：定义 `GoRouter`、`ShellRoute` 与各页面 `GoRoute`
- `lib/screens/`：页面实现（例如 `home.dart`、`chat.dart`）
- `lib/app.dart`：App 根部件中注入路由

## 添加新页面
1. 在 `lib/screens/` 新建页面文件，例如 `notifications.dart`
2. 在 `lib/router.dart` 中追加路由：
   ```dart
   GoRoute(
     path: '/notifications',
     name: 'notifications',
     builder: (context, state) => const NotificationsScreen(),
   )
   ```
3. 如需出现在底部导航：将其加入 `ShellRoute` 的 `routes`，并在底部导航组件增加对应条目。

## 传参与返回
- 路由参数：`state.pathParameters` / `state.queryParameters`
- 返回上一页：`context.pop()` 或 `Navigator.of(context).pop()`
- 命名路由跳转：`context.goNamed('detail', params: {...}, queryParams: {...})`

## 路由守卫与权限
- 建议通过 `redirect` 或在页面 `initState` 中检查登录态/权限
- 对复杂场景可引入中间件风格的封装（例如统一鉴权函数）

## 深链接与恢复
- `go_router` 支持浏览器地址栏直达与刷新状态恢复
- 复杂状态建议结合状态管理库，避免页面恢复时数据丢失

