# Maze-Tools

*(repo stays `HyDr0-Tools`, package id stays `com.hydr0.tools` -- this is a display-name/branding rename only, so self-update and existing installs keep working with no reinstall needed)*

A storefront-style APK installer for Fire TV / Android TV / Android phones,
backed by your own self-hosted Maze-Tools Store backend (the `hydr0-store`
project, running on your own NAS) instead of anyone else's servers.

Point the app at your NAS/Funnel URL once (Settings → Store URL) and the
home screen becomes a Featured row + Categories, pulled live from
`/api/apps` and `/api/categories`. Nothing is seeded or pre-loaded --
until you configure a store and add apps through the admin dashboard, the
home screen just says so and asks for the URL. Same "you bring your own"
idea as [HyDr02](https://github.com/Blkmaze/HyDr02) -- this just does it
for a whole catalog instead of one link.

Entering a 6-digit code or pasting a direct APK URL still works exactly
like before -- it's just moved off the home screen into a secondary
"Enter code / paste URL" screen (the dialpad icon in the top bar), for
apps not in your catalog or for anyone who prefers typing a code.

## What it's for

Running your own small, private app store for the devices in your house:
your own builds, GitHub releases, or anything else you have a legitimate
direct download link for, organized into categories with a Featured shelf,
instead of a flat list of raw URLs. Each catalog entry can show a
"NAS-hosted", "GitHub-verified", or "Updated this week" badge (computed
from the URL and timestamps the backend already tracks) so it's obvious at
a glance where something came from. It also self-updates the same way
HyDr02 does -- the update check now lives in Settings.

## Building it

This repo builds the same way HyDr02 does: `Actions` tab →
`Build Maze-Tools APK` → `Run workflow`. Fill in the app name / package id
if you want to change them (defaults: `Maze-Tools` / `com.hydr0.tools`),
leave `icon_url` blank for an auto-generated icon, or point it at a 512x512
PNG.

### Signing (do this before your first real build)

Same three repository secrets as HyDr02 -- **Settings → Secrets and
variables → Actions**:

- `KEYSTORE_B64` -- base64 of a `.jks` keystore file
- `KEYSTORE_PASSWORD`
- `KEY_ALIAS`

You can reuse the exact same keystore file you already use for HyDr02 --
a keystore isn't tied to one app, it just needs to sign every build of
*this* app consistently from here on. Reusing it is simpler than managing
a second one. If you'd rather keep them separate, generate a fresh one the
same way the HyDr02 README describes.

**Without these secrets set, every build is signed with a fresh throwaway
key**, and Android will refuse to install a new build over an old one
(`package conflicts with an existing package`) until you uninstall first --
exactly the issue that came up early on with HyDr02. Set the secrets once,
before your first real build, and every build after that updates cleanly
in place.

## Getting it onto a Fire TV / Firestick

Same pattern as HyDr02: build it, grab the `HyDr0Tools-latest` release
link (stays the same URL across every build --
`https://github.com/Blkmaze/HyDr0-Tools/releases/download/HyDr0Tools-latest/MazeTools-tv-arm64.apk`,
swap `-arm` for the other CPU type or drop the suffix for the universal
APK), and grab it with Downloader on the device, or a Bitly link if typing
the full URL on a remote is annoying.

(The release tag itself is still called `HyDr0Tools-latest` -- that's just
an internal label in the URL path, never shown anywhere in the app or on
the TV. Only the asset filenames changed, from the `app_name` rename.)

## First run

1. Install the APK (see below).
2. Open it, tap the gear icon, paste your Maze-Tools Store's URL (the same
   Funnel/Tailscale address the admin dashboard uses) into **Store URL**,
   and tap **Save** -- it runs a connection test automatically.
3. Back on the home screen: Featured apps and Categories populate from
   whatever's in your store's catalog. Add more from the admin dashboard at
   any time and pull-to-refresh (or just reopen the app) to see them.

## Permissions

The app asks Android for permission to install unknown apps
(`REQUEST_INSTALL_PACKAGES`) the first time you use it -- that's the
system's own prompt, required for any app that installs another APK. It
doesn't ask for anything else: no storage browsing, no contacts, nothing
related to the apps it installs beyond handing them to the installer.
