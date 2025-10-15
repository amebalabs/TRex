# TRex CI/CD Setup

This directory contains the GitHub Actions workflow and custom actions for building, signing, notarizing, and releasing TRex.

## Overview

The CI/CD pipeline automates the entire release process:
1. Building universal binaries for TRex and TRex CMD
2. Code signing with Developer ID certificate
3. Notarization with Apple
4. Sparkle signature generation for auto-updates
5. Creating GitHub releases
6. Updating Sparkle appcast files
7. Generating Homebrew formula
8. Deploying to GitHub Pages

## Workflow Triggers

The workflow runs on:
- **Release builds**: Tags matching `v*.*.*` or `v*.*.*-beta.*`
- **Test builds**: Pull requests to main branch
- **CI builds**: Pushes to non-main branches

## Required Secrets

Before using this workflow, configure these secrets in your GitHub repository:

### Code Signing
- `CERTIFICATE_P12`: Base64 encoded Developer ID Application certificate
  ```bash
  base64 -i certificate.p12 | pbcopy
  ```
- `CERTIFICATE_PASSWORD`: Password for the P12 certificate

### Notarization
- `APPLE_ID`: Apple ID email for notarization
- `NOTARIZATION_PASSWORD`: App-specific password (create at appleid.apple.com)
- `TEAM_ID`: Your Apple Developer Team ID

### Sparkle Updates
- `SPARKLE_PRIVATE_KEY`: EdDSA private key for Sparkle signatures
  ```bash
  # Generate key pair if needed
  ./generate_keys
  ```

## Release Process

1. **Create release notes**: Add a file to `docs/release-notes/VERSION.md`
2. **Tag the release**: 
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
3. **Automatic steps**:
   - Workflow builds and signs the app
   - Submits for notarization
   - Creates GitHub release with ZIP archive
   - Updates appcast.xml (or appcast_beta.xml for beta)
   - Updates CHANGELOG.md
   - Generates Homebrew formula (stable releases only)
   - Deploys docs to GitHub Pages

## File Structure

```
.github/
├── workflows/
│   └── release.yml          # Main workflow file
├── actions/
│   ├── sign/               # Code signing action
│   │   └── action.yaml
│   ├── notarize/           # Notarization action
│   │   └── action.yaml
│   └── sparkle-sign/       # Sparkle signature action
│       └── action.yaml
└── README.md               # This file

docs/
├── release-notes/          # Release notes for each version
│   ├── README.md
│   └── VERSION.md
├── appcast.xml            # Sparkle update feed (stable)
├── appcast_beta.xml       # Sparkle update feed (beta)
└── homebrew/              # Homebrew formula
    └── trex.rb
```

## Beta vs Stable Releases

- **Stable**: Tag as `v1.0.0`
  - Updates `appcast.xml`
  - Generates Homebrew formula
  - Creates standard GitHub release

- **Beta**: Tag as `v1.0.0-beta.1`
  - Updates `appcast_beta.xml`
  - No Homebrew formula
  - Creates pre-release on GitHub

## Troubleshooting

### Certificate Issues
- Ensure certificate is "Developer ID Application" type
- Certificate must not be expired
- Password must be correct

### Notarization Failures
- Check that all frameworks and libraries are signed
- Ensure proper entitlements are set
- Verify bundle ID matches certificate

### Sparkle Signature Issues
- Private key must be in correct format
- Use the matching public key in your app

## Local Testing

Test the build process locally:
```bash
# Build release version
xcodebuild -scheme TRex -configuration Release build

# Test signing (requires certificate)
codesign --force --deep --sign "Developer ID Application: Your Name" TRex.app

# Test notarization (requires credentials)
xcrun notarytool submit TRex.zip --apple-id your@email.com --password app-password --team-id TEAMID
```