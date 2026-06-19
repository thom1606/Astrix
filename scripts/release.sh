#!/usr/bin/env bash
#
# release.sh — build, sign, notarize, package, and publish a new Astrix release.
#
# Produces a Developer ID-signed + notarized build, packages it as a Sparkle
# update zip and a user-facing DMG, signs the zip with the Sparkle EdDSA key,
# appends an entry to the appcast (docs/appcast.xml, served via GitHub Pages),
# creates a GitHub Release with the assets, and commits the updated appcast.
#
# Runs locally or in CI (see .github/workflows/release.yml). The same logic is
# used in both; CI just provides the secrets as environment variables.
#
# Required environment (see RELEASING.md for setup):
#   ASC_API_KEY_ID        App Store Connect API key id (notarytool)
#   ASC_API_ISSUER_ID     App Store Connect API issuer id
#   ASC_API_KEY_PATH      Path to the App Store Connect API .p8 file
#   SPARKLE_PRIVATE_KEY   (optional) base64 EdDSA private key. If unset, the key
#                         is read from the login keychain (local machines).
# Optional:
#   REPO                  GitHub repo slug (default: thom1606/Astrix; CI uses
#                         $GITHUB_REPOSITORY automatically)
#   SKIP_PUBLISH=1        Build/package only — no GitHub release, no git push
#   SKIP_NOTARIZE=1       Skip notarization (for local smoke tests only)
#
set -euo pipefail

# --- Configuration ---------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

PROJECT="Astrix.xcodeproj"
SCHEME="Astrix"
CONFIGURATION="Release"
APP_NAME="Astrix"
REPO="${REPO:-${GITHUB_REPOSITORY:-thom1606/Astrix}}"

