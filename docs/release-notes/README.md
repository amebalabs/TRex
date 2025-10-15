# Release Notes Guide

This directory contains release notes for each version of TRex.

## Creating Release Notes

1. Before tagging a new release, create a file named `VERSION.md` in this directory
2. Use the following format:

```markdown
### Features
- New feature 1
- New feature 2

### Improvements
- Improvement 1
- Improvement 2

### Fixes
- Bug fix 1
- Bug fix 2

### Technical Details
- Any technical changes worth noting
```

3. The release notes will be automatically included in:
   - GitHub release description
   - Sparkle appcast for auto-updates
   - CHANGELOG.md

## Version Naming

- Production releases: `1.0.0`, `1.1.0`, etc.
- Beta releases: `1.0.0-beta.1`, `1.0.0-beta.2`, etc.