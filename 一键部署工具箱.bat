@echo off
rem =======================================================
rem 爱搜资源 - Cloudflare 全能网站一键搭建工具箱
rem 项目: https://github.com/yys9253462-gif/isoziyuan-tools
rem 支持: 1. 个人导航站 (Pages + D1)
rem       2. 免费云网盘 (Pages + R2 10G免流存储)
rem       3. 账号管理与资源清理
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
echo   [2] 一键搭建 免费云网盘 (Pages + R2 10G免流存储)
echo   [3] 清除 GitHub / Cloudflare 登录授权状态
echo   [4] 一键清理远程已建的 isoziyuan 相关项目
echo   [Q] 退出工具箱
echo.
choice /c 1234Q /m "请输入选项编号: "
if errorlevel 5 exit /b 0
if errorlevel 4 goto menu_cleanup
if errorlevel 3 goto menu_logout
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

rem 环境检测
echo [1/5] 检测基础运行环境...
where node >nul 2>nul
if errorlevel 1 (
    echo [X] 未检测到 Node.js，请先安装 Node.js 环境。
    pause
    exit /b 1
)
echo [OK] Node.js 环境正常

rem 登录检测
echo [2/5] 检查 Cloudflare 授权状态...
call npx wrangler whoami >nul 2>nul
if errorlevel 1 (
    echo 正在调起浏览器进行 Cloudflare 授权...
    call npx wrangler login
)
echo [OK] Cloudflare 授权验证通过

rem 创建 R2 存储桶
echo [3/5] 检查并创建 R2 存储桶: isoziyuan-drive-bucket ...
call npx wrangler r2 bucket create isoziyuan-drive-bucket >nul 2>nul
echo [OK] R2 存储桶准备就绪 (10GB 免费容量)

rem 部署 Pages 网盘前端与 API
echo [4/5] 部署网盘项目到 Cloudflare Pages ...
cd drive
call npx wrangler pages project create isoziyuan-drive --production-branch main >nul 2>nul

rem 设置管理员密码
echo.
echo 请设置网盘访问/管理密码 (直接回车生成随机密码):
set "DRIVE_PASS="
set /p DRIVE_PASS=密码 (6-32位字母数字): 
if "%DRIVE_PASS%"=="" set "DRIVE_PASS=Drive%RANDOM%2026"
echo 你的网盘管理密码为: %DRIVE_PASS%
echo (请妥善保存)

powershell -NoProfile -Command "[IO.File]::WriteAllText('drivepass.tmp','%DRIVE_PASS%',[Text.UTF8Encoding]::new($false))"
call npx wrangler pages secret put ADMIN_PASSWORD --project-name isoziyuan-drive < drivepass.tmp >nul 2>nul
if exist drivepass.tmp del drivepass.tmp

rem 部署
echo.
echo [5/5] 正在发布到全球边缘网络...
call npx wrangler pages deploy . --project-name isoziyuan-drive --branch main --commit-dirty=true

echo.
echo ==================================================
echo   恭喜！云网盘部署成功！
echo   管理密码: %DRIVE_PASS%
echo   访问地址: https://isoziyuan-drive.pages.dev
echo ==================================================
echo.
set "DESK_FILE=%USERPROFILE%\Desktop\爱搜云盘信息.txt"
> "%DESK_FILE%" echo ==============================
>> "%DESK_FILE%" echo 爱搜云盘 - 访问凭据
>> "%DESK_FILE%" echo ==============================
>> "%DESK_FILE%" echo 网盘网址: https://isoziyuan-drive.pages.dev
>> "%DESK_FILE%" echo 访问密码: %DRIVE_PASS%
>> "%DESK_FILE%" echo 部署时间: %date% %time%
echo 信息已备份至桌面: 爱搜云盘信息.txt
cd ..
pause
exit /b 0

rem ---------- 模式 3: 清除授权 ----------
:menu_logout
echo.
echo 正在清理本地 GitHub 与 Cloudflare 授权状态...
call gh auth logout --hostname github.com 2>nul
call npx wrangler logout 2>nul
echo [OK] 已清理所有登录状态。
pause
exit /b 0

rem ---------- 模式 4: 清理资源 ----------
:menu_cleanup
echo.
if exist "nav\一键搭建导航站.bat" (
    cd nav
    call "一键搭建导航站.bat" dry
    cd ..
)
pause
exit /b 0
