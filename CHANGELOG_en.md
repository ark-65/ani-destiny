<!-- Keep a Changelog guide -> https://keepachangelog.com -->

# AniDestiny Changelog

> [中文更新日志](./CHANGELOG.md) | English Changelog

## [Unreleased]

### 🐛 Fixed
- Fixed failed `Retry` attempts dropping the interrupted playback position and speed context, which made the next recovery attempt feel like starting over; when a retry still cannot resume playback, AniDestiny now keeps the last interruption context visible so the failure state and the next retry both continue from the same place.
- Fixed the player already exposing a direct `Retry` action while the failure message and disabled-control copy still told users to retry later; the shared failure wording now says to retry now or try another playback line so the recovery state uses one consistent voice.
- Fixed the playback-failure card keeping its `Next episode` and `External player` recovery actions less explicit than the main player controls; those failure-state actions now reuse the same tooltip explanations and subdued styling, so "already on the latest episode" and "this stream must stay in AniDestiny" are just as clear without leaving the error scene.
- Fixed `Next episode` recovery still living mainly in the app bar or fullscreen controls after playback had already failed, which made users leave the failure scene to find the obvious keep-watching path; the failure card now exposes that action directly and reuses the existing switching-state and latest-episode explanation behavior so continuing forward stays in the same recovery surface.
- Fixed the playback-failure card hiding the main `External player` recovery action entirely on header-protected streams and leaving only a small explanatory note behind; the failure state now keeps that entry visible but honestly disabled, so this boundary reads the same way it already does on the normal player screen.
- Fixed header-protected external handoff limits still describing the blocked stream as a vague "playback" instead of naming the active source AniDestiny was keeping in-app; the disabled tooltip, failure card, and immediate feedback now call out the actual source that stays in AniDestiny so this boundary feels as specific as the newer handoff success and failure copy.
- Fixed successful and failed `External player` handoffs still talking only about "current playback" without naming which source AniDestiny was actually handing off; the confirmation and failure copy now call out the active source directly so fallback-backed handoffs stay specific and trustworthy.
- Fixed fallback-backed playback failures still leading with only diagnostic source/line context after AniDestiny had already switched away from the requested source; the failure card now first says plainly which source AniDestiny continued from, then keeps the detailed diagnostics underneath so users understand the outcome before the internals.
- Fixed successful next-episode handoffs that quietly fell back to another source still ending with a generic source-unavailable toast; the player now uses the same explicit source-switch wording as the in-page fallback banner, so users can immediately see which source AniDestiny kept playing from.
- Fixed the player fallback banner still describing a recovered stream as “fallback data”, which made a steady playback handoff sound like implementation detail. It now says plainly which source AniDestiny switched to so the result feels calmer and easier to trust.
- Fixed fullscreen route-level handoffs like `Next episode`, `Retrying playback...`, and `Opening external player...` still leaving the visible `Exit fullscreen` control as a dead tap target for touch users; that visible exit affordance now explains the active busy reason directly, so it stays consistent with system back and the embedded back arrow.
- Fixed failed `External player` handoffs only telling users to try again later without clearly saying the current episode was still staying inside AniDestiny; the failure copy now explicitly says playback remains in AniDestiny so an interrupted handoff still feels honest.
- Fixed player exit attempts during route-level handoffs like `Next episode`, `Opening external player...`, and `Retrying playback...` still collapsing to one generic "current playback action" warning without saying what AniDestiny was actually waiting on; app-bar Back and system back now explain the active handoff directly, so leaving the player uses the same honest language as the visible busy state.
- Fixed the embedded player app-bar Back arrow becoming a dead tap target during route-level handoffs like `Next episode`, `Retrying playback...`, and `Opening external player...` while system back still explained that AniDestiny needed a moment; that leading exit affordance now surfaces the same busy explanation instead of silently doing nothing, so every way of leaving the player stays consistent.
- Fixed successful `External player` handoffs providing almost no explicit confirmation inside AniDestiny itself, which made the transition feel like "maybe that tap worked" unless the system app-switch was obvious; the player now shows one short in-app confirmation once the current playback has been opened externally.
- Fixed the playback-failure screen still leaving the previous episode's danmaku overlay and danmaku status badge visible behind the error card; once playback has failed, AniDestiny now clears that stale viewing chrome first so the page only communicates the failure and the available recovery actions.
- Fixed embedded playback keeping only the episode title in the app bar while `Next episode`, `Retrying playback...`, or `Opening external player...` was already taking over the page; the non-fullscreen app bar now keeps the current or upcoming episode title and adds one short status line so waiting states stay calm without hiding the active handoff.
- Fixed AniDestiny still falling back to vague `No playable source found` or `Source temporarily unavailable` copy when users were already in a failed playback state, tapped `Next episode`, and the handoff never truly left the current episode; any aborted next-episode attempt that keeps the current page now explicitly says it stayed on the current episode so the recovery result itself stays honest.
- Fixed the player going silently inert once AniDestiny already knew the current episode was the latest available one, which left touch users with no immediate explanation; embedded and fullscreen playback now keep a subdued `Next episode` entry that can still explain "You are already on the latest available episode." on contact, so the boundary no longer feels like a broken button.
- Fixed AniDestiny clearing away the current playback-failure scene after a successful `External player` handoff from an already failed stream, which made the app look recovered when users came back even though in-app playback had never resumed; the original failure card now returns after the handoff completes so the external escape hatch and the in-app failure stay equally honest.
- Fixed fullscreen playback still making `External player` look available after AniDestiny had already entered `Retrying playback...`; that escape hatch now joins the same retry busy lock and copy, so users cannot interrupt the current recovery path by starting a second handoff mid-retry.
- Fixed the player still making `Next episode` look worth trying even when AniDestiny already had the current episode list in memory and could tell the user was on the last available episode; embedded and fullscreen playback now tone that action down and explain that there is no later episode yet, so users are not invited into a dead end before the player tells them the truth.
- Fixed the player still leaving the previous playback timeline and progress bar visible after AniDestiny had already entered a route-level handoff like `Next episode`, `Retrying playback...`, or `Opening external player...`; those busy states now switch the bottom transport row into a neutral time display so the page only communicates the in-progress takeover instead of implying the old stream is still active.
- Fixed embedded player transitions repeating the same busy message in both the app-bar status line and the centered handoff overlay during `Next episode`, `Retrying playback...`, and `Opening external player...`; embedded mode now keeps only the current or upcoming episode title in the app bar and leaves the action message to the overlay so the handoff feels calmer.
- Fixed the player still reporting a generic source failure after a `Next episode` handoff had already been rolled back to the current episode; it now explicitly says the next episode could not be opened and that AniDestiny stayed on the current one, so the recovery outcome is as clear as the rollback behavior itself.
- Fixed the player still making `Enter fullscreen` look available before playback was actually ready or after the current playback had already failed; it now only allows entering fullscreen once the current stream is truly playable, while users who are already fullscreen can still exit reliably so the control behaves like a viewing action instead of an empty promise.
- Fixed the player still making `External player` look tappable on header-protected streams that AniDestiny cannot safely hand off, only to repeat the same limitation after users tapped it; the action now stays disabled up front so the affordance matches the explanation before users try it.
- Fixed the embedded player app bar dropping its short `Loading next episode...` status as soon as AniDestiny learned the upcoming episode title, which made the page look finished before the takeover had actually completed; the app bar now keeps that loading line until the switch truly settles so the title and busy state stay honest together.
- Fixed the embedded player keeping its fallback-source banner visible while route-level handoffs like `Retrying playback...` or `Opening external player...` were already taking over the page; those busy states now hide the secondary fallback notice first so the screen explains one in-progress action at a time.
- Fixed the player quietly disabling `External player` while still explaining the limit with implementation-heavy copy like `request headers`; users can now still tap into a clear reason, and the message now explains the product boundary in calmer product language instead of network internals.
- Fixed the embedded player app bar either dropping episode context or competing with the centered transition copy during route-level handoffs like `Next episode`, `Retrying playback...`, and `Opening external player...`; non-fullscreen playback now keeps the current or upcoming episode title visible and only adds a short busy line when it is still needed, so transitions feel calmer without hiding what is happening.
- Fixed the embedded player app bar keeping the stale episode title while AniDestiny had already entered `Retrying playback...` or `Opening external player...`; non-fullscreen playback now switches that title to the active route-level action so the page explains what it is doing as clearly as the next-episode transition already does.
- Fixed the player still leaving the previous episode's danmaku overlay and danmaku status badge on screen after AniDestiny had already entered `Retrying playback...` or `Opening external player...`; those route-level handoff states now clear the stale danmaku chrome first so the transition only communicates the one action currently in progress.
- Fixed AniDestiny often leaving the next episode paused after users escaped a temporary playback failure by tapping `Next episode`; once the switch succeeds, that explicit keep-watching action now starts the new episode immediately instead of making users press Play again.
- Fixed the player staying stuck on the old playback-failure card after users chose `External player` from that failure state, which made the stale error UI compete with the new handoff action; the page now switches into the same explicit `Opening external player...` transition first and restores the original failure state only if the system handoff cannot be launched.
- Fixed the player showing `Opening external player...` immediately while still letting the current video keep playing until the system app launch actually succeeded; AniDestiny now pauses playback as soon as the handoff starts and automatically resumes it if the handoff fails, so the transition no longer sends mixed signals about whether playback has really left the app.
- Fixed fullscreen playback still making system back and `Exit fullscreen` feel immediately available after AniDestiny had already entered a route-level busy state like next-episode switching, retry recovery, or external-player handoff; those fullscreen exit paths now reuse the active busy copy and stay locked until the current takeover finishes, so the player no longer flips back to embedded mode mid-transition.
- Fixed the embedded player still leaving its app-bar Back arrow looking immediately usable after AniDestiny had already entered a route-level busy state like `Next episode`, `Retrying playback...`, or `Opening external player...`; that exit affordance now joins the same busy lock so the page no longer claims "please wait" while still glowing with a seemingly available way out.
- Fixed external-player handoff mostly hiding its busy feedback inside a spinning button, which made it hard to tell at a glance whether AniDestiny was still opening another app; the player now shows a centered `Opening external player...` transition overlay as well, and fullscreen handoff keeps the current episode title visible so the takeover feels like one explicit in-progress action.
- Fixed the player repeating the same episode title in both the app bar and the centered transition card while `Next episode` or `Retrying playback...` was already in progress on the embedded page; embedded playback now keeps one primary title while fullscreen still shows the takeover title in the overlay, so the handoff reads like one deliberate action instead of layered UI noise.
- Fixed the player stacking a second generic loading spinner on top of the explicit transition overlay while `Loading next episode...` or `Retrying playback...` was already in progress; those handoff states now keep one consistent busy indicator so the waiting screen feels calmer instead of looking like two competing loads.
- Fixed the player clearing away the current episode's failure card when users tried `Next episode` from an already failed playback state but AniDestiny then discovered there was no real next episode or no playable source after all; if the handoff aborts before the page truly leaves the current episode, the original failure UI now returns so "the switch did not happen" does not look like "the error disappeared."
- Fixed retry recovery mostly reducing the player to a spinner and disabled buttons, which left touch users without any explicit on-screen confirmation that playback recovery had actually started; the page now shows a centered `Retrying playback...` transition overlay so failure recovery feels like an active handoff instead of a silent freeze.
- Fixed the player still leaving the danmaku toggle feeling immediately usable while a route-level transition like Next episode, Retry playback, or External player handoff was already in progress; those busy states now lock the toggle together with the rest of the critical controls and reuse the active transition copy so users are not changing stale playback chrome mid-handoff.
- Fixed the player app bar still showing the previous episode title after AniDestiny had already entered the next-episode transition; the title now switches to `Loading next episode...` first and then updates to the upcoming episode once it is known, so the page no longer presents two competing episode contexts at the same time.
- Fixed the player still keeping the previous episode's fallback-source banner visible after it had already entered the `Loading next episode...` transition; the banner now hides as soon as the switch begins so the new handoff is not competing with stale source context from the episode users are leaving.
- Fixed the player keeping the previous episode's failure card on screen even after users had already chosen to continue into `Next episode`; once the next-episode transition starts, the page now clears that stale error UI immediately and enters the shared switching state so moving forward no longer feels mixed with being stuck on the old failure.
- Fixed the player already showing a clear next-episode transition overlay while still leaving the previous episode timeline and timestamps in the bottom controls; the switch state now clears that stale progress chrome first so users do not think the old episode is still active.
- Fixed the player leaving the previous episode's danmaku overlay and danmaku status badge on screen while `Next episode` was still switching; the transition now clears that stale episode chrome first so the handoff feels calmer and more deliberate.
- Fixed next-episode switching hiding most of its critical waiting state inside disabled buttons; the player now shows a centered `Loading next episode...` transition overlay and, once the target is known, names the upcoming episode so the handoff feels intentional instead of frozen.
- Fixed next-episode switching leaving users on a broken new episode page when the target episode had already been selected but failed before playback could really start; the player now restores the current episode and resumes the original playback so a failed switch behaves like a safe cancellation instead of a confusing half-transition.
- Fixed Next episode pausing the current stream and then leaving users stuck on a stopped player when AniDestiny discovered there was no real next episode or no playable source before the switch completed; the current episode now resumes automatically whenever the transition aborts before playback actually leaves it.
- Fixed the player still letting the current episode continue for a short moment after users tapped Next episode but before the new episode actually took over; it now pauses the current playback first, then enters the loading-next-episode state so the transition feels clearly committed instead of making users wonder whether the tap registered.
- Fixed Runtime diagnostics already surfacing the latest playback snapshot while still leaving users unsure whether it matched the playback they had just seen; the snapshot now shows when it was captured, the section copy explains that this page already holds the latest playback context, and copied support summaries carry the same time anchor so confirm-then-report feels trustworthy.
- Fixed the Runtime diagnostics page still making users bounce back to the player if they wanted to confirm the last playback context before reporting an issue; it now shows the most recent anime, episode, requested source, active source, line, URL type, sanitized URL, and request-header names directly in Settings so the inspect-and-report flow stays in one place.
- Fixed Source settings and Runtime diagnostics already exposing source health and recent issues while still leaving users to infer the next step themselves; unstable or unavailable sources now explain whether to retry later or switch sources, and healthy rows no longer clutter the support flow with reset actions or `0`-failure noise by default.
- Fixed Runtime diagnostics and Source diagnostics showing raw inline error snippets that could still contain tokens, session values, cookie text, or HTML fragments even though the copied support summary was already sanitized; the on-screen diagnostics now apply the same redaction path so the first support surface is no leakier than the copied one.
- Fixed users being able to inspect recent source failures and fallback events in `Source settings -> Source diagnostics` while still needing to back out to another page before they could copy a support summary; the sheet now lets them copy sanitized diagnostics in place so checking source health and reporting it is one continuous flow.
- Fixed the runtime diagnostics page still making users back out to Settings before they could copy the sanitized feedback summary; it now lets them copy diagnostics in place so the inspect-and-report support flow stays intact.
- Fixed Runtime diagnostics already being able to explain the current source, fallback history, and recent diagnostics while still being hidden behind debug-only Settings UI; regular users can now open it from Settings before copying a support summary.
- Fixed the Settings page's copied diagnostics summary still mixing engineering-facing output like `sakura`, `detail`, `true/false`, and `healthy`; it now follows the active locale for headings, field labels, status words, and download reasons so shared support notes read like product copy instead of an internal dump.
- Fixed runtime diagnostics and source diagnostics still exposing engineering-facing terms like `Debug`, `fallback`, `detail`, `Headers`, `true/false`, and raw platform identifiers; they now use localized support copy, operation labels, boolean values, and platform names so the diagnostics flow feels like product UI instead of an internal panel.
- Fixed Source Settings and Runtime diagnostics still exposing raw English health states like `Healthy`, `Degraded`, and `Unavailable` to Chinese and Japanese users; those diagnostics now use localized status labels so the support flow feels less like an internal panel.

