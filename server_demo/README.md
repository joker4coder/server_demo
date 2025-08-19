# Visionplay (server_demo)

这是一个 iOS 客户端应用，旨在为用户提供体育比赛视频上传、分析和集锦生成的功能。项目完全使用 SwiftUI 构建，并遵循了现代化的、功能驱动的 MVVM（Model-View-ViewModel）架构模式。

## ✨ 主要功能

- **用户认证**: 全功能的注册、登录、退出登录流程。
- **会话管理**: 支持短期（后台切换）和长期（天级）的会话保持逻辑。
- **视频上传**: 从用户相册选择并上传视频文件。
- **视频处理**: 客户端能够处理视频文件，并与服务器进行模拟通信以获取分析数据。
- **集锦生成**: 根据服务器返回的时间戳，在客户端本地生成并保存集锦视频。
- **数据持久化**: 使用 `UserDefaults` 存储用户配置和会话信息。
- **动态UI**: 个人信息等UI元素会根据当前登录的用户动态显示。

## 🛠️ 技术栈

- **UI**: SwiftUI
- **App Lifecycle**: SwiftUI App Life Cycle
- **异步处理**: Swift Concurrency (`async/await`)
- **视频与相册**: `AVFoundation`, `PhotosUI`
- **数据传递**: `Combine` (`ObservableObject`, `@Published`, `@EnvironmentObject`)

## 🚀 如何开始

### 环境要求

- macOS
- Xcode 15 或更高版本

### 安装与运行

1.  克隆本项目仓库到本地。
2.  使用 Xcode 打开 `server_demo.xcodeproj` 文件。
3.  在 Xcode 的顶部菜单中选择一个模拟器（如 iPhone 15 Pro）或连接一台物理设备。
4.  按下快捷键 `Cmd + R` 或点击 "Run" 按钮来编译并运行项目。

> **注意**: 项目中的视频上传功能需要连接到一个本地服务器。请在 `HomeView.swift` 文件中修改 `serverURL` 常量，以指向您的本地服务器地址。

## 📂 项目结构

项目采用功能驱动（Feature-based）的目录结构，清晰地分离了不同模块的关注点。

```
server_demo/
├───Application/         # App入口 (App struct) 及全局配置
│   ├───AppLaunchView.swift
│   └───server_demoApp.swift
│
├───Features/            # 核心功能模块
│   ├───Auth/            # 认证 (登录、注册)
│   │   ├───Views/
│   │   └───ViewModels/
│   ├───Home/            # 首页 (视频上传)
│   │   └───Views/
│   ├───Analysis/        # 分析页
│   │   └───Views/
│   └───Profile/         # 我的页面
│       └───Views/
│
├───Shared/              # 跨功能共享的代码
│   ├───Models/          # 共享数据模型
│   ├───ViewModels/      # 共享视图模型
│   ├───Views/           # 可复用的视图组件
│   └───Helpers/         # 工具类、扩展等
│
├───Resources/           # 资源文件
│   └───Assets.xcassets
│
└───server_demo.xcodeproj
```

## 🤝 如何贡献

我们欢迎各种形式的贡献。如果您有任何改进建议或发现了Bug，请随时提交 Pull Request 或创建 Issue。

1.  Fork 本项目。
2.  创建您的功能分支 (`git checkout -b feature/AmazingFeature`)。
3.  提交您的更改 (`git commit -m 'Add some AmazingFeature'`)。
4.  推送到分支 (`git push origin feature/AmazingFeature`)。
5.  打开一个 Pull Request。
