[PLANS]
- 2026-05-09T18:32:56+0200 [USER] Implement Chops-native Sources in Settings, source-only Library Skills, managed symlink installs/uninstalls, and prompt skill mentions.
- 2026-05-11T15:32:21+0200 [USER] Add GitHub Actions CI so builds can run remotely when local Xcode tooling is unavailable.

[DECISIONS]
- 2026-05-09T18:32:56+0200 [CODE] Store Sources and install manifests as JSON under Application Support instead of adding SwiftData models.
- 2026-05-09T18:32:56+0200 [CODE] Use symlink-only installs for v1 and refuse unmanaged target conflicts.
- 2026-05-11T15:41:42+0200 [USER] Keep the Build GitHub Actions workflow manual-only for now.

[PROGRESS]
- 2026-05-09T18:32:56+0200 [CODE] Added Source models/services, Settings > Sources UI, source scanner integration, source-only Library Skills filtering, install target sheet, source metadata badges, and prompt mention resolution.
- 2026-05-11T15:32:21+0200 [CODE] Added `.github/workflows/build.yml` with a macOS 15 XcodeGen + unsigned Debug app build and an Ubuntu Astro site build.
- 2026-05-11T15:41:42+0200 [CODE] Changed `.github/workflows/build.yml` triggers to `workflow_dispatch` only.

[DISCOVERIES]
- 2026-05-09T18:32:56+0200 [TOOL] `xcodegen` is not installed and `xcodebuild` is blocked because active developer directory is Command Line Tools, not full Xcode.
- 2026-05-11T15:32:21+0200 [TOOL] GitHub-hosted runner docs list `macos-15` as an available macOS runner label; local `xcodebuild` remains blocked by Command Line Tools.

[OUTCOMES]
- 2026-05-09T18:32:56+0200 [TOOL] Swift syntax parse for edited files succeeded; full app build remains unverified due local Xcode tooling blocker.
- 2026-05-09T18:35:23+0200 [TOOL] `git diff --check` passed; Swift syntax parse passed; focused typechecks for new Source services/settings/install/mention helpers passed with stubs where SwiftData blocked standalone typecheck.
- 2026-05-11T15:32:21+0200 [TOOL] Workflow YAML parsed successfully, XcodeGen generated a check project under `.context`, and `npm run build` passed for `site`; native app build deferred to GitHub Actions.