### 🔧 CI/CD
- Fixed `player_controls_test` still asserting that fullscreen `Loading next episode...` kept `Exit fullscreen` immediately available; the widget test now matches the real player behavior and verifies that fullscreen exit shares the same busy copy and lock while the handoff is in progress, so this playback-trust change no longer gets stuck behind stale expectations.
- Fixed the changelog gate shallow-fetching the base branch and then diffing with `...`, which could falsely fail with `no merge base` after certain PR syncs; it now keeps the base history intact and computes the merge base explicitly so the Chinese/English changelog check stays stable on normal PR histories.
- Tightened the player failure-card diagnostics-copy assertion around the new `Request headers` wording so PR validation keeps protecting the localized support copy instead of failing on stale expectations.
- Removed the unused `permission_handler` dependency that was breaking `flutter build windows --release` on the newer GitHub Windows runner, so the Windows delivery path is no longer blocked by an unused platform plugin.

## [1.0.3] - 2026-06-13

### 🐛 Fixed
- Fixed the player only explaining source fallback in a transient pre-navigation message and then losing that context after the page opened; the player page now keeps the active fallback source visible and includes the originally requested source in playback diagnostics so users do not have to guess why playback came from a different source.
- Fixed the player failure card hiding the External player limitation inside a disabled button state when the current stream still depended on request headers; it now explains the handoff constraint directly in the failure state so users do not have to guess why another app cannot take over yet.
- Fixed player failure recovery and copied diagnostics still missing the anime and episode context, so the failure card, playback diagnostics, and feedback package now all carry the current title and episode for more precise user reports.
- Fixed the player failure card already offering retry and diagnostics while still hiding the External player escape hatch in the surrounding controls; when the current stream can really be handed off, the failure state now exposes that action directly and keeps a clear busy state during handoff.
- Fixed constrained player layouts on narrow or short screens from breaking both the failure card and bottom controls; the error card now scrolls and the controls wrap to the available width so recovery actions like Copy diagnostics stay reachable.
- Fixed the player failure state already exposing Playback diagnostics without offering any direct way to take away a sanitized summary; the error card and diagnostics sheet now both provide Copy diagnostics so users can share the current source, line, and playback state immediately.
- Fixed playback retries after an in-progress failure restarting from an older position or the beginning; retry now resumes from the current known playback position so temporary interruptions feel like continuing the same episode instead of starting over.
- Fixed the player already locking its controls during `Retrying playback...` while still letting system back leave the page; retry recovery now counts as a route-level busy transition so users do not exit before the current recovery path finishes.
- Fixed the player starting a retry after a temporary playback failure while still making next-episode, external-player, download, and enter-fullscreen actions look usable; retry now puts those controls into a shared `Retrying playback...` busy state so the current recovery path stays unambiguous.
- Fixed the player only offering diagnostics after a temporary playback failure without any in-place retry path; the error card now includes a direct Retry action, while no-playable-source states still avoid promising a retry that cannot work.
- Fixed the player already showing the current source and line in the error card while still hiding playback diagnostics in a debug-only corner; the error state now includes a direct Playback diagnostics button so users can inspect a shareable summary right where playback failed.
- Fixed the player only showing a generic error when no playable source or a temporary playback failure occurred, without telling users which source and line were involved; the error card now also shows the current source and playback line so users can decide whether to retry, switch sources, or choose another line more confidently.
- Fixed the player still letting back navigation leave the page while a next-episode switch or external-player handoff was still in flight; it now keeps users on the current player page and explains that the current playback action needs to finish first.
- Fixed the player still allowing users to enter fullscreen while Next episode was loading; embedded playback now disables Enter fullscreen and explains that the switch is still in progress, while already-fullscreen playback still keeps Exit fullscreen available as the stable way back out.
- Fixed the player still making next-episode, play, seek, playback-speed, download, and fullscreen controls look usable while an external-player handoff was already opening; those actions now share the same busy disabled state and explain that the handoff is still in progress.
- Fixed the External player action still allowing repeated taps without a clear busy state during handoff; it now shows an opening state and stays disabled until the handoff finishes.
- Fixed AniDestiny staying fullscreen or continuing local playback after a successful External player handoff; it now exits fullscreen and pauses in-app playback once another player takes over.
- Fixed the player time display always wrapping as `MM:SS`, so videos longer than 59 minutes now show hours instead of making long-form playback look like it jumped backward.
- Fixed the player still making play, seek, and playback-speed controls look usable before playback was ready or after load had already failed; those controls now stay disabled and explain whether playback is still preparing or has temporarily failed.
- Fixed malformed playback URLs still falling through to the generic playback-failed state; they are now treated the same as empty links so the placeholder and primary controls consistently explain that no playable source is available.
- Fixed the player leaving play, seek, and playback-speed controls tappable while Next episode was still loading; those core playback actions now enter the same busy disabled state and explain that the next episode is still loading, instead of implying the current stream can still be controlled.
- Fixed the player still leaving play, seek, and playback-speed controls clickable when the current item had no playable source; those primary playback controls are now disabled together and explain that no playable source is available, instead of pretending playback can still continue.
- Fixed the player still exposing the download action when the current episode had no playable URL at all; it now disables the button and explains that no playable source is available, instead of implying the episode can still be saved offline.
- Fixed the player still allowing downloads and only showing generic control copy while Next episode was loading; switching state now consistently says it is loading the next episode and blocks downloads until the switch finishes.
- Fixed the player External player action still looking tappable when the current stream needed request headers or lacked a handoffable playback URL; it now disables the action up front and explains why the stream cannot be sent to another app.
- Fixed the External player action staying tappable while Next episode was still loading, so users can no longer hand the previous episode stream to another app mid-switch.
- Fixed the player fullscreen button always using a generic `Fullscreen` tooltip, so it now tells users whether the control will enter or exit fullscreen.
- Fixed fullscreen playback hiding the External player entry with the app bar; the fullscreen control bar now keeps the same action so users do not need to exit fullscreen first.
- Fixed the player External player action only showing a placeholder snackbar; it now hands plain playback URLs to the system external player, explains when header-protected streams cannot be handed off yet, and reports a clear failure message when launch is unavailable.
- Fixed the player playback-diagnostics sheet showing raw internal English state values; it now uses localized user-facing state labels.
- Fixed playback diagnostics keeping the previous line details after a player load failure or empty play URL; the diagnostics snapshot now refreshes as soon as each load attempt starts.
- Fixed `PlayerRouteArgs.copyWith()` clearing resume progress while only updating other playback fields; it now preserves `initialPosition` by default and only resets it when `null` is passed explicitly.
- Fixed system back leaving the player page immediately in fullscreen; it now exits fullscreen first and only leaves the page on the next back action.
- Fixed next-episode switching still failing when upstream episode titles changed between formats like `第12集`, `Episode 12`, and `EP12`; the player now keeps matching by episode number in the title when needed.
- Fixed next-episode playback stopping after refreshed episode data changed both the current episode id and index; the player now falls back to the current title when it still matches.
- Fixed fullscreen playback controls losing access to the Next episode action by adding the same entry point to the fullscreen control bar with the existing switching busy state.
- Fixed next-episode switching failing to keep the current playback line when upstream line ids changed but the line titles only differed by spacing or letter case.
- Fixed the player page Next episode action only showing a placeholder snackbar; it now switches to the next episode in place while preserving the current play line and playback speed when possible.
- Fixed Source Settings still labeling the production default `sakura` source as `Experimental`; it now shows a clear default-source badge instead.
- Fixed Source Settings and the settings-page source status still describing the production default `sakura` source as experimental; they now use consistent default-source and retry guidance copy.
- Fixed the source-localization widget tests using pages without a `Material/Scaffold` host and asserting against non-rendered exact labels, avoiding false CI failures on PR validation.
- Fixed unknown sources still exposing internal `sourceId` values when no readable name or description was available, falling back to neutral localized copy instead.
- Fixed the copied feedback diagnostics package still exposing raw internal source ids like `sakura` and `mock`; it now shows localized source names instead.
- Fixed runtime diagnostics, source diagnostics, and player diagnostics still showing raw internal source ids like `sakura` and `mock` to users; they now consistently show localized source names instead.
- Fixed favorites, search results, and schedule rows falling back to raw internal source ids like `sakura` and `mock` when no descriptive copy was available; they now show localized source names instead.
- Fixed release builds still exposing the Mock source in Source Settings to regular users; the settings list now keeps only production-selectable sources and migrates old Mock selections back to the default `sakura` source.
- Fixed Source Settings exposing raw technical identifiers like `id: mock` and `id: sakura` to users, so it now shows only localized names and descriptions.
- Fixed Source Settings still describing Mock as the most stable source, replacing it with neutral copy that matches the production default `sakura`.
- Fixed the search empty state still telling users to search the Mock source, replacing it with neutral copy for normal browsing.
- Fixed the downloads page exposing the Mock test-task action to regular users by default; it now only appears in debug builds.
- Fixed the player placeholder still exposing Mock wording to regular users, replacing it with a neutral playback preview hint.
- Fixed the player route falling back to the Mock source when `sourceId` is missing, so it now uses the default production source `sakura`.
- Fixed episode cards and the watch-history model still defaulting missing source metadata to Mock, so they now align with the production default source `sakura`.
- Fixed completed download tasks not offering direct removal, so finished records can now be cleared from the list.
- Fixed failed download tasks only offering cancel, so they now keep retry and allow direct removal.
- Fixed failed download tasks still showing the pause note even though they only support retry or removal.
- Fixed failed download tasks still showing a generic Start action, replacing it with a clear Retry label and icon.
- Fixed download progress labels showing values outside `0%` to `100%`, so out-of-range progress no longer leaks into the list UI.
- Fixed canceled download tasks being rendered as errors and reported as the latest diagnostics issue, avoiding misleading warnings after user-initiated cancellation.
- Fixed the downloads page only allowing one-by-one cleanup, adding a single action to clear completed, failed, canceled, and unsupported tasks together.
- Fixed batch cleanup stopping on the first deletion failure with no feedback, so the downloads page now keeps clearing the remaining ended tasks and reports the result; pause, cancel, and remove failures also surface immediately.
- Fixed batch cleanup staying tappable while it was already running, so the same ended tasks cannot be deleted repeatedly.
- Fixed per-task start, pause, cancel, retry, and remove actions staying tappable while they were already running, so each task now enters a busy state and blocks duplicate taps.
- Fixed ended tasks that were already being removed individually still being picked up by batch cleanup, preventing duplicate concurrent deletion attempts for the same task.
- Fixed batch cleanup still being available while an ended task action was already running, preventing overlapping cleanup flows and confusing feedback.

