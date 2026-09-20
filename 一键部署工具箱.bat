@echo off
rem =======================================================
rem 爱搜资源 - Cloudflare 全能网站一键搭建工具箱
rem 项目: https://github.com/yys9253462-gif/isoziyuan-tools
rem 支持: 1. 个人导航站 (Pages + D1)
rem       2. 免费云网盘 (isoziyuan-pan: Pages + D1 + R2)
rem       3. 个人轻量博客 - 纯净版 (无需R2, 仅 Pages + D1)
rem       4. 个人全能博客 - 图床版 (带 R2 图片上传 + Pages + D1)
rem       5. 账号管理与资源清理
rem =======================================================
setlocal enabledelayedexpansion
title 爱搜资源 - Cloudflare 全能网站一键搭建工具箱
cd /d "%~dp0"

rem ---------- 自动检测并继承系统与代理配置 ----------
set "SYS_PROXY="
set "PROXY_ENABLED=0"
for /f "tokens=3" %%i in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable 2^>nul ^| findstr "0x1"') do (
    set "PROXY_ENABLED=1"
)
if "%PROXY_ENABLED%"=="1" (
    for /f "tokens=3" %%i in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer 2^>nul') do (
        set "SYS_PROXY=%%i"
    )
)

if not "%SYS_PROXY%"=="" goto check_proxy_format
netstat -ano | findstr /c":10808" >nul 2>nul
if not errorlevel 1 (
    set "SYS_PROXY=127.0.0.1:10808"
    goto check_proxy_format
)
netstat -ano | findstr /c":10809" >nul 2>nul
if not errorlevel 1 (
    set "SYS_PROXY=127.0.0.1:10809"
    goto check_proxy_format
)
netstat -ano | findstr /c":7890" >nul 2>nul
if not errorlevel 1 (
    set "SYS_PROXY=127.0.0.1:7890"
    goto check_proxy_format
)
:check_proxy_format

if "%SYS_PROXY%"=="" goto proxy_done
echo %SYS_PROXY% | findstr /i "://" >nul
if not errorlevel 1 goto proxy_ready
set "SYS_PROXY=http://%SYS_PROXY%"
:proxy_ready
set "HTTP_PROXY=%SYS_PROXY%"
set "HTTPS_PROXY=%SYS_PROXY%"
set "http_proxy=%SYS_PROXY%"
set "https_proxy=%SYS_PROXY%"
set "ALL_PROXY=%SYS_PROXY%"
set "all_proxy=%SYS_PROXY%"
echo [网络环境] 已成功挂接网络加速代理: %SYS_PROXY%
echo.
:proxy_done

echo ==================================================
echo   爱搜资源 - Cloudflare 全能网站一键搭建工具箱
echo   基于 Cloudflare 免费资源打造您的专属云端服务
echo ==================================================
echo.
echo 请选择要搭建或执行的功能:
echo   [1] 一键搭建 个人导航站 (Pages + D1 数据库)
echo   [2] 一键搭建 免费云网盘 (isoziyuan-pan: Pages + D1 + R2)
echo   [3] 一键搭建 个人轻量博客 [纯净版] (零门槛, 无需R2, 仅需D1)
echo   [4] 一键搭建 个人全能博客 [图床版] (带R2存储, 支持文章插图)
echo   [5] 清除 GitHub / Cloudflare 登录授权状态
echo   [6] 一键清理远程已建的 isoziyuan 相关项目
echo   [Q] 退出工具箱
echo.
choice /c 123456Q /m "请输入选项编号: "
if errorlevel 7 exit /b 0
if errorlevel 6 goto menu_cleanup
if errorlevel 5 goto menu_logout
if errorlevel 4 goto menu_blog_pro
if errorlevel 3 goto menu_blog_lite
if errorlevel 2 goto menu_drive
if errorlevel 1 goto menu_nav

rem ---------- 模式 1: 部署导航站 ----------
:menu_nav
echo.
echo ==================================================
echo   正在准备启动 [个人导航站] 部署流程...
echo ==================================================
if exist "nav\一键搭建导航站.bat" (
    cd nav
    call "一键搭建导航站.bat"
    cd ..
    pause
    exit /b 0
)
echo [X] 未找到 nav 源码目录，请检查仓库文件完整性。
pause
exit /b 1

rem ---------- 模式 2: 部署 R2 云网盘 ----------
:menu_drive
echo.
echo ==================================================
echo   正在准备启动 [免费云网盘] 部署流程...
echo ==================================================

