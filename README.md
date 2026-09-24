# HyDr0 Tools

A standalone APK installer for Fire TV / Android TV / Android phones. Paste a
direct download link for an APK, it fetches the file and hands it to
Android's own package installer. That's the whole app.

It ships empty on purpose: no built-in catalog, no codes, no pre-loaded app
list, nothing to browse. Same "you bring your own" idea as
[HyDr02](https://github.com/Blkmaze/HyDr02) -- this just does it for
installing APKs instead of playing IPTV.

## What it's for

Moving your own APKs (your own builds, or anything you already have a
legitimate direct download link for) from wherever they're hosted onto a
Fire TV Cube/Stick without a browser, or onto a phone, without needing a
file manager or ADB. It also self-updates the same way HyDr02 does -- the
update icon in the top bar checks this repo's own releases.

## Building it

This repo builds the same way HyDr02 does: `Actions` tab →
`Build HyDr0 Tools APK` → `Run workflow`. Fill in the app name / package id
if you want to change them (defaults: `HyDr0 Tools` / `com.hydr0.tools`),
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
`https://github.com/Blkmaze/HyDr0-Tools/releases/download/HyDr0Tools-latest/HyDr0Tools-tv-arm64.apk`,
swap `-arm` for the other CPU type or drop the suffix for the universal
APK), and grab it with Downloader on the device, or a Bitly link if typing
the full URL on a remote is annoying.

## Permissions

The app asks Android for permission to install unknown apps
(`REQUEST_INSTALL_PACKAGES`) the first time you use it -- that's the
system's own prompt, required for any app that installs another APK. It
doesn't ask for anything else: no storage browsing, no contacts, nothing
related to the apps it installs beyond handing them to the installer.