### 🔧 CI/CD
- Fixed the player-page widget tests still tapping the old generic `Fullscreen` tooltip, so PR CI now follows the new `Enter fullscreen` copy after the fullscreen-label update.
- Stabilized the schedule localization widget test across Flutter environments so `Sakura Anime` assertions no longer depend on `ExpansionTile` starting expanded.
- Fixed Source Settings and episode-list widget tests waiting too little for localization setup, avoiding false text-assertion failures during PR validation.
- Stabilized widget-test targeting for downloads cleanup and task actions so Flutter CI does not misread button structure differences as failures.
- Fixed flaky busy-state test waits and overly broad cleanup loading assertions so CI no longer fails on active progress indicators.

### 📚 Documentation
- Added GitHub issue templates for general bugs, playback/source issues, and feature requests.
- Added troubleshooting documentation for source, playback, danmaku, download, install, and diagnostics-copy flows.
- Updated README and reporting docs to guide users toward templates and sanitized diagnostics.
- Clarified release asset platform selection and changed the Android debug artifact example to use a version placeholder.
## [1.0.2] - 2026-05-29

### ✨ Added
- Added download type detection for direct files, HLS/m3u8, BT placeholders, and unknown URLs.
- Added an HLS/m3u8 manifest parser foundation for media and master playlists.
- Added download task fields for failure reasons, headers, byte progress, and local paths.
- Added a Copy diagnostics entry in Settings that generates a sanitized Markdown feedback summary.
- Added a feedback diagnostics package with app version, platform, source health, fallback, playback, danmaku, and download task status.
- Added a standard brand asset directory using the existing AniDestiny logo as the README and platform icon source.
- Added Android, Windows, and macOS platform icon assets generated from the existing logo.
- Added a release page entry, runtime diagnostics page, and copyable feedback summary for playback and source issues.
- Added source health state, failure counts, recent issue summaries, and manual reset support.
- Added automatic fallback from the selected source to available backup sources.
- Added persistent source health state and reset support.
- Added fallback notices so users can tell when fallback data is being shown.
- Added source diagnostics for recent failures and fallback events.
- Added source health summaries and recent fallback events to runtime diagnostics.