echo [1/7] 检测基础运行环境 (Node.js)...
where node >nul 2>nul
if errorlevel 1 (
    echo [X] 未检测到 Node.js，请先安装 Node.js 环境。
    pause
    exit /b 1
)
echo [OK] Node.js 环境正常

echo [2/7] 检查 Cloudflare 授权状态...
call npx wrangler whoami >nul 2>nul
if errorlevel 1 (
    echo 正在调起浏览器进行 Cloudflare 授权...
    call npx wrangler login
)
echo [OK] Cloudflare 授权验证通过

set "BUCKET_NAME=isoziyuan-pan-bucket"
echo [3/7] 检查并创建 R2 存储桶: %BUCKET_NAME% ...
call npx wrangler r2 bucket create %BUCKET_NAME% >nul 2>nul
echo [OK] R2 存储桶准备就绪 (10GB 免费容量)

set "D1_NAME=isoziyuan-pan-db"
echo [4/7] 检查并创建 D1 数据库: %D1_NAME% ...
cd drive
set "PAN_DB_ID="
set "DB_LIST_TMP=%TEMP%\pan_d1_list_%RANDOM%.json"
call npx wrangler d1 list --json > "%DB_LIST_TMP%" 2>nul
powershell -NoProfile -Command "$data=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText('%DB_LIST_TMP%')); foreach($item in @($data)){if($item.name -eq '%D1_NAME%'){[Console]::Write($item.uuid); break}}" > "%TEMP%\pan_dbid.tmp" 2>nul
if exist "%TEMP%\pan_dbid.tmp" set /p PAN_DB_ID=<"%TEMP%\pan_dbid.tmp"
if exist "%DB_LIST_TMP%" del "%DB_LIST_TMP%" >nul 2>nul
if exist "%TEMP%\pan_dbid.tmp" del "%TEMP%\pan_dbid.tmp" >nul 2>nul

if not defined PAN_DB_ID (
    echo   正在创建全新 D1 数据库...
    call npx wrangler d1 create %D1_NAME% > "%TEMP%\pan_d1_create.txt" 2>&1
    powershell -NoProfile -Command "$text=[IO.File]::ReadAllText('%TEMP%\pan_d1_create.txt'); $m=[regex]::Match($text,'(?i)[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'); if($m.Success){[Console]::Write($m.Value)}" > "%TEMP%\pan_dbid.tmp" 2>nul
    if exist "%TEMP%\pan_dbid.tmp" set /p PAN_DB_ID=<"%TEMP%\pan_dbid.tmp"
    if exist "%TEMP%\pan_d1_create.txt" del "%TEMP%\pan_d1_create.txt" >nul 2>nul
    if exist "%TEMP%\pan_dbid.tmp" del "%TEMP%\pan_dbid.tmp" >nul 2>nul
)

if not defined PAN_DB_ID (
    echo [X] 未能获取或创建 D1 数据库，请检查网络后重试。
    cd ..
    pause
    exit /b 1
)
echo [OK] D1 数据库准备就绪: %PAN_DB_ID%

powershell -NoProfile -Command "$f='wrangler.jsonc'; $t=[IO.File]::ReadAllText($f); $t=[regex]::Replace($t,'(?i)(\"database_id\":\s*\")[^\"]*(\")','$1'+$env:PAN_DB_ID+'$2'); [IO.File]::WriteAllText($f,$t)"

echo [5/7] 初始化网盘数据表结构 (schema.sql)...
call npx wrangler d1 execute DB --remote --file schema.sql --yes >nul 2>nul
echo [OK] 数据表初始化完成

echo [6/7] 创建 Cloudflare Pages 项目与配置密码...
call npx wrangler pages project create isoziyuan-pan --production-branch main >nul 2>nul

echo.
echo 请设置网盘管理员密码 (用于后台 /admin.html 管理、上传与提取码设置):
set "PAN_PASS="
set /p PAN_PASS=请输入 6-32 位密码 (直接回车生成随机强密码): 
if "%PAN_PASS%"=="" (
    powershell -NoProfile -Command "[Console]::Write('Pan'+[Guid]::NewGuid().ToString('N').Substring(0,10)+'2026')" > "%TEMP%\pan_pass.tmp"
    if exist "%TEMP%\pan_pass.tmp" set /p PAN_PASS=<"%TEMP%\pan_pass.tmp"
    if exist "%TEMP%\pan_pass.tmp" del "%TEMP%\pan_pass.tmp" >nul 2>nul
)
if not defined PAN_PASS set "PAN_PASS=PanAdmin2026"

