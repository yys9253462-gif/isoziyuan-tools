# Works Blog - 基于 Hono 和 Cloudflare Pages 的轻量级博客系统

这是一个高性能、低延迟的博客系统，完全运行在 Cloudflare 的全球边缘网络上。

它放弃了传统的 Next.js 架构，转而采用 **Hono** 框架，配合 **Cloudflare Pages Functions** 和 **D1 Database**，实现了极致的加载速度和零冷启动延迟。

## 🚀 技术栈架构

*   **核心框架**: [Hono](https://hono.dev/) - 专为边缘计算设计的超快 Web 标准框架。
*   **运行时**: [Cloudflare Pages Functions](https://developers.cloudflare.com/pages/platform/functions/) - 代码在全球 Cloudflare 节点上运行。
*   **数据库**: [Cloudflare D1](https://developers.cloudflare.com/d1/) - 基于 SQLite 的原生 Serverless 数据库。
*   **ORM**: [Drizzle ORM](https://orm.drizzle.team/) - 轻量级、类型安全的 TypeScript ORM。
*   **语言**: TypeScript.
*   **样式**: Tailwind CSS (通过 CDN 引入，保持构建简单)。
*   **包管理**: pnpm.

## ✨ 功能特性

### 公开页面
*   **首页**: 展示已发布的文章列表，按时间倒序排列。
*   **文章详情页**: 渲染 Markdown 格式的文章内容（目前支持基础 HTML 渲染）。
*   **全站汉化**: 友好的中文界面。

### 管理后台 (`/admin`)
*   **安全认证**: 基于 Cookie 的简单密码认证系统。
*   **仪表盘**: 查看所有文章（包括草稿），管理文章状态。
*   **创建文章**: 支持设置标题、URL 别名 (slug)、内容及发布状态。
*   **编辑文章**: 修改现有文章内容和元数据。
*   **删除文章**: 安全删除过时内容。

## 📂 项目结构

```
.
├── functions/
│   └── [[path]].tsx    # 核心应用逻辑。所有路由、UI 渲染、API 处理都在这里 (Hono单文件模式)
├── db/
│   └── schema.ts       # Drizzle 数据库模型定义 (Posts 表结构)
├── public/
│   └── styles.css      # 静态资源文件
├── drizzle/            # 数据库迁移文件
├── wrangler.toml       # Cloudflare 部署配置文件
├── package.json        # 项目依赖
└── tsconfig.json       # TypeScript 配置
```

## 🛠️ 本地开发指南

### 前置要求
*   Node.js (LTS 版本)
*   pnpm
*   Cloudflare Wrangler CLI (`pnpm add -g wrangler`)

### 安装依赖
```bash
pnpm install
```

### 初始化数据库 (本地)
本地开发时，我们需要基于 schema 生成 SQLite 数据库文件：
```bash
# 生成迁移文件
pnpm run generate

# 应用迁移到本地 D1 模拟环境
npx wrangler d1 execute DB --local --file=./drizzle/0000_xxxx.sql
# 注意：你需要根据实际生成的 sql 文件名替换上面的路径
# 或者直接使用 drizzle-kit migrate (如果配置了)
```

### 启动开发服务器
```bash
pnpm dev
# 或者
wrangler pages dev
```
访问 `http://localhost:8788` 即可预览。

## ☁️ 部署指南 (Cloudflare Pages)

本项目设计为与 GitHub 集成自动部署。

### 1. 准备 Cloudflare D1 数据库
在 Cloudflare Dashboard 中：
1.  进入 **Workers & Pages** -> **D1**.
2.  创建一个新数据库（例如命名为 `my-blog-db`）。
3.  复制数据库的 ID。
4.  在本地 `wrangler.toml` 文件中，更新 `database_id`。

### 2. 配置 Cloudflare Pages
1.  进入 **Workers & Pages** -> **Create application** -> **Pages** -> **Connect to Git**.
2.  选择本项目的 GitHub 仓库。
3.  **构建配置 (Build configuration)**:
    *   **Framework preset**: 选择 `None` (非常重要！不要选 Next.js)。
    *   **Build command**: `exit 0` (或者留空，Hono 在 Pages 模式下不需要构建步骤，只需依赖安装)。
    *   **Build output directory**: `public`。
4.  保存并部署。

### 3. 环境变量设置
部署完成后，进入项目的 **Settings** -> **Environment variables**:
1.  **添加变量**:
    *   `ADMIN_PASSWORD`: 设置你的后台登录密码。
    *   `SESSION_PASSWORD`: 设置一个足够长的随机字符串（至少32位），用于加密 Session Cookie。

### 4. 绑定数据库
在 **Settings** -> **Functions** -> **D1 Database Bindings**:
1.  **Variable name**: 输入 `DB` (必须大写，与代码一致)。
2.  **D1 Database**: 选择你在第 1 步创建的数据库。
3.  重新部署 (Redeploy) 以使绑定生效。

### 5. 初始化数据库 (推荐)
无需使用命令行，我们已经内置了网页版初始化工具：

1.  部署完成后，访问您的博客地址：`https://works-blog.pages.dev/admin/setup` (请替换为您的实际域名)。
2.  输入您在环境变量中设置的 `ADMIN_PASSWORD`。
3.  点击“初始化数据库”按钮。
4.  看到成功提示后，即可访问 `/admin` 进行登录。

### (可选) 只有命令行能用时：
```bash
npx wrangler d1 execute DB --remote --file=./drizzle/0000_closed_morbius.sql
```

## 📝 逻辑说明

**为什么不再使用 Next.js?**
Next.js 的 Edge Runtime 兼容性在 Cloudflare Pages 上有时会遇到由于 Node.js API 缺失导致的 500 错误。
切换到 Hono 后：
1.  **更轻量**: 没有复杂的 Webpack/Turbopack 打包过程。
2.  **更原生**: Hono 直接输出 Cloudflare Worker 代码，稳定性极高。
3.  **同构路由**: 我们使用 `functions/[[path]].tsx` 捕获所有请求，无论是 API 还是 页面渲染，统一处理，简化了心智模型。