### 🔄 Changed
- Refreshed AniDestiny logo artwork and synced the README brand image, Android launcher icon, Windows icon, and macOS AppIcon.
- Redesigned the download task model and states; the downloads page now shows task type, status, progress, failure reason, and local path.
- Stabilized the direct-file download path while keeping HLS offline and BT downloads clearly marked as not implemented yet.
- Improved Home, Search, Detail, Schedule, History, and Player flows when the selected source is temporarily unavailable.
- Improved Source Settings with health status, failure count, and reset controls.
- Improved playback diagnostics and URL sanitization to avoid exposing query tokens, header values, or other sensitive details in feedback summaries.
- Kept empty search results as a normal empty state instead of treating them as source failures that trigger fallback.

### 🐛 Fixed
- Fixed empty detail episodes and empty play-source lists not being treated as source failures, allowing automatic fallback to run.

### 🔧 CI/CD
- Added a Windows Build CI job that verifies `flutter build windows --release` on `windows-latest` and uploads a temporary Windows x64 artifact.
- Added a release preflight script and pre-release quality gate checklist.
- Changed Android release asset naming to use the universal APK suffix and documented the arm64 naming rule.
- Changed macOS and Windows release asset names to include platform and architecture suffixes.
- Fixed release rebuild handling, Linux release dependencies, and release publishing checkout context.
- Changed release preparation PRs and GitHub Release notes to publish only user-facing Added, Changed, and Fixed sections.
- Added a `changelog correction` PR label path for controlled fixes to released changelog sections while still requiring `[Unreleased]` updates.
- Added Android debug build and clean scripts, plus post-release validation configuration.

