@echo off
setlocal
where node >nul 2>nul || (echo Node.js 20.19+ is required. & exit /b 1)
if not exist node_modules\@maazsohail11\pdf-editor-sdk (
  echo Installing the local SDK artifact...
  call npm install --no-audit --no-fund || exit /b 1
)
echo Starting the local SDK Playground...
node host-server.mjs
