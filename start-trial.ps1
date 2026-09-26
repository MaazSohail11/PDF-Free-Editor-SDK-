[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$minimumNode = [version]'20.19.0'
$artifactUrl = 'https://raw.githubusercontent.com/MaazSohail11/PDF-Free-Editor-SDK-/main/maazsohail11-pdf-editor-sdk-0.9.0.tgz'
$expectedSha256 = '780F7A397D272E5BCDA99E57C062632CE70AFE303D4A77EB651E13AE57358B67'
$contact = 'contact@pdffreeeditor.com'

Write-Host ''
Write-Host 'PDF Free Editor SDK — TRIAL self-host launcher' -ForegroundColor Cyan
Write-Host 'This downloads and runs the non-removable, watermarked trial build.' -ForegroundColor Yellow
Write-Host ''

$nodeCommand = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodeCommand) {
  Write-Error "Node.js $minimumNode or newer is required. Install it from https://nodejs.org/en/download and run this command again."
  exit 1
}

$nodeText = (& node --version).Trim().TrimStart('v')
try { $nodeVersion = [version]$nodeText } catch {
  Write-Error "Could not read the installed Node.js version ('$nodeText'). Install Node.js $minimumNode or newer from https://nodejs.org/en/download."
  exit 1
}
if ($nodeVersion -lt $minimumNode) {
  Write-Error "Node.js $nodeVersion is too old. Node.js $minimumNode or newer is required. Upgrade from https://nodejs.org/en/download."
  exit 1
}

do {
  $licenseAnswer = (Read-Host 'Do you have a license? (Y/N)').Trim().ToUpperInvariant()
} while ($licenseAnswer -notin @('Y', 'N'))

if ($licenseAnswer -eq 'Y') {
  Write-Host "Licensed setup isn't available yet. Please contact $contact to arrange access."
  exit 0
}

$root = Join-Path ([IO.Path]::GetTempPath()) ("pdf-free-editor-sdk-trial-" + [Guid]::NewGuid().ToString('N'))
$archive = Join-Path $root 'trial.zip'
$hostHtml = Join-Path $root 'index.html'
$hostServer = Join-Path $root 'host-server.mjs'
$log = Join-Path $root 'trial-server.log'
$errorLog = Join-Path $root 'trial-server-error.log'
$port = 5188
while (Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue) { $port += 1 }

try {
  New-Item -ItemType Directory -Path $root | Out-Null
  Write-Host 'Downloading the sanitized watermarked SDK artifact...' -ForegroundColor Cyan
  Invoke-WebRequest -Uri $artifactUrl -OutFile $archive -UseBasicParsing
  $actualSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $archive).Hash
  if ($actualSha256 -ne $expectedSha256) { throw "SDK artifact checksum mismatch. Expected $expectedSha256 but received $actualSha256." }

  $packageJson = @'
{
  "name": "pdf-free-editor-sdk-trial-host",
  "private": true,
  "type": "module",
  "dependencies": {
    "@maazsohail11/pdf-editor-sdk": "file:./maazsohail11-pdf-editor-sdk-0.9.0.tgz",
    "esbuild": "^0.25.0",
    "pdf-lib": "^1.17.1",
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  }
}
'@
  Set-Content -LiteralPath (Join-Path $root 'package.json') -Value $packageJson -Encoding UTF8
  Copy-Item -LiteralPath $archive -Destination (Join-Path $root 'maazsohail11-pdf-editor-sdk-0.9.0.tgz') -Force

  Write-Host 'Installing dependencies...' -ForegroundColor Cyan
  & npm.cmd --prefix $root install --no-audit --no-fund
  if ($LASTEXITCODE -ne 0) { throw "npm install failed with exit code $LASTEXITCODE." }

  $hostPage = @'
