# 贡献指南

感谢你对 Ice 项目的关注！我们欢迎所有形式的贡献，包括但不限于：

- 🐛 Bug 报告
- 💡 功能建议
- 📝 文档改善
- 🔧 代码贡献

## 开始之前

### 环境要求

| 工具 | 版本要求 |
|------|----------|
| macOS | 26.0 及以上 |
| Xcode | 最新稳定版 |
| Swift | 5.0+ |
| Git | 任意最新版本 |

### 本地开发设置

1. **Fork 本仓库**并克隆到本地：

   ```sh
   git clone https://github.com/<your-username>/Ice-re.git
   cd Ice-re
   ```

2. **打开 Xcode 项目**：

   ```sh
   open Ice.xcodeproj
   ```

3. **设置开发团队**：在 Xcode 中选择你自己的 Apple Developer Team（项目中 `DEVELOPMENT_TEAM` 已留空，需要你在本地设置）。

4. **解析依赖**：Xcode 会自动解析 Swift Package Manager 依赖。

5. **构建并运行**：选择 `Ice` scheme，按 `Cmd+R` 运行。

## 提交代码

### 分支策略

- `main` - 主分支，保持稳定
- `feature/*` - 新功能开发
- `fix/*` - Bug 修复
- `docs/*` - 文档更新

### 提交流程

1. 从 `main` 创建新分支：

   ```sh
   git checkout -b feature/your-feature-name
   ```

2. 在新分支上进行开发，确保：
   - 代码可以编译通过
   - 遵循项目现有的代码风格
   - 新增功能有适当的注释

3. 提交你的更改：

   ```sh
   git add .
   git commit -m "feat: 简短描述你的更改"
   ```

4. 推送分支并创建 Pull Request：

   ```sh
   git push origin feature/your-feature-name
   ```

### Commit 规范

我们建议使用 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

| 前缀 | 用途 |
|------|------|
| `feat:` | 新功能 |
| `fix:` | Bug 修复 |
| `docs:` | 文档更新 |
| `style:` | 代码格式调整（不影响功能） |
| `refactor:` | 代码重构 |
| `perf:` | 性能优化 |
| `chore:` | 构建/工具链更新 |

## 报告 Bug

请通过 [Issues](../../issues) 提交 Bug 报告，并包含以下信息：

1. **macOS 版本**
2. **Ice 版本**
3. **Bug 描述**：期望行为 vs 实际行为
4. **复现步骤**：尽可能详细
5. **截图**（如适用）

## 功能建议

欢迎通过 [Issues](../../issues) 提交功能建议。请先搜索是否已有类似建议，避免重复。

## 代码风格

- 遵循 Swift 官方 [API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- 使用 4 空格缩进
- 保持函数简短，单一职责
- 为公开 API 添加文档注释（`///`）

## 许可证

提交代码即表示你同意将代码以 [GPL-3.0](LICENSE) 许可证发布。
