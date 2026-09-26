# PDF Free Editor SDK — Watermarked Trial Artifact

This repository publishes only the installable SDK package. The package
contains the production browser bundle, type declarations, required fonts,
PDF.js worker, and product documentation. It does not contain the private
editor source, website source, development configuration, tests, or source
maps.

Install the artifact from a downloaded copy with:

```powershell
npm install .\maazsohail11-pdf-editor-sdk-0.9.0.tgz react react-dom
```

To run the included source-free local Playground without PowerShell:

```cmd
npm install
start-trial.cmd
```

Or on macOS/Linux:

```sh
npm install
./start-trial.sh
```

The host files serve only the packaged SDK artifact. They do not include the
private editor source, website source, development configuration, tests, or
source maps.

The trial build is watermarked on every exported page. The source project and
clean/licensed branch are not published here.

To use the SDK in another application, install the same tarball from that
application's directory:

```cmd
npm install C:\path\to\maazsohail11-pdf-editor-sdk-0.9.0.tgz react react-dom
```

The application can then import `VanillaPDFEditor` from
`@maazsohail11/pdf-editor-sdk`. The included Playground is already wired to
load the package automatically.