BUILD_DIR="$ROOT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
STAGING_DIR="$BUILD_DIR/staging"      # holds the .app alone, for create-dmg
APPCAST="$ROOT_DIR/docs/appcast.xml"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31mError:\033[0m %s\n' "$*" >&2; exit 1; }

# Locate Sparkle's `sign_update` tool: prefer the one from the resolved SPM
# artifact, otherwise download the Sparkle distribution. Echoes the path only.
find_sign_update() {
  local found
  found="$(find "$HOME/Library/Developer/Xcode/DerivedData" \
            -path '*/Sparkle/bin/sign_update' -type f 2>/dev/null | head -1 || true)"
  if [ -n "$found" ]; then echo "$found"; return; fi

  local tools_dir="$BUILD_DIR/sparkle-tools" ver="2.9.3"
  if [ ! -x "$tools_dir/bin/sign_update" ]; then
    { mkdir -p "$tools_dir"
      curl -fsSL "https://github.com/sparkle-project/Sparkle/releases/download/$ver/Sparkle-$ver.tar.xz" \
        | tar xJ -C "$tools_dir"; } >&2
  fi
  echo "$tools_dir/bin/sign_update"
}

# --- Preflight -------------------------------------------------------------
command -v xcodebuild >/dev/null || fail "xcodebuild not found"
command -v create-dmg >/dev/null || fail "create-dmg not found (brew install create-dmg)"
command -v gh >/dev/null         || fail "gh (GitHub CLI) not found"
command -v python3 >/dev/null    || fail "python3 not found"

# --- Version ---------------------------------------------------------------
# Read the authoritative version values from the build settings.
read_setting() {
  xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration "$CONFIGURATION" \
    -showBuildSettings 2>/dev/null | awk -v k="$1" '$1==k {print $3; exit}'
}
MARKETING_VERSION="$(read_setting MARKETING_VERSION)"
BUILD_NUMBER="$(read_setting CURRENT_PROJECT_VERSION)"
[ -n "$MARKETING_VERSION" ] || fail "Could not read MARKETING_VERSION"
[ -n "$BUILD_NUMBER" ] || fail "Could not read CURRENT_PROJECT_VERSION"

TAG="v$MARKETING_VERSION"
ZIP_NAME="$APP_NAME-$MARKETING_VERSION.zip"
DMG_NAME="$APP_NAME-$MARKETING_VERSION.dmg"
ZIP_PATH="$BUILD_DIR/$ZIP_NAME"
DMG_PATH="$BUILD_DIR/$DMG_NAME"
DOWNLOAD_URL="https://github.com/$REPO/releases/download/$TAG/$ZIP_NAME"

log "Releasing $APP_NAME $MARKETING_VERSION (build $BUILD_NUMBER) as $TAG"

# --- Guard: don't overwrite an existing release ----------------------------
if [ "${SKIP_PUBLISH:-0}" != "1" ]; then
  if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
    fail "Release $TAG already exists — bump MARKETING_VERSION before releasing."
  fi
fi

# --- Build & export --------------------------------------------------------
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

log "Archiving…"
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -archivePath "$ARCHIVE_PATH" \
  -destination 'generic/platform=macOS' \
  CODE_SIGN_STYLE=Automatic

log "Exporting (Developer ID)…"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$SCRIPT_DIR/ExportOptions.plist"

APP_PATH="$EXPORT_DIR/$APP_NAME.app"
[ -d "$APP_PATH" ] || fail "Exported app not found at $APP_PATH"

# --- Notarize & staple -----------------------------------------------------
if [ "${SKIP_NOTARIZE:-0}" != "1" ]; then
  : "${ASC_API_KEY_ID:?ASC_API_KEY_ID is required for notarization}"
  : "${ASC_API_ISSUER_ID:?ASC_API_ISSUER_ID is required for notarization}"
  : "${ASC_API_KEY_PATH:?ASC_API_KEY_PATH is required for notarization}"

  log "Submitting for notarization…"
  NOTARIZE_ZIP="$BUILD_DIR/notarize.zip"
  ditto -c -k --keepParent "$APP_PATH" "$NOTARIZE_ZIP"
  xcrun notarytool submit "$NOTARIZE_ZIP" \
    --key "$ASC_API_KEY_PATH" \
    --key-id "$ASC_API_KEY_ID" \
    --issuer "$ASC_API_ISSUER_ID" \
    --wait

  log "Stapling notarization ticket…"
  xcrun stapler staple "$APP_PATH"
else
  log "SKIP_NOTARIZE=1 — skipping notarization (not distributable!)"
fi

# --- Package ---------------------------------------------------------------
log "Creating Sparkle zip…"
# Sparkle expects a zip of the .app; sequester resource forks for a clean archive.
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

log "Creating DMG…"
rm -rf "$STAGING_DIR" && mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"
create-dmg \
  --volname "$APP_NAME" \
  --window-size 600 400 \
  --icon "$APP_NAME.app" 150 190 \
  --app-drop-link 450 190 \
  --no-internet-enable \
  "$DMG_PATH" "$STAGING_DIR" || true   # create-dmg returns non-zero on warnings
[ -f "$DMG_PATH" ] || fail "DMG was not created"

# --- Sparkle signature -----------------------------------------------------
log "Signing update with Sparkle…"
SIGN_UPDATE="$(find_sign_update)"
if [ -n "${SPARKLE_PRIVATE_KEY:-}" ]; then
  SIGN_OUTPUT="$("$SIGN_UPDATE" -s "$SPARKLE_PRIVATE_KEY" "$ZIP_PATH")"
else
  # No key provided → read from the login keychain (local machines).
  SIGN_OUTPUT="$("$SIGN_UPDATE" "$ZIP_PATH")"
fi
# sign_update prints: sparkle:edSignature="…" length="…"
ED_SIGNATURE="$(printf '%s' "$SIGN_OUTPUT" | sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p')"
LENGTH="$(printf '%s' "$SIGN_OUTPUT" | sed -n 's/.*length="\([^"]*\)".*/\1/p')"
[ -n "$ED_SIGNATURE" ] || fail "Could not read EdDSA signature from sign_update output: $SIGN_OUTPUT"
[ -n "$LENGTH" ] || LENGTH="$(stat -f%z "$ZIP_PATH")"

# --- Appcast ---------------------------------------------------------------
log "Updating appcast…"
PUB_DATE="$(date -R 2>/dev/null || date '+%a, %d %b %Y %H:%M:%S %z')"
MIN_OS="$(read_setting MACOSX_DEPLOYMENT_TARGET)"
ITEM="        <item>
            <title>$MARKETING_VERSION</title>
            <pubDate>$PUB_DATE</pubDate>
            <sparkle:version>$BUILD_NUMBER</sparkle:version>
            <sparkle:shortVersionString>$MARKETING_VERSION</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>${MIN_OS:-14.0}</sparkle:minimumSystemVersion>
            <enclosure url=\"$DOWNLOAD_URL\" length=\"$LENGTH\" type=\"application/octet-stream\" sparkle:edSignature=\"$ED_SIGNATURE\"/>
        </item>"

# Insert the new (newest) item right after the marker, keeping newest-first order.
python3 - "$APPCAST" "$ITEM" <<'PY'
import sys
path, item = sys.argv[1], sys.argv[2]
with open(path, "r", encoding="utf-8") as f:
    xml = f.read()
marker = "<!-- BEGIN ITEMS -->"
if marker not in xml:
    raise SystemExit(f"Marker '{marker}' not found in {path}")
xml = xml.replace(marker, marker + "\n" + item, 1)
with open(path, "w", encoding="utf-8") as f:
    f.write(xml)
print("appcast updated")
PY

if [ "${SKIP_PUBLISH:-0}" = "1" ]; then
  log "SKIP_PUBLISH=1 — built $ZIP_PATH and $DMG_PATH; appcast updated locally. Done."
  exit 0
fi

# --- Publish ---------------------------------------------------------------
log "Creating GitHub release $TAG…"
gh release create "$TAG" \
  --repo "$REPO" \
  --title "$APP_NAME $MARKETING_VERSION" \
  --notes "Astrix $MARKETING_VERSION (build $BUILD_NUMBER)" \
  "$ZIP_PATH" "$DMG_PATH"

log "Committing appcast…"
git add "$APPCAST"
git commit -m "release: $APP_NAME $MARKETING_VERSION"
git push

log "Done. $APP_NAME $MARKETING_VERSION published as $TAG."
