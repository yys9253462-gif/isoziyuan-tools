# isoziyuan-tools (爱搜资源 - Cloudflare 全能免费建站工具箱)

基于 Cloudflare 免费服务打造的全自动化建站工具箱，支持一键搭建各类轻量高效的个人云端服务。

## 🚀 已支持模块与开源选型

1. **个人导航站 (`nav`)**
   - 架构：Cloudflare Pages + D1 数据库
   - 特色：免服务器、响应式自适应布局、自带后台管理、支持分类/图标/密码认证。

2. **免费云网盘 (`drive`)**
   - 源码：`isoziyuan-pan` 官方成熟源码（脱敏纯净版）
   - 架构：Cloudflare Pages + D1 数据库 + R2 存储桶
   - 特色：10GB 免费空间、0 出站流量费、支持提取码取件页、文件夹管理、文件直链下载与访问控制。

3. **个人轻量博客·纯净版 (`blog-lite` - 无需 R2)**
   - 源码：`sky300/works-blog`（基于 Hono + Drizzle ORM + D1 + Pages Functions）
   - 架构：Cloudflare Pages + D1 数据库
   - 特色：专为未开通 R2 存储的用户设计，零信用卡门槛，自带 `/admin` 独立后台，在线撰写与管理文章。

4. **个人全能博客·图床版 (`blog-pro` - 带 R2)**
   - 源码：`openRin/Rin`（GitHub 3000+ Star 高颜值开源博客系统）
   - 架构：Cloudflare Pages + Workers + D1 数据库 + R2 存储桶
   - 特色：集成了完整的 GitHub OAuth 登录、实时草稿保存、R2 图床拖拽直传、友链健康检查与 Webhook 提醒。

5. **账号与资源管理**
   - 支持一键识别/清除授权
   - 支持一键扫描与删除所有关联的远程资源

## 🛠️ 快速开始
双击运行 `一键部署工具箱.bat`，按照控制台菜单提示选择对应编号即可。
全部流程自动检测环境、调起浏览器授权并完成云端建库建桶与部署。

## 📌 后续规划
- [ ] 独立免费图床 (Pages + R2 + 自动生成 Markdown/HTML 外链)
- [ ] 短链接服务 (Pages + KV 高速跳转)
- [ ] 个人单页/简历/作品集展示页
