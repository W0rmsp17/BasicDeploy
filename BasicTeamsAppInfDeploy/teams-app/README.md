# Teams Frontend

React/Vite frontend for the Microsoft 365 onboarding Teams tab.

## Hosting

The intended hosting target is Azure Static Web Apps in the target tenant subscription. The Teams app manifest points the tab at the Static Web Apps URL.

For local development:

```powershell
npm install
npm run dev
```

For production build:

```powershell
npm run build
```

## Configuration

Copy `.env.example` to `.env.local` for local testing:

```powershell
Copy-Item .env.example .env.local
```

Set:

- `VITE_API_BASE_URL`: Function App base URL, for example `https://func-name.azurewebsites.net`.
- `VITE_FUNCTION_KEY`: temporary local/test Function key.

The frontend also supports runtime configuration through the settings button. Values are stored in browser local storage.

Do not use a bundled Function key as the production security model. The long-term production path should use Teams SSO or a small authenticated server-side proxy so secrets are not exposed in browser code.

## Teams Package

Use `manifest/manifest.template.json` as the Teams app manifest template. Replace the placeholders and add Teams icon PNGs before packaging.
