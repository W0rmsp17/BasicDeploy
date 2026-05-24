# Teams Manifest

This folder contains a template manifest for the Teams personal tab.

Replace these placeholders before packaging:

- `{{TEAMS_APP_ID}}`: a generated GUID for the Teams app package.
- `{{FRONTEND_BASE_URL}}`: the HTTPS URL of the deployed frontend, for example an Azure Static Web Apps URL.
- `{{FRONTEND_DOMAIN}}`: the hostname only, without `https://`.

The manifest references `outline.png` and `color.png`. The environment script `new-teams-package.ps1` creates placeholder icons and packages the generated manifest for upload through Teams Developer Portal or Teams admin center.

For the MVP, the tab is a personal app. A configurable team/channel tab can be added later once the frontend is backed by Teams SSO or another server-side auth pattern.