echo 您的网盘管理密码为: %PAN_PASS%
echo (正在安全加密写入 Cloudflare Secrets...)

powershell -NoProfile -Command "[IO.File]::WriteAllText('panpass.tmp','%PAN_PASS%',[Text.UTF8Encoding]::new($false))"
call npx wrangler pages secret put ADMIN_PASSWORD --project-name isoziyuan-pan < panpass.tmp >nul 2>nul
if exist panpass.tmp del panpass.tmp

echo.
echo [7/7] 正在部署网盘到 Cloudflare 全球边缘网络...
call npx wrangler pages deploy . --project-name isoziyuan-pan --branch main --commit-dirty=true

echo.
echo ==================================================
echo   恭喜！爱搜云盘部署成功！
echo   网盘前台: https://isoziyuan-pan.pages.dev
echo   提取文件: https://isoziyuan-pan.pages.dev/pickup.html
echo   管理后台: https://isoziyuan-pan.pages.dev/admin.html
echo   管理密码: %PAN_PASS%
echo ==================================================
echo.

set "DESK_FILE=%USERPROFILE%\Desktop\爱搜云盘信息.txt"
> "%DESK_FILE%" echo ==============================
>> "%DESK_FILE%" echo 爱搜云盘 - 部署凭据
>> "%DESK_FILE%" echo ==============================
>> "%DESK_FILE%" echo 网盘前台: https://isoziyuan-pan.pages.dev
>> "%DESK_FILE%" echo 提取页面: https://isoziyuan-pan.pages.dev/pickup.html
>> "%DESK_FILE%" echo 管理后台: https://isoziyuan-pan.pages.dev/admin.html
>> "%DESK_FILE%" echo 管理账号: admin
>> "%DESK_FILE%" echo 管理密码: %PAN_PASS%
>> "%DESK_FILE%" echo 部署时间: %date% %time%
echo 账号与访问信息已备份至桌面: 爱搜云盘信息.txt
cd ..
pause
exit /b 0

rem ---------- 模式 3: 部署轻量博客 (无R2) ----------
:menu_blog_lite
echo.
echo ==================================================
echo   正在准备启动 [个人轻量博客·纯净版] (无需R2) 部署流程...
echo ==================================================

echo [1/6] 检查环境与授权...
call npx wrangler whoami >nul 2>nul
if errorlevel 1 (
    echo 正在调起浏览器进行 Cloudflare 授权...
    call npx wrangler login
)
echo [OK] Cloudflare 授权验证通过

set "D1_NAME=isoziyuan-blog-lite-db"
echo [2/6] 检查并创建 D1 数据库: %D1_NAME% ...
cd blog-lite
set "BLOG_DB_ID="
set "DB_LIST_TMP=%TEMP%\blog_lite_d1_%RANDOM%.json"
call npx wrangler d1 list --json > "%DB_LIST_TMP%" 2>nul
powershell -NoProfile -Command "$data=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText('%DB_LIST_TMP%')); foreach($item in @($data)){if($item.name -eq '%D1_NAME%'){[Console]::Write($item.uuid); break}}" > "%TEMP%\blog_lite_dbid.tmp" 2>nul
if exist "%TEMP%\blog_lite_dbid.tmp" set /p BLOG_DB_ID=<"%TEMP%\blog_lite_dbid.tmp"
if exist "%DB_LIST_TMP%" del "%DB_LIST_TMP%" >nul 2>nul
if exist "%TEMP%\blog_lite_dbid.tmp" del "%TEMP%\blog_lite_dbid.tmp" >nul 2>nul

if not defined BLOG_DB_ID (
    echo   正在创建全新 D1 数据库...
    call npx wrangler d1 create %D1_NAME% > "%TEMP%\blog_lite_create.txt" 2>&1
    powershell -NoProfile -Command "$text=[IO.File]::ReadAllText('%TEMP%\blog_lite_create.txt'); $m=[regex]::Match($text,'(?i)[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'); if($m.Success){[Console]::Write($m.Value)}" > "%TEMP%\blog_lite_dbid.tmp" 2>nul
    if exist "%TEMP%\blog_lite_dbid.tmp" set /p BLOG_DB_ID=<"%TEMP%\blog_lite_dbid.tmp"
    if exist "%TEMP%\blog_lite_create.txt" del "%TEMP%\blog_lite_create.txt" >nul 2>nul
    if exist "%TEMP%\blog_lite_dbid.tmp" del "%TEMP%\blog_lite_dbid.tmp" >nul 2>nul
)

