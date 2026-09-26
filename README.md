# PDF Free Editor SDK

Browser-based PDF editing SDK with a local, source-free trial Playground.

The public repository contains the packaged SDK artifact and a sanitized host
wrapper. It does **not** contain the private editor source, website source,
development configuration, tests, or source maps.

## Choose your workflow

| Goal | Recommended path |
| --- | --- |
| Fastest trial on Windows | PowerShell launcher |
| Run the included Playground manually | `npm install` + `npm start` |
| Integrate the SDK into your own application | Install the `.tgz` package |

## Requirements

- Node.js 20.19 or newer
- npm (included with Node.js)
- A modern browser such as Chrome, Edge, Firefox, or Safari

The SDK runs locally in the browser. PDFs are processed by the Playground and
SDK client-side; the included host does not upload document content to a
server.

## Option 1 — Quickest Windows trial

Open PowerShell and run:

```powershell
irm "https://raw.githubusercontent.com/MaazSohail11/PDF-Free-Editor-SDK-/main/start-trial.ps1" | iex
```

Answer `N` when asked about a license. The launcher will:

1. Download the published SDK tarball.
2. Verify its SHA-256 checksum.
3. Install the local host dependencies.
4. Start a localhost server on an available port.
5. Print the Playground URL.

Open the printed URL in your browser. To stop the server, close the terminal
or run the `Stop-Process` command printed by the launcher.

If PowerShell has cached an older script, add a cache-busting query:

```powershell
irm "https://raw.githubusercontent.com/MaazSohail11/PDF-Free-Editor-SDK-/main/start-trial.ps1?cachebust=latest" | iex
```

## Option 2 — Use the provided files without PowerShell

Download the repository ZIP from GitHub, extract it, and open a terminal in the
extracted folder. The folder must contain `package.json` and the SDK tarball.

```cmd
npm install
npm start
```

The server prints a local URL such as:

```text
http://127.0.0.1:5188/
```

Open that URL in a browser. The included `index.html` and `host-server.mjs`
already load the packaged SDK automatically; no manual import is needed for
this Playground.

### Windows CMD launcher

```cmd
start-trial.cmd
```

### macOS/Linux launcher

```sh
chmod +x start-trial.sh
./start-trial.sh
```

These launchers are convenience wrappers around the same Node host. They do
not expose private source code.

## Option 3 — Integrate into your own application

The tarball is a normal installable npm package. It can be used from a Vite,
React, vanilla JavaScript, or other browser application.

### Create a test application

```cmd
npm create vite@latest my-pdf-app -- --template vanilla
cd my-pdf-app
npm install
```

### Install the SDK tarball

From the generated application directory, install the tarball from the cloned
SDK repository:

```cmd
npm install "..\sdk-latest\PDF-Free-Editor-SDK--main\maazsohail11-pdf-editor-sdk-0.9.0.tgz" react react-dom
```

Adjust the path if your folders are located elsewhere.

### Add a mount point

In `index.html`:

```html
<input id="pdfFile" type="file" accept="application/pdf" />
<div id="editor" style="height: 100vh;"></div>
```

### Mount the editor

In `src/main.js`:

```js
import { VanillaPDFEditor } from "@maazsohail11/pdf-editor-sdk";
import "./style.css";

const fileInput = document.querySelector("#pdfFile");
let editor = null;

fileInput.addEventListener("change", () => {
  const file = fileInput.files?.[0];
  if (!file) return;

  editor?.unmount();

  editor = new VanillaPDFEditor(document.querySelector("#editor"), {
    file,
    onReady() {
      console.log("PDF editor ready");
    },
    onError(error) {
      console.error("SDK error", error);
    },
    onExport(blob) {
      const url = URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.download = "edited.pdf";
      link.click();
      URL.revokeObjectURL(url);
    }
  });
});
```

Start the application:

```cmd
npm run dev
```

Open the URL printed by Vite. The application chooses its own mount element,
file workflow, branding configuration, and export handling; the SDK package
does not modify unrelated application files automatically.

## Playground test checklist

After loading a PDF, verify:

- Text insertion and editing
- Image insertion, movement, scaling, and rotation
- Drawing, highlighting, and stamps
- Manual stamp placement, movement, and deletion
- Page navigation, page collapse, and page operations
- Header/footer branding configuration
- Theme and Settings panel behavior
- Export and download
- Reopening the exported PDF
- Trial watermark on exported pages

The Settings button changes to `×` while open. Opening Settings collapses the
page sidebar; closing Settings reopens it.

## Package contents and privacy

The public repository includes:

- Compiled browser SDK bundle
- Type declarations
- Required fonts and PDF.js worker
- SDK tarball and checksum
- Sanitized Playground host files
- Installation and technical documentation

It intentionally excludes:

- Private editor source files
- Website source files
- Vite and development configuration
- Automated tests
- Source maps

The trial watermark is implemented in the browser bundle. Browser-delivered
JavaScript can always be inspected or modified by a determined user; the
watermark is therefore a trial deterrent, not cryptographic tamper prevention.
License enforcement and cryptographic signing are separate product features.

## Artifact verification

The expected checksum is recorded in `SHA256SUMS.txt`.

PowerShell:

```powershell
Get-FileHash .\maazsohail11-pdf-editor-sdk-0.9.0.tgz -Algorithm SHA256
```

Compare the result with the recorded SHA-256 value before installing a manually
downloaded artifact.

## Support and pricing

- Email: [contact@pdffreeeditor.com](mailto:contact@pdffreeeditor.com)
- Pricing: [https://pdffreeeditor.com/pricing](https://pdffreeeditor.com/pricing)
- Repository: [PDF Free Editor SDK](https://github.com/MaazSohail11/PDF-Free-Editor-SDK-)

The published tarball is the watermarked trial artifact. Contact us for
licensed package access and commercial terms.
