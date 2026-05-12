# Signing and Releasing Chops

## Current Status

- ✅ **CI Builds**: Unsigned debug builds (for testing only)
- ✅ **Release Script**: Complete `./scripts/release.sh` for signed production releases
- ⚠️ **Requires Setup**: Apple Developer credentials

## Quick Answer

**CI builds are unsigned** - they're for testing/development only. Users cannot run them without disabling Gatekeeper.

**For distribution**, you need to:
1. Join Apple Developer Program ($99/year)
2. Create signing certificates
3. Configure credentials locally
4. Run `./scripts/release.sh <version>` to create signed release

---

## Apple Developer Program Setup

### 1. Join Apple Developer Program

Visit: https://developer.apple.com/programs/

- Cost: $99/year
- Required for: Code signing, notarization, Mac App Store distribution
- Process takes: 1-2 business days

### 2. Create Developer ID Application Certificate

Once enrolled:

1. **Open Xcode**
   - Xcode → Settings → Accounts
   - Click "+" → Add Apple ID
   - Sign in with your Apple Developer account

2. **Create Certificate**
   - Select your account → Click "Manage Certificates"
   - Click "+" → Select "Developer ID Application"
   - Certificate will be created and installed in Keychain

3. **Verify Certificate**
   ```bash
   security find-identity -v -p codesigning
   ```
   
   Look for: `Developer ID Application: Your Name (TEAM_ID)`

### 3. Get Your Team ID

**Method 1: Xcode**
- Xcode → Settings → Accounts
- Select your account → Team ID is shown

**Method 2: Developer Portal**
- https://developer.apple.com/account/
- Membership → Team ID

**Method 3: Certificate**
```bash
security find-identity -v -p codesigning | grep "Developer ID"
# Output: "Developer ID Application: Your Name (ABC123XYZ)"
#                                              ^^^^^^^^^^^
#                                              This is your Team ID
```

### 4. Create App-Specific Password

For notarization:

1. Go to: https://appleid.apple.com/account/manage
2. Sign in with your Apple ID
3. Security → App-Specific Passwords → Generate
4. Name it: "Chops Notarization"
5. **Save the password** - you'll need it once

---

## Local Configuration

### 1. Create `.env` file

In the project root:

```bash
cp .env.example .env
```

Edit `.env`:

```bash
APPLE_TEAM_ID=ABC123XYZ          # Your 10-character Team ID
APPLE_ID=you@example.com         # Your Apple ID email
SIGNING_IDENTITY_NAME=Your Name  # Name on your Developer ID cert
```

**Important:** `.env` is in `.gitignore` - never commit it!

### 2. Store Notarization Credentials

One-time setup:

```bash
xcrun notarytool store-credentials "AC_PASSWORD" \
  --apple-id "you@example.com" \
  --team-id "ABC123XYZ" \
  --password "abcd-efgh-ijkl-mnop"  # App-specific password from step 4
```

This stores credentials in your keychain as "AC_PASSWORD" profile.

### 3. Verify Setup

```bash
# Test notarytool access
xcrun notarytool history --keychain-profile "AC_PASSWORD"

# Should show: No submissions found (or list of previous submissions)
```

---

## Creating a Signed Release

### Prerequisites

- ✅ Joined Apple Developer Program
- ✅ Developer ID Application certificate installed
- ✅ `.env` file configured
- ✅ Notarytool credentials stored
- ✅ Git working directory clean
- ✅ CHANGELOG.md updated with version notes

### Release Process

1. **Update CHANGELOG.md**

   ```markdown
   ## [1.0.0] - 2026-05-12
   
   - Add expandable source filtering
   - Add multi-select batch operations
   - Fix app icon in unsigned builds
   - Add comprehensive test suite (85% coverage)
   ```

2. **Run Release Script**

   ```bash
   ./scripts/release.sh 1.0.0
   ```

### What the Script Does

1. ✅ Generates Xcode project
2. ✅ Builds app in Release configuration
3. ✅ **Signs with Developer ID Application certificate**
4. ✅ Exports signed app
5. ✅ Creates DMG with custom background
6. ✅ **Notarizes DMG with Apple**
7. ✅ **Staples notarization ticket to app**
8. ✅ Creates final DMG
9. ✅ Tags git commit
10. ✅ Generates Sparkle appcast (auto-updates)
11. ✅ Creates GitHub Release with DMG
12. ✅ Updates site/public/appcast.xml

### Output

```
build/
├── Chops.dmg           # Signed, notarized, ready to distribute
├── Chops.xcarchive     # Archive for re-export if needed
└── export/
    └── Chops.app       # Signed, notarized app bundle
```

---

## Distributing the App

### GitHub Release (Primary)

The release script automatically creates a GitHub release at:
```
https://github.com/Shpigford/chops/releases/tag/v1.0.0
```

Users download `Chops.dmg` and drag to Applications.

### Direct Download

Host `Chops.dmg` on your website:
```
https://chops.md/downloads/Chops.dmg
```

### Sparkle Auto-Updates

Already configured! The app checks for updates via:
```
https://chops.md/appcast.xml
```

When you release a new version:
1. ✅ Script updates `site/public/appcast.xml`
2. ✅ Users get in-app update notifications
3. ✅ Updates download and install automatically

---

## Verification

### Verify Signing

```bash
codesign -dvvv build/export/Chops.app
```