<!doctype html><meta charset="utf-8"><title>PDF Free Editor SDK Playground — Trial</title>
<style>body{margin:0;font:14px Arial;color:#172033;background:#f5f7fb}#layout{height:100vh;position:relative;overflow:hidden}#topbar{height:54px;box-sizing:border-box;padding:10px 14px;background:#fff;border-bottom:1px solid #dce2ec;display:flex;align-items:center;gap:10px;position:relative;z-index:3}#topbar strong{color:#1261c9;font-size:17px}#status{font-size:12px;color:#475569;margin-left:auto;line-height:1.4}#settingsToggle{margin:0;padding:7px 11px;border:1px solid #1261c9;border-radius:5px;background:#1261c9;color:#fff;cursor:pointer}#panel{position:absolute;z-index:4;top:54px;left:0;bottom:0;width:330px;padding:22px;background:#fff;border-right:1px solid #dce2ec;box-sizing:border-box;overflow:auto;transform:translateX(-100%);transition:transform .2s ease;box-shadow:5px 0 18px rgba(15,23,42,.12)}#panel.open{transform:translateX(0)}#panel h1{font-size:22px;margin:0 0 6px;color:#1261c9}#panel h2{font-size:15px;margin:24px 0 10px;border-bottom:1px solid #dce2ec;padding-bottom:7px}label{display:block;font-size:12px;font-weight:600;margin:10px 0 4px}input[type=text],input[type=number],select{width:100%;box-sizing:border-box;padding:8px;border:1px solid #cbd5e1;border-radius:5px}input[type=file]{width:100%;font-size:12px}button{padding:8px 11px;border:1px solid #1261c9;border-radius:5px;background:#1261c9;color:#fff;cursor:pointer;margin:10px 5px 0 0}button.secondary{background:#fff;color:#1261c9}.hint{font-size:11px;color:#64748b;line-height:1.4}#editor{height:calc(100vh - 54px);background:#eef2f7}#dropzone{position:absolute;z-index:2;inset:54px 0 0;display:flex;align-items:center;justify-content:center;background:#eef2f7}#dropzone.hidden{display:none}.dropcard{width:min(520px,calc(100% - 40px));padding:48px 30px;text-align:center;background:#fff;border:2px dashed #8fb4e8;border-radius:14px;box-shadow:0 12px 35px rgba(15,23,42,.08)}.dropcard.dragover{border-color:#1261c9;background:#eff6ff}.dropcard h1{margin:0 0 8px;color:#1261c9;font-size:24px}.dropcard p{color:#64748b;margin:8px 0 18px}.dropcard button{margin:0}.dropcard small{display:block;color:#94a3b8;margin-top:14px}</style>
<div id="layout"><div id="topbar"><strong>PDF Free Editor SDK</strong><button id="settingsToggle" type="button">Settings</button><span id="status">Choose a PDF to begin.</span></div><aside id="panel"><h1>SDK Settings</h1><div class="hint">Trial build — configure branding only when needed.</div><h2>Branding Config</h2><label for="header">Header asset URL or Base64</label><input id="header" type="text" placeholder="data:image/png;base64,..."><label for="footer">Footer asset URL or Base64</label><input id="footer" type="text" placeholder="data:image/png;base64,..."><label for="top">Top margin (px)</label><input id="top" type="number" value="100"><label for="bottom">Bottom margin (px)</label><input id="bottom" type="number" value="50"><label><input id="prebuilt" type="checkbox"> Use prebuilt margins</label><div class="hint">Stamp branding over the original page instead of elongating it.</div><h2>SDK Settings</h2><label for="theme">Editor theme</label><select id="theme"><option value="dark">Dark theme</option><option value="light">Light theme</option></select><button id="unmount" class="secondary" disabled>Unmount</button></aside><main id="editor"></main><section id="dropzone"><div class="dropcard" id="dropcard"><h1>Drop your PDF here</h1><p>Upload a PDF to start editing locally in your browser.</p><button id="choose" type="button">Choose PDF</button><small>Nothing is uploaded to a server.</small><input id="file" type="file" accept="application/pdf" hidden></div></section></div>
<script type="importmap">{"imports":{"react":"/vendor/react.js","react-dom":"/vendor/react-dom.js","react-dom/client":"/vendor/react-dom-client.js","react/jsx-runtime":"/vendor/jsx-runtime.js"}}</script>
<script type="module">
const {VanillaPDFEditor}=await import('/dist-sdk/pdf-editor-sdk.es.js'); let instance=null;
const status=document.getElementById('status'), unmountButton=document.getElementById('unmount');
const options=()=>({theme:document.getElementById('theme').value,brandingConfig:{headerAsset:document.getElementById('header').value,footerAsset:document.getElementById('footer').value,topMargin:Number(document.getElementById('top').value),bottomMargin:Number(document.getElementById('bottom').value),usePrebuiltMargins:document.getElementById('prebuilt').checked,onWarning:msg=>{status.textContent='Branding warning: '+msg}},onReady(){status.textContent='Ready — edit the PDF, then use the editor Export button.';unmountButton.disabled=false},onError(e){status.textContent='Error: '+e.error.message},onExport(blob){const url=URL.createObjectURL(blob);const a=document.createElement('a');a.href=url;a.download='trial-edited.pdf';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);status.textContent='Exported '+blob.size+' bytes — download started.'}});
const fileInput=document.getElementById('file'),dropzone=document.getElementById('dropzone'),dropcard=document.getElementById('dropcard');
document.getElementById('choose').onclick=()=>fileInput.click();
fileInput.onchange=event=>{const file=event.target.files?.[0];if(!file)return;instance?.unmount();dropzone.classList.add('hidden');instance=new VanillaPDFEditor(document.getElementById('editor'),{...options(),file})};
['dragenter','dragover'].forEach(type=>dropcard.addEventListener(type,event=>{event.preventDefault();dropcard.classList.add('dragover')}));
['dragleave','drop'].forEach(type=>dropcard.addEventListener(type,event=>{event.preventDefault();dropcard.classList.remove('dragover')}));
dropcard.addEventListener('drop',event=>{const file=event.dataTransfer.files?.[0];if(file?.type==='application/pdf'){const transfer=new DataTransfer();transfer.items.add(file);fileInput.files=transfer.files;fileInput.dispatchEvent(new Event('change'))}else status.textContent='Please drop a PDF file.'});
document.getElementById('settingsToggle').onclick=()=>document.getElementById('panel').classList.toggle('open');
['header','footer','top','bottom','prebuilt','theme'].forEach(id=>document.getElementById(id).addEventListener('change',()=>instance?.updateOptions(options())));
unmountButton.onclick=()=>{instance?.unmount();instance=null;dropzone.classList.remove('hidden');unmountButton.disabled=true;status.textContent='Choose a PDF to begin.'};
</script>
'@
  Set-Content -LiteralPath $hostHtml -Value $hostPage -Encoding UTF8

  $serverSource = @'
