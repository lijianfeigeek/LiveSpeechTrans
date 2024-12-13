# LiveSpeechTrans

   LiveSpeechTrans 是一个实时语音翻译应用，基于 SwiftUI 开发，支持实时语音识别和多语言翻译功能。

   ## 功能特点

   - 实时语音识别
   - 多语言翻译支持
   - 聊天界面展示翻译历史
   - 简洁直观的用户界面
   - 支持深色/浅色模式

   ## 技术栈

   - Swift 6.0
   - SwiftUI
   - Speech Framework
   - AVFoundation
   - Xcode 16

   ## 系统要求

   - iOS 17.0 或更高版本
   - Xcode 16 或更高版本
   - 麦克风权限
   - 语音识别权限

   ## 安装说明

   1. 克隆项目到本地：
   ```bash
   git clone https://github.com/lijianfeigeek/LiveSpeechTrans.git
   ```

   2. 使用 Xcode 打开 LiveSpeechTrans.xcodeproj
   3. 选择目标设备或模拟器
   4. 点击运行按钮或按下 Cmd + R

   ## 使用说明

   1. 首次启动时，请允许应用访问麦克风和语音识别权限
   2. 点击麦克风按钮开始录音
   3. 说话时会自动进行语音识别
   4. 识别结果会实时显示在界面上
   5. 可以在设置中选择目标翻译语言

   ## 项目结构

   ```
   LiveSpeechTrans/
   ├── App/
   │   └── LiveSpeechTransApp.swift     # 应用程序入口
   ├── Views/
   │   ├── ContentView.swift            # 主界面视图
   │   ├── ChatView.swift               # 聊天历史视图
   │   ├── RecordButton.swift           # 录音按钮组件
   │   └── TranslationView.swift        # 翻译结果展示视图
   ├── Models/
   │   ├── TranslationModel.swift       # 翻译数据模型
   │   └── ChatMessage.swift            # 聊天消息模型
   ├── Services/
   │   ├── SpeechRecognizer.swift       # 语音识别服务
   │   └── TranslationService.swift     # 翻译服务
   ├── Utils/
   │   ├── AudioManager.swift           # 音频管理工具
   │   └── Permissions.swift            # 权限管理工具
   └── Resources/
       ├── Assets.xcassets              # 图片资源
       └── Info.plist                   # 应用配置文件
   ```

   ### 主要组件说明

   - **App**: 包含应用程序的入口点和主要配置
   - **Views**: 包含所有用户界面相关的视图组件
   - **Models**: 定义应用程序的数据模型和状态
   - **Services**: 处理核心功能如语音识别和翻译
   - **Utils**: 包含各种辅助工具和通用功能
   - **Resources**: 存储应用资源和配置文件

   ## 许可证

   MIT License

   ## 贡献指南

   欢迎提交 Pull Request 或创建 Issue。