if not defined BLOG_DB_ID (
    echo [X] 未能获取或创建 D1 数据库。
    cd ..
    pause
    exit /b 1
)
echo [OK] D1 数据库准备就绪: %BLOG_DB_ID%

powershell -NoProfile -Command "$f='wrangler.jsonc'; $t=[IO.File]::ReadAllText($f); $t=[regex]::Replace($t,'(?i)(\"database_id\":\s*\")[^\"]*(\")','$1'+$env:BLOG_DB_ID+'$2'); [IO.File]::WriteAllText($f,$t)"

echo [3/6] 初始化博客数据表 (schema.sql)...
call npx wrangler d1 execute DB --remote --file schema.sql --yes >nul 2>nul
echo [OK] 数据表初始化完成

echo [4/6] 创建 Cloudflare Pages 项目...
call npx wrangler pages project create isoziyuan-blog-lite --production-branch main >nul 2>nul

echo [5/6] 设置后台发布密码...
set "BLOG_PASS="
set /p BLOG_PASS=请输入博客后台管理密码 (直接回车生成随机密码): 
if "%BLOG_PASS%"=="" set "BLOG_PASS=Blog%RANDOM%2026"
echo 您的博客管理密码为: %BLOG_PASS%

powershell -NoProfile -Command "[IO.File]::WriteAllText('blogpass.tmp','%BLOG_PASS%',[Text.UTF8Encoding]::new($false))"
call npx wrangler pages secret put ADMIN_PASSWORD --project-name isoziyuan-blog-lite < blogpass.tmp >nul 2>nul
if exist blogpass.tmp del blogpass.tmp

echo [6/6] 正在部署上线到全球边缘节点...
call npx wrangler pages deploy . --project-name isoziyuan-blog-lite --branch main --commit-dirty=true

echo.
echo ==================================================
echo   恭喜！轻量博客 (纯净版) 部署完成！
echo   博客首页: https://isoziyuan-blog-lite.pages.dev
echo   管理后台: https://isoziyuan-blog-lite.pages.dev/admin.html
echo   后台密码: %BLOG_PASS%
echo ==================================================
echo.

set "DESK_FILE=%USERPROFILE%\Desktop\轻量博客信息.txt"
> "%DESK_FILE%" echo ==============================
>> "%DESK_FILE%" echo 爱搜轻量博客 - 访问凭据
>> "%DESK_FILE%" echo ==============================
>> "%DESK_FILE%" echo 博客前台: https://isoziyuan-blog-lite.pages.dev
>> "%DESK_FILE%" echo 管理后台: https://isoziyuan-blog-lite.pages.dev/admin.html
>> "%DESK_FILE%" echo 管理密码: %BLOG_PASS%
>> "%DESK_FILE%" echo 部署时间: %date% %time%
echo 凭据信息已保存至桌面: 轻量博客信息.txt
cd ..
pause
exit /b 0

rem ---------- 模式 4: 部署全能博客 (带R2) ----------
:menu_blog_pro
echo.
echo ==================================================
echo   正在准备启动 [个人全能博客·图床版] (带R2) 部署流程...
echo ==================================================

echo [1/7] 检查环境与授权...
call npx wrangler whoami >nul 2>nul
if errorlevel 1 (
    echo 正在调起浏览器进行 Cloudflare 授权...
    call npx wrangler login
)
echo [OK] Cloudflare 授权验证通过

set "R2_NAME=isoziyuan-blog-media"
echo [2/7] 检查并创建 R2 媒体存储桶: %R2_NAME% ...
call npx wrangler r2 bucket create %R2_NAME% >nul 2>nul
echo [OK] R2 存储桶准备就绪

set "D1_NAME=isoziyuan-blog-pro-db"
echo [3/7] 检查并创建 D1 数据库: %D1_NAME% ...
cd blog-pro
set "BLOG_PRO_DB_ID="
set "DB_LIST_TMP=%TEMP%\blog_pro_d1_%RANDOM%.json"
call npx wrangler d1 list --json > "%DB_LIST_TMP%" 2>nul
powershell -NoProfile -Command "$data=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText('%DB_LIST_TMP%')); foreach($item in @($data)){if($item.name -eq '%D1_NAME%'){[Console]::Write($item.uuid); break}}" > "%TEMP%\blog_pro_dbid.tmp" 2>nul
if exist "%TEMP%\blog_pro_dbid.tmp" set /p BLOG_PRO_DB_ID=<"%TEMP%\blog_pro_dbid.tmp"
if exist "%DB_LIST_TMP%" del "%DB_LIST_TMP%" >nul 2>nul
if exist "%TEMP%\blog_pro_dbid.tmp" del "%TEMP%\blog_pro_dbid.tmp" >nul 2>nul