import { createServer } from 'node:http'; import { readFile } from 'node:fs/promises'; import { resolve, extname, sep } from 'node:path'; import { build } from 'esbuild'; import { createRequire } from 'node:module'; import { PDFDocument, StandardFonts } from 'pdf-lib';
const root=process.cwd(), port=Number(process.argv[2]||5188), require=createRequire(import.meta.url); const vendor=await build({entryPoints:{'react-core':'react','react-dom-client-core':'react-dom/client','react-dom-core':'react-dom'},absWorkingDir:root,bundle:true,splitting:true,format:'esm',platform:'browser',outdir:resolve(root,'.vendor'),write:false,define:{'process.env.NODE_ENV':'"production"'}}); const vendorFiles=new Map(vendor.outputFiles.map(f=>[f.path.split(/[\\/]/).pop(),f.contents])); const reactShim=Buffer.from("import React from '/vendor/react-core.js'; export default React; export const Suspense=React.Suspense; export const StrictMode=React.StrictMode; export const useEffect=React.useEffect; export const useState=React.useState; export const useRef=React.useRef; export const createElement=React.createElement; export const lazy=React.lazy;"); const reactDomClientShim=Buffer.from("import ReactDOM from '/vendor/react-dom-client-core.js'; export default ReactDOM; export const createRoot=ReactDOM.createRoot; export const hydrateRoot=ReactDOM.hydrateRoot;"); const reactDomShim=Buffer.from("import ReactDOM from '/vendor/react-dom-core.js'; export default ReactDOM; export const createPortal=ReactDOM.createPortal; export const flushSync=ReactDOM.flushSync;"); const jsxRuntimeShim=Buffer.from("import React from '/vendor/react.js'; export const Fragment=React.Fragment; export const jsx=(type,props,key)=>React.createElement(type,{...props,key}); export const jsxs=jsx; export const jsxDEV=jsx;"); const pdf=await PDFDocument.create(),font=await pdf.embedFont(StandardFonts.Helvetica); const page=pdf.addPage([612,792]); page.drawText('PDF Free Editor SDK trial document',{x:40,y:730,size:18,font}); page.drawText('Local test file — no customer data.',{x:40,y:690,size:12,font}); const fixture=await pdf.save(); const types={'.html':'text/html','.js':'text/javascript','.mjs':'text/javascript','.css':'text/css','.pdf':'application/pdf','.ttf':'font/ttf'};
createServer(async(req,res)=>{try{const path=decodeURIComponent(new URL(req.url,'http://localhost').pathname);res.setHeader('Cache-Control','no-store');if(path==='/fixture.pdf'){res.setHeader('Content-Type','application/pdf');return res.end(fixture)}if(path==='/vendor/react.js'){res.setHeader('Content-Type','text/javascript');return res.end(reactShim)}if(path==='/vendor/react-dom-client.js'){res.setHeader('Content-Type','text/javascript');return res.end(reactDomClientShim)}if(path==='/vendor/react-dom.js'){res.setHeader('Content-Type','text/javascript');return res.end(reactDomShim)}if(path==='/vendor/jsx-runtime.js'){res.setHeader('Content-Type','text/javascript');return res.end(jsxRuntimeShim)}if(path.startsWith('/vendor/')){const data=vendorFiles.get(path.slice(8));if(!data)throw Error('Missing vendor');res.setHeader('Content-Type','text/javascript');return res.end(data)}let target=path.startsWith('/dist-sdk/')?resolve(root,'node_modules/@maazsohail11/pdf-editor-sdk','dist-sdk',path.slice('/dist-sdk/'.length)):resolve(root,path==='/'?'index.html':'.'+path);if(!target.startsWith(root+sep))throw Error('Outside root');res.setHeader('Content-Type',types[extname(target)]||'application/octet-stream');res.end(await readFile(target))}catch{res.writeHead(404);res.end('Not found')}}).listen(port,'127.0.0.1',()=>console.log(`Trial SDK: http://127.0.0.1:${port}/`));
'@
  $serverSource = $serverSource.Replace('export const lazy=React.lazy;', 'export const lazy=React.lazy; export const forwardRef=React.forwardRef; export const Component=React.Component;')
  Set-Content -LiteralPath $hostServer -Value $serverSource -Encoding UTF8

  $server = Start-Process -FilePath 'node.exe' -ArgumentList @('host-server.mjs', [string]$port) -WorkingDirectory $root -RedirectStandardOutput $log -RedirectStandardError $errorLog -WindowStyle Hidden -PassThru
  $ready = $false
  for ($attempt = 0; $attempt -lt 30; $attempt++) {
    Start-Sleep -Milliseconds 500
    try {
      $probe = Invoke-WebRequest -Uri "http://127.0.0.1:$port/" -UseBasicParsing -TimeoutSec 2
      if ($probe.StatusCode -eq 200) { $ready = $true; break }
    } catch { }
  }
  if (-not $ready) {
    $serverOutput = if (Test-Path $log) { Get-Content -LiteralPath $log -Raw } else { '' }
    throw "The local trial server did not become ready. $serverOutput"
  }

  Write-Host ''
  Write-Host 'Trial SDK is ready.' -ForegroundColor Green
  Write-Host "Open: http://127.0.0.1:$port/" -ForegroundColor Green
  Write-Host 'The editor runs locally; exported PDFs include the trial watermarks.'
  Write-Host "Server process ID: $($server.Id)"
  Write-Host "To stop it later: Stop-Process -Id $($server.Id)"
} catch {
  Write-Error "Trial setup failed: $($_.Exception.Message)"
  Write-Host "Temporary files: $root"
  exit 1
}
