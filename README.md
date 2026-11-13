# Dore

原生 macOS 状态栏硬件监控工具。

- 总览：CPU、内存、GPU 使用率圆环。
- 状态栏：CPU 曲线、内存、CPU 温度，或整机功耗。
- 硬件详情：温度传感器、CPU / GPU 分项功耗、整机功耗和风扇转速。
- DoreHelper：随应用嵌入的只读 XPC 服务；主应用保持沙盒开启。

## 开发

在 Xcode 中打开 `Dore.xcodeproj`，选择 `Dore` scheme 和 My Mac，编译运行。
硬件读数依赖机型与系统提供的接口；目前实测 Apple M5 Max / macOS 27.2。

## 分支

- `main`：当前原生硬件监控版本，保留原仓库及新工程的提交历史。
- `codex/legacy`：迁移前的传统版本（网络速度状态栏工具），保留旧代码、文档和当时的本地状态。

原有发布版本仍可在 [Releases](https://github.com/weihas/Dore/releases) 查看。

## 许可

[MIT](LICENSE)