### 📚 Documentation
- Added Windows CI build output path, temporary artifact, and EXE / taskbar icon verification notes.
- Added an issue reporting guide for playback, source, danmaku, and download diagnostics.
- Added Android, Windows, and macOS release smoke checklists.
- Added release asset naming, Windows build verification, and current capability boundary notes.
- Added download path, Android permission policy, and not-yet-implemented scope notes.
- Updated README visuals, platform notes, screenshot placeholders, and brand asset references.
- Added platform icon paths and release asset naming notes to platform build documentation.
- Updated the Chinese and English READMEs and platform build notes.
- Moved post-release changelog content back under `[Unreleased]` so the released `1.0.1` record stays stable.

### Known Limitations
- Fallback data may not always map perfectly between different sources.
- Source availability still depends on upstream websites.
- Dandanplay credentials are optional; fallback is used when unavailable.
- Download support is still basic.
## [1.0.1] - 2026-05-28

### 🔧 CI/CD
- Added Flutter quality checks, bilingual changelog gate, manual release preparation PR, and multi-platform release workflows.
- Changed releases to use a reviewed release PR first, then read the Chinese changelog, create the tag, build artifacts, and publish the release after merge.

### 📚 Documentation
- Changed the main README to Chinese and added `README_en.md`.
- Added the Chinese primary changelog `CHANGELOG.md` and English secondary changelog `CHANGELOG_en.md`.

## [1.0.0] - 2026-05-28

### ✨ Added
- Added the AniDestiny Flutter app foundation.
- Added Sakura live source parsing for home, search, anime detail, episode list, and play sources.
- Added player controls, danmaku overlay, Dandanplay integration structure, and mock fallback.
- Added local persistence for watch history, favorites, and download tasks.
- Added Chinese, English, and Japanese UI languages.

### 🔧 CI/CD
- Verified the initial version locally with `flutter analyze`, `flutter test`, Android debug/release builds, and macOS release build.
