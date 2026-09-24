#!/usr/bin/env python3
"""
Stamps this app's name, package id, and icon into a freshly `flutter
create`d Android project. Trimmed down from HyDr02's tools/brand.py --
this app has no server/portal branding to inject, just an applicationId,
a label, and a launcher icon.

  brand.py --project build/proj --app-name "HyDr0 Tools" \
           --package com.hydr0.tools [--icon path-or-url]

What it does:
  1. sets applicationId + minSdk in android/app/build.gradle(.kts)
  2. patches AndroidManifest.xml (INTERNET, REQUEST_INSTALL_PACKAGES,
     leanback launcher + banner so it shows in the Fire TV apps row,
     cleartext http for plain-http download links)
  3. generates launcher icons + TV banner (from --icon, or auto-made
     initials if none given)
"""
import argparse, io, os, re, sys, urllib.request
from PIL import Image, ImageDraw, ImageFont

ap = argparse.ArgumentParser()
ap.add_argument("--project", required=True)
ap.add_argument("--app-name", required=True)
ap.add_argument("--package", required=True)
ap.add_argument("--color", default="#00B4FF")
ap.add_argument("--icon", default="")
a = ap.parse_args()

P = a.project
if not re.fullmatch(r"[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+", a.package):
    sys.exit(f"Bad package id: {a.package} (use e.g. com.yourname.tools)")
color = a.color if a.color.startswith("#") else "#" + a.color
if not re.fullmatch(r"#[0-9a-fA-F]{6}", color):
    sys.exit(f"Bad color: {a.color} (use #RRGGBB)")

# 1. gradle --------------------------------------------------------------
def patch(path, subs):
    s = open(path).read()
    for pat, rep in subs:
        s, n = re.subn(pat, rep, s, count=1)
        if n == 0:
            print(f"[brand] WARN pattern not found in {os.path.basename(path)}: {pat}")
    open(path, "w").write(s)

gradle = f"{P}/android/app/build.gradle.kts"
if os.path.exists(gradle):
    patch(gradle, [
        (r'applicationId\s*=\s*"[^"]+"', f'applicationId = "{a.package}"'),
        (r'minSdk\s*=\s*[^\n]+', 'minSdk = 21'),
    ])
else:
    gradle = f"{P}/android/app/build.gradle"
    patch(gradle, [
        (r'applicationId\s+"[^"]+"', f'applicationId "{a.package}"'),
        (r'minSdkVersion\s+[^\n]+', 'minSdkVersion 21'),
    ])
print(f"[brand] applicationId -> {a.package}, minSdk 21")

# 2. manifest --------------------------------------------------------------
man = f"{P}/android/app/src/main/AndroidManifest.xml"
s = open(man).read()
perms = """
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>
    <uses-feature android:name="android.software.leanback" android:required="false"/>
    <uses-feature android:name="android.hardware.touchscreen" android:required="false"/>
"""
s = s.replace("<application", perms + "    <application", 1)
if "installLocation" not in s:
    s = s.replace("<manifest ", '<manifest android:installLocation="internalOnly" ', 1)
s = re.sub(r'android:label="[^"]*"', f'android:label="{a.app_name}"', s, count=1)
s = s.replace("<application", '<application\n        android:banner="@drawable/ic_banner"\n        android:usesCleartextTraffic="true"', 1)
s = re.sub(r'<activity(\s+android:name="\.MainActivity")',
           r'<activity\n            android:banner="@drawable/ic_banner"\1', s, count=1)
if 'android:banner' not in s.split('<activity', 1)[1].split('>', 1)[0]:
    s = s.replace('<activity', '<activity\n            android:banner="@drawable/ic_banner"', 1)
s = s.replace('<category android:name="android.intent.category.LAUNCHER"/>',
              '<category android:name="android.intent.category.LAUNCHER"/>\n'
              '                <category android:name="android.intent.category.LEANBACK_LAUNCHER"/>', 1)
open(man, "w").write(s)
print("[brand] manifest patched (install permission + Fire TV launcher)")

# 3. icons -------------------------------------------------------------------
def load_icon():
    if a.icon:
        data = urllib.request.urlopen(a.icon).read() if a.icon.startswith("http") else open(a.icon, "rb").read()
        return Image.open(io.BytesIO(data)).convert("RGBA")
    img = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((0, 0, 511, 511), radius=96, fill=color)
    initials = "".join(w[0] for w in a.app_name.split()[:2]).upper() or "HT"
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 240)
    except Exception:
        font = ImageFont.load_default()
    bb = d.textbbox((0, 0), initials, font=font)
    d.text(((512 - bb[2] + bb[0]) / 2 - bb[0], (512 - bb[3] + bb[1]) / 2 - bb[1]), initials, font=font, fill="white")
    return img

icon = load_icon()
res = f"{P}/android/app/src/main/res"
for d, sz in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
    os.makedirs(f"{res}/mipmap-{d}", exist_ok=True)
    icon.resize((sz, sz), Image.LANCZOS).save(f"{res}/mipmap-{d}/ic_launcher.png")

os.makedirs(f"{P}/assets", exist_ok=True)
icon.resize((256, 256), Image.LANCZOS).save(f"{P}/assets/logo.png")
print("[brand] logo.png bundled" + (" (from --icon)" if a.icon else " (auto-generated initials)"))

ban = Image.new("RGBA", (320, 180), color)
ban.alpha_composite(icon.resize((140, 140), Image.LANCZOS), (20, 20))
d = ImageDraw.Draw(ban)
try:
    f = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 26)
except Exception:
    f = ImageFont.load_default()
d.text((175, 76), a.app_name[:14], font=f, fill="white")
for dname, scale in {"mdpi": 0.5, "hdpi": 0.75, "xhdpi": 1.0, "xxhdpi": 1.5, "xxxhdpi": 2.0}.items():
    os.makedirs(f"{res}/drawable-{dname}", exist_ok=True)
    w, h = int(320 * scale), int(180 * scale)
    ban.resize((w, h), Image.LANCZOS).convert("RGB").save(f"{res}/drawable-{dname}/ic_banner.png")
os.makedirs(f"{res}/mipmap-xhdpi", exist_ok=True)
ban.convert("RGB").save(f"{res}/mipmap-xhdpi/ic_banner.png")
print("[brand] icons + TV banner generated")
