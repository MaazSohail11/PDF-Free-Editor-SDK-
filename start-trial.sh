#!/usr/bin/env sh
set -eu
command -v node >/dev/null 2>&1 || { echo "Node.js 20.19+ is required."; exit 1; }
if [ ! -d node_modules/@maazsohail11/pdf-editor-sdk ]; then
  echo "Installing the local SDK artifact..."
  npm install --no-audit --no-fund
fi
echo "Starting the local SDK Playground..."
node host-server.mjs