if not defined BLOG_PRO_DB_ID (
    echo   正在创建全新 D1 数据库...
    call npx wrangler d1 create %D1_NAME% > "%TEMP%\blog_pro_create.txt" 2>&1
    powershell -NoProfile -Command "$text=[IO.File]::ReadAllText('%TEMP%\blog_pro_create.txt'); $m=[regex]::Match($text,'(?i)[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'); if($m.Success){[Console]::Write($m.Value)}" > "%TEMP%\blog_pro_dbid.tmp" 2>nul
    if exist "%TEMP%\blog_pro_dbid.tmp" set /p BLOG_PRO_DB_ID=<"%TEMP%\blog_pro_dbid.tmp"
    if exist "%TEMP%\blog_pro_create.txt" del "%TEMP%\blog_pro_create.txt" >nul 2>nul
    if exist "%TEMP%\blog_pro_dbid.tmp" del "%TEMP%\blog_pro_dbid.tmp" >nul 2>nul
)

if not defined BLOG_PRO_DB_ID (
    echo [X] 未能获取或创建 D1 数据库。
    cd ..
    pause
    exit /b 1
)
echo [OK] D1 数据库准备就绪: %BLOG_PRO_DB_ID%

powershell -NoProfile -Command "$f='wrangler.jsonc'; $t=[IO.File]::ReadAllText($f); $t=[regex]::Replace($t,'(?i)(\"database_id\":\s*\")[^\"]*(\")','$1'+$env:BLOG_PRO_DB_ID+'$2'); [IO.File]::WriteAllText($f,$t)"

echo [4/7] 初始化博客数据表 (schema.sql)...
call npx wrangler d1 execute DB --remote --file schema.sql --yes >nul 2>nul
echo [OK] 数据表初始化完成

echo [5/7] 创建 Cloudflare Pages 项目...
call npx wrangler pages project create isoziyuan-blog-pro --production-branch main >nul 2>nul

echo [6/7] 设置后台发布密码...
set "BLOG_PASS="
set /p BLOG_PASS=请输入博客后台管理密码 (直接回车生成随机密码): 
if "%BLOG_PASS%"=="" set "BLOG_PASS=Blog%RANDOM%2026"
echo 您的博客管理密码为: %BLOG_PASS%

powershell -NoProfile -Command "[IO.File]::WriteAllText('blogpass.tmp','%BLOG_PASS%',[Text.UTF8Encoding]::new($false))"
call npx wrangler pages secret put ADMIN_PASSWORD --project-name isoziyuan-blog-pro < blogpass.tmp >nul 2>nul
if exist blogpass.tmp del blogpass.tmp

echo [7/7] 正在部署上线到全球边缘节点...
call npx wrangler pages deploy . --project-name isoziyuan-blog-pro --branch main --commit-dirty=true

echo.
echo ==================================================
echo   恭喜！全能博客 (图床版) 部署完成！
echo   博客首页: https://isoziyuan-blog-pro.pages.dev
echo   管理后台: https://isoziyuan-blog-pro.pages.dev/admin.html
echo   后台密码: %BLOG_PASS%
echo ==================================================
echo.

set "DESK_FILE=%USERPROFILE%\Desktop\全能博客信息.txt"
> "%DESK_FILE%" echo ==============================
>> "%DESK_FILE%" echo 爱搜全能博客 - 访问凭据
>> "%DESK_FILE%" echo ==============================
>> "%DESK_FILE%" echo 博客前台: https://isoziyuan-blog-pro.pages.dev
>> "%DESK_FILE%" echo 管理后台: https://isoziyuan-blog-pro.pages.dev/admin.html
>> "%DESK_FILE%" echo 管理密码: %BLOG_PASS%
>> "%DESK_FILE%" echo 部署时间: %date% %time%
echo 凭据信息已保存至桌面: 全能博客信息.txt
cd ..
pause
exit /b 0

rem ---------- 模式 5: 清除授权 ----------
:menu_logout
echo.
echo 正在清理本地 GitHub 与 Cloudflare 授权状态...
call gh auth logout --hostname github.com 2>nul
call npx wrangler logout 2>nul
echo [OK] 已清理所有登录状态。
pause
exit /b 0

rem ---------- 模式 6: 清理资源 ----------
:menu_cleanup
echo.
if exist "nav\一键搭建导航站.bat" (
    cd nav
    call "一键搭建导航站.bat" dry
    cd ..
)
pause
exit /b 0
