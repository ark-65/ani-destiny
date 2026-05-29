# Reporting Issues

When reporting playback, source, danmaku, or download issues, include enough
context for maintainers to reproduce the problem.

## Recommended Details

- App version.
- Platform and OS version.
- Reproduction steps.
- Source name.
- Whether fallback data was shown.
- Whether danmaku was enabled.
- Download task type and status, if the issue is download-related.
- Sanitized diagnostics copied from Settings.

## Copy Diagnostics

In the app, open Settings and choose **Copy diagnostics**. The copied Markdown
summary includes app, platform, source health, fallback, playback, danmaku, and
download task information.

The summary is sanitized before it is copied. It hides URL query parameters,
credential values, cookie values, authorization values, request header values,
and local usernames in file paths.

## Do Not Include

- Account credentials.
- Cookies.
- Tokens.
- Full URLs with query parameters.
- Dandanplay app secrets.
- Full HTML pages or large logs.
