# PROJECT_NOTES.md

> Any edit or new feature added to this app MUST be implemented in all three platform folders (`lib/screens/mobile/`, `lib/screens/desktop/`, `lib/screens/web/`) — never add a feature to only one platform folder. Future AI coding sessions must read this file first and apply changes across all three.

## Architectural Guidelines
1. **Multi-platform Screen Implementations**:
   - `lib/screens/mobile/`: Optimized for compact touch interfaces (phones/small tablets).
   - `lib/screens/desktop/`: Multi-pane, keyboard/mouse friendly, responsive desktop windows (Linux, macOS, Windows).
   - `lib/screens/web/`: Web-responsive browser layouts, sandbox-aware web limitations.

2. **Resources Structure**:
   - `resources/android/`
   - `resources/ios/`
   - `resources/linux/`
   - `resources/windows/`
   - `resources/macos/`
   - `resources/web/`

3. **Sandboxing Boundary**:
   - Every media preview is executed under an OS-enforced or native isolation sandbox.
   - Real isolation mechanisms must be tested and verified per platform.
   - Every image switch in the multi-image gallery triggers a fresh sandbox execution; no unverified caching is permitted.
   - Every video transition/auto-advance in the playlist player triggers a fresh sandbox execution.

4. **Multi-Image Gallery & Video Playlist Screen Implementations**:
   - `lib/screens/mobile/`:
     - `mobile_image_gallery_screen.dart`: Touch swipe gestures primary, position badge ("3 / 12"), disabled at ends.
     - `mobile_video_player_screen.dart`: Compact bottom control bar, touch swipe, expandable playlist bottom sheet.
   - `lib/screens/desktop/`:
     - `desktop_image_gallery_screen.dart`: On-screen arrows, keyboard navigation (Left/Right arrows, Space, Esc), persistent side/bottom strips.
     - `desktop_video_player_screen.dart`: Visible seek bar, volume slider + mute, repeat modes (Off/One/All), auto-advance, persistent playlist side panel.
   - `lib/screens/web/`:
     - `web_image_gallery_screen.dart`: Desktop keyboard shortcuts + visible buttons + touch swipe support for touch laptops/tablets.
     - `web_video_player_screen.dart`: Full responsive layout, keyboard shortcuts, touch swipe, side playlist panel, volume slider, seek bar, repeat mode.

5. **Bug Fixes (Video Duration, UI Uncluttering & Baseline Divider Alignment)**:
   - **Bug 1 (Video Duration & State Tracking)**:
     - Implemented `MediaMetadataReader` (`lib/services/media_metadata_reader.dart`) with pure-Dart container header parsers for MP4/MOV `mvhd` boxes, WebM/MKV EBML duration tags, and AVI headers, plus `safe_extract_video_duration` inside the native Linux sandbox C helper (`linux/sandbox/aazil_sandbox.c`).
     - Integrated with `SandboxManager.inspectMedia` across all platforms.
     - In all 3 platform video player screens (`desktop_video_player_screen.dart`, `mobile_video_player_screen.dart`, `web_video_player_screen.dart`), the playback timer only starts after the real video duration is loaded.
     - Position is clamped strictly to `[Duration.zero, _duration]`, preventing elapsed time from ever exceeding the total video duration.
     - Seek bar and playlist auto-advance accurately track and reset against the real media duration.
   - **Bug 2 (UI Visual Clutter)**:
     - Replaced always-visible security badges across all platforms with a single compact "Sandbox Active" status badge.
     - Moved detailed security breakdown (network blocked, filesystem restricted, syscall filter, process tree isolation) into an on-demand collapsible expansion panel on desktop, a modal bottom sheet on mobile, and an alert dialog on web.
     - Primary action buttons ("Select Images", "Select Videos", "Create Project") made visually dominant and uncluttered across all platforms.
   - **Bug 3 (Misaligned Divider Lines)**:
     - Established a unified horizontal header baseline `kHeaderHeight = 72.0` with matching `Border(bottom: BorderSide(...))` across the sidebar, center workspace, and inspector pane.
     - Removed redundant uncoordinated `Divider(height: 1)` widgets, creating a single continuous horizontal divider seam that aligns across desktop, tablet, and resized windows.
