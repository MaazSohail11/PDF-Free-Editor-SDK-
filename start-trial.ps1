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

$root = Join-Path ([IO.Path]::GetTempPath()) 'pdf-free-editor-sdk-trial'
$archive = Join-Path $root 'trial.zip'
$hostHtml = Join-Path $root 'index.html'
$hostServer = Join-Path $root 'host-server.mjs'
$log = Join-Path $root 'trial-server.log'
$errorLog = Join-Path $root 'trial-server-error.log'

try {
  if (Test-Path $root) { Remove-Item -LiteralPath $root -Recurse -Force }
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
<!doctype html><meta charset="utf-8"><title>PDF Free Editor SDK — Trial</title>
<style>body{margin:0;font:14px Arial}#bar{padding:10px;background:#f2f2f2;display:flex;gap:10px;align-items:center}#editor{height:calc(100vh - 52px)}#status{color:#444}</style>
<div id="bar"><input id="file" type="file" accept="application/pdf"><button id="export" disabled>Export PDF</button><button id="unmount" disabled>Unmount</button><span id="status">Choose a PDF to begin.</span></div><div id="editor"></div>
<script type="importmap">{"imports":{"react":"/vendor/react.js","react-dom":"/vendor/react-dom.js","react-dom/client":"/vendor/react-dom-client.js","react/jsx-runtime":"/vendor/jsx-runtime.js"}}</script>
<script type="module">
const {VanillaPDFEditor}=await import('/dist-sdk/pdf-editor-sdk.es.js'); let instance=null; let exported=null;
const status=document.getElementById('status'), exportButton=document.getElementById('export'), unmountButton=document.getElementById('unmount');
document.getElementById('file').onchange=event=>{const file=event.target.files?.[0]; if(!file)return; instance?.unmount(); instance=new VanillaPDFEditor(document.getElementById('editor'),{file,onReady(){status.textContent='Ready — edit the PDF, then export.'; exportButton.disabled=false; unmountButton.disabled=false},onError(e){status.textContent='Error: '+e.error.message},onExport(blob){exported=blob; const url=URL.createObjectURL(blob); const a=document.createElement('a'); a.href=url; a.download='trial-edited.pdf'; a.click(); setTimeout(()=>URL.revokeObjectURL(url),1000); status.textContent='Exported '+blob.size+' bytes — download started.'}})};
exportButton.onclick=()=>instance?.export(); unmountButton.onclick=()=>{instance?.unmount();instance=null;exportButton.disabled=true;unmountButton.disabled=true;status.textContent='Unmounted.'};
</script>
'@
  Set-Content -LiteralPath $hostHtml -Value $hostPage -Encoding UTF8

  $serverSource = @'
import { createServer } from 'node:http'; import { readFile } from 'node:fs/promises'; import { resolve, extname, sep } from 'node:path'; import { build } from 'esbuild'; import { createRequire } from 'node:module'; import { PDFDocument, StandardFonts } from 'pdf-lib';
const root=process.cwd(), port=5188, require=createRequire(import.meta.url); const vendor=await build({entryPoints:{react:'react','react-dom-client':'react-dom/client','react-dom':'react-dom','jsx-runtime':'react/jsx-runtime'},absWorkingDir:root,bundle:true,splitting:true,format:'esm',platform:'browser',outdir:resolve(root,'.vendor'),write:false,define:{'process.env.NODE_ENV':'"production"'}}); const vendorFiles=new Map(vendor.outputFiles.map(f=>[f.path.split(/[\\/]/).pop(),f.contents])); const pdf=await PDFDocument.create(),font=await pdf.embedFont(StandardFonts.Helvetica); const page=pdf.addPage([612,792]); page.drawText('PDF Free Editor SDK trial document',{x:40,y:730,size:18,font}); page.drawText('Local test file — no customer data.',{x:40,y:690,size:12,font}); const fixture=await pdf.save(); const types={'.html':'text/html','.js':'text/javascript','.mjs':'text/javascript','.css':'text/css','.pdf':'application/pdf','.ttf':'font/ttf'};
createServer(async(req,res)=>{try{const path=decodeURIComponent(new URL(req.url,'http://localhost').pathname);res.setHeader('Cache-Control','no-store');if(path==='/fixture.pdf'){res.setHeader('Content-Type','application/pdf');return res.end(fixture)}if(path.startsWith('/vendor/')){const data=vendorFiles.get(path.slice(8));if(!data)throw Error('Missing vendor');res.setHeader('Content-Type','text/javascript');return res.end(data)}let target=path.startsWith('/dist-sdk/')?resolve(root,'node_modules/@maazsohail11/pdf-editor-sdk',path.slice(1)):resolve(root,path==='/'?'index.html':'.'+path);if(!target.startsWith(root+sep))throw Error('Outside root');res.setHeader('Content-Type',types[extname(target)]||'application/octet-stream');res.end(await readFile(target))}catch{res.writeHead(404);res.end('Not found')}}).listen(port,'127.0.0.1',()=>console.log(`Trial SDK: http://127.0.0.1:${port}/`));
'@
  Set-Content -LiteralPath $hostServer -Value $serverSource -Encoding UTF8

  $server = Start-Process -FilePath 'node.exe' -ArgumentList 'host-server.mjs' -WorkingDirectory $root -RedirectStandardOutput $log -RedirectStandardError $errorLog -WindowStyle Hidden -PassThru
  $ready = $false
  for ($attempt = 0; $attempt -lt 30; $attempt++) {
    Start-Sleep -Milliseconds 500
    try {
      $probe = Invoke-WebRequest -Uri 'http://127.0.0.1:5188/' -UseBasicParsing -TimeoutSec 2
      if ($probe.StatusCode -eq 200) { $ready = $true; break }
    } catch { }
  }
  if (-not $ready) {
    $serverOutput = if (Test-Path $log) { Get-Content -LiteralPath $log -Raw } else { '' }
    throw "The local trial server did not become ready. $serverOutput"
  }

  Write-Host ''
  Write-Host 'Trial SDK is ready.' -ForegroundColor Green
  Write-Host 'Open: http://127.0.0.1:5188/' -ForegroundColor Green
  Write-Host 'The editor runs locally; exported PDFs include the trial watermarks.'
  Write-Host "Server process ID: $($server.Id)"
  Write-Host "To stop it later: Stop-Process -Id $($server.Id)"
} catch {
  Write-Error "Trial setup failed: $($_.Exception.Message)"
  Write-Host "Temporary files: $root"
  exit 1
}