Should show:
- ✅ `Authority=Developer ID Application: Your Name (TEAM_ID)`
- ✅ `Signature=adhoc` if unsigned, or full signature if signed
- ✅ `Signed Time=...`

### Verify Notarization

```bash
spctl -a -vv build/export/Chops.app
```

Should show:
- ✅ `build/export/Chops.app: accepted`
- ✅ `source=Notarized Developer ID`

### Verify DMG

```bash
spctl -a -t open --context context:primary-signature -v build/Chops.dmg
```

Should show:
- ✅ `build/Chops.dmg: accepted`

---

## Troubleshooting

### "Unable to use notarytool keychain profile"

**Solution:**
```bash
xcrun notarytool store-credentials "AC_PASSWORD" \
  --apple-id "you@example.com" \
  --team-id "ABC123XYZ" \
  --password "app-specific-password"
```

### "No signing identity found"

**Solution:**
1. Open Xcode → Settings → Accounts
2. Select account → "Manage Certificates"
3. Click "+" → "Developer ID Application"
4. Wait for certificate to be created

### "Certificate not trusted"

**Solution:**
1. Open Keychain Access
2. Find "Developer ID Application" certificate
3. Double-click → Trust → "Always Trust"

### Notarization Fails

**Check status:**
```bash
# Get submission ID from release script output
xcrun notarytool log <submission-id> --keychain-profile "AC_PASSWORD"
```

**Common issues:**
- Hardened Runtime not enabled → Check project.yml `ENABLE_HARDENED_RUNTIME: YES`
- Entitlements issues → Check `Chops/Chops.entitlements`
- Code signing errors → Run `codesign -dvvv` to diagnose

### "App is damaged" on user's Mac

**Cause:** App lost Extended Attributes during download/transfer

**Solution:** Redistribute via DMG (not raw .app folder)

---

## CI/CD Integration (Optional)

### GitHub Actions Signed Builds

To sign in CI, you need to:

1. **Export certificates from Keychain**
   ```bash
   # Export Developer ID Application certificate
   security find-identity -v -p codesigning
   # Right-click certificate in Keychain → Export
   # Save as: Certificates.p12 (with password)
   ```

2. **Add GitHub Secrets**
   - `APPLE_TEAM_ID`
   - `APPLE_ID`
   - `SIGNING_IDENTITY_NAME`
   - `CERTIFICATES_P12` (base64 of .p12 file)
   - `CERTIFICATES_PASSWORD`
   - `NOTARIZATION_PASSWORD` (app-specific password)

3. **Update `.github/workflows/build.yml`**
   
   Add signing step:
   ```yaml
   - name: Import certificates
     run: |
       echo "${{ secrets.CERTIFICATES_P12 }}" | base64 --decode > certificate.p12
       security create-keychain -p actions temp.keychain
       security import certificate.p12 -k temp.keychain -P "${{ secrets.CERTIFICATES_PASSWORD }}"
       security set-key-partition-list -S apple-tool:,apple: -s -k actions temp.keychain
       security list-keychains -s temp.keychain
       security default-keychain -s temp.keychain
   ```

**Note:** This is complex. Local signing is recommended for releases.

---

## Cost Summary

| Item | Cost | Required For |
|------|------|-------------|
| Apple Developer Program | $99/year | Code signing, notarization, distribution |
| Developer ID Certificate | Free | Included with membership |
| Notarization | Free | Included with membership |
| GitHub Releases | Free | Public repos |
| Domain for appcast | ~$15/year | Auto-updates (optional) |

**Minimum:** $99/year for Apple Developer Program

---

## Alternative: Unsigned Distribution

If you don't want to pay $99/year:

### Option 1: Unsigned + Instructions

Distribute with instructions:
```
1. Download Chops.app.zip
2. Right-click Chops.app → Open
3. Click "Open" when warned about unsigned app
```

**Downsides:**
- ❌ Scary warning for users
- ❌ No auto-updates (Sparkle requires signing)
- ❌ Less professional

### Option 2: Self-Signing

```bash
codesign --force --deep --sign - Chops.app
```

**Downsides:**
- ❌ Still shows Gatekeeper warning
- ❌ Can't notarize
- ❌ No auto-updates

### Option 3: Open Source Distribution

Ask users to build from source:
```bash
git clone https://github.com/Shpigford/chops
cd chops
xcodegen generate
xcodebuild -scheme Chops -configuration Release
```

**Downsides:**
- ❌ Requires Xcode (huge download)
- ❌ Technical users only
- ❌ No auto-updates

---

## Recommended Approach

**For serious distribution: Join Apple Developer Program**

- Users trust signed apps
- Auto-updates work seamlessly
- Professional user experience
- One-time $99/year investment

**For testing/development: Use CI unsigned builds**

- Perfect for testing
- Quick iteration
- No signing overhead

---

## Summary

| Build Type | Signed | Notarized | Use Case |
|------------|--------|-----------|----------|
| CI Debug | ❌ | ❌ | Development, testing |
| Local Release | ✅ | ✅ | Production distribution |
| GitHub Release | ✅ | ✅ | Public downloads |

**Current setup:** All infrastructure ready, just needs Apple Developer credentials!

**Next steps:**
1. Join Apple Developer Program ($99/year)
2. Create `.env` with credentials
3. Run `./scripts/release.sh 1.0.0`
4. App is signed, notarized, and published!
