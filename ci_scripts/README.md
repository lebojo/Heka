# iOS beta builds with Xcode Cloud

The **iOS Beta** workflow is enabled in Xcode Cloud and connected to `lebojo/Heka`. It builds and archives iOS on changes to `main`. Its external TestFlight post-action uses the **Github link** group and the **Archive - iOS** artifact. The shared schemes and scripts in this branch must be merged into `main` before the first Cloud run can use them; no Cloud run has been validated yet.

App: `6831797156`; Cloud product: `c42d365c-baba-41bf-871c-b61818834f71`; workflow: `63057B02-D13C-48E0-B3FD-1DB220349956`. `ios-beta-workflow.json` records the API update used for the build actions and start condition. TestFlight post-actions are configured separately in Xcode, because the public API does not expose them.

## Workflow settings

To edit the workflow, open `Heka.xcodeproj` and use **Report navigator → Cloud → Heka → Manage Workflows**, or open Heka Mobile's Xcode Cloud tab in App Store Connect. The app belongs to team `TS45UKZHX5`, with bundle ID `ch.jordanchap.heka`.

Use these settings, matching StreamClipper's build/archive workflow:

| Setting | Value |
| --- | --- |
| Name | iOS Beta |
| Project | `Heka.xcodeproj` |
| Scheme for both actions | `Heka-iOS` |
| Xcode | 27.2 (the version used for local validation) |
| Environment | Compatible macOS version, **Clean** enabled |
| Start condition | **Branch Changes**, exact branch `main`, any file change |
| Other automatic start conditions | None: remove suggested pull request, tag, and schedule conditions |
| Build action | **iOS**, Any iOS Device, required to pass |
| Archive action | **iOS**, Release, required to pass, **TestFlight and App Store** distribution |
| Post-action | TestFlight External Testing → **Github link** |

Branch Changes runs after every merge into `main`, and also after a direct push to `main`. Do not add macOS actions. The host machine runs macOS, but both build actions target iOS. The shared target still supports normal local Mac builds.

The **Github link** group owns [the public TestFlight invitation](https://testflight.apple.com/join/DsVPEUqk). External distribution needs a clean build and an archive eligible for App Store distribution; do not select **TestFlight Internal Only**. Apple's beta review and any required TestFlight information still apply. The post-actions must be selected in Xcode or App Store Connect, even when a workflow is otherwise managed through the API.

## Build preparation

`ci_post_clone.sh` runs only inside Xcode Cloud, refuses non-iOS actions, and updates the temporary checkout's `CURRENT_PROJECT_VERSION` to `CI_BUILD_NUMBER + 1`. Build 1 of version 0.5.0 was already uploaded manually, so Cloud build 1 becomes app build 2. Keep the offset stable and do not reset the Cloud counter; if uploading a manual build later, choose its number in coordination with the next Cloud build.

The script also enables SwiftTerm's pinned build-info package plugin on the disposable Cloud machine. It does not change `MARKETING_VERSION`, create tags, or publish a GitHub release. The existing macOS release workflow remains separate.

The iOS Info.plist explicitly carries `ITSAppUsesNonExemptEncryption = NO`, matching the existing TestFlight build's declaration, so subsequent uploads retain that export-compliance answer. Reassess it if the app's use of encryption changes.

## Check the first run

After merging the repository changes into `main`, use App Store Connect → Heka Mobile → Xcode Cloud to confirm that only the two iOS actions ran, then check TestFlight for the new build and its external distribution post-action. The existing **Intern** group is also available if an additional internal-testing post-action is wanted. A local unsigned archive verifies compilation, not Cloud signing, upload, or beta review.

```sh
asc xcode-cloud workflows --app 6831797156
asc builds list --app 6831797156 --limit 5
```

Apple references: [first workflow setup](https://developer.apple.com/documentation/xcode/configuring-your-first-xcode-cloud-workflow), [workflow settings and post-actions](https://developer.apple.com/documentation/xcode/xcode-cloud-workflow-reference), [environment variables](https://developer.apple.com/documentation/xcode/environment-variable-reference).
