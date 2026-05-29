# Download Notes

AniDestiny download support is designed as a local-first client capability.
The current implementation focuses on task modeling, type detection, direct
file downloads, and clear unsupported states.

## Download Types

- Direct file: supported for regular media file URLs such as `.mp4`, `.mkv`,
  `.webm`, and `.mov`.
- HLS / m3u8: detected and parsed for manifest metadata. Full offline segment
  download and merge is not implemented yet.
- BT / magnet: detected as a placeholder type. BT downloading is not
  implemented yet.
- Unknown: stored as an unsupported task with a user-facing reason.

## Task State

Download tasks track:

- type,
- status,
- progress,
- downloaded and total bytes,
- request headers,
- local path,
- failure reason and message.

Pause support is basic. A paused task may restart from the beginning when
continued because full resume support is not implemented yet.

## Storage Path

Direct file downloads use the app-specific documents directory by default:

```txt
<app documents>/downloads/
```

This keeps Android storage access scoped to the app and avoids broad external
storage permissions for the default path.

## Android Permissions

Android builds should prefer app-specific storage for downloads. Android 13+
media permissions are only needed when the app reads shared media collections or
lets users export files outside the app-specific directory.

The current download flow does not require broad shared-storage permissions for
the default app-specific path.

## Windows And macOS Paths

Windows and macOS also use the Flutter app documents directory as the default
download root. Future releases may add a user-selected destination, but the
default path should remain app-owned and predictable.

## Not Implemented Yet

- Full HLS segment download and merge.
- BT engine integration.
- Background download service.
- System notification progress.
- Full resume and multi-threaded downloads.
- Local offline player library management.
