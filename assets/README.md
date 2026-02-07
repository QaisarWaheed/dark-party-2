# Assets – Naming & Usage

## File naming

- **No spaces** in filenames. Use underscores: `Group_33.png`, not `Group 33.png`.
- **Lowercase** preferred for consistency (e.g. `app_logo.jpeg`).
- **Short, clear names** (e.g. `bg_home.png`, `icon_chat.png`).

## Why

- Spaces in paths can break builds and tooling.
- Underscores work everywhere (Flutter, pubspec, native, CI).
- Consistent names make search and refactors easier.

## Loading images in code

Use the shared image widget so all assets get high-quality rendering:

```dart
import 'package:shaheen_start_app/...'; // wherever AppImage lives

AppImage.asset('assets/images/example.png');
```

Avoid raw `Image.asset()` for UI images; use `AppImage.asset()` so `filterQuality: FilterQuality.high` is applied and images stay sharp.

## Adding new assets

1. Add the file under `assets/images/`, `assets/icons/`, or `assets/svg/` with an underscore-style name.
2. Register the path in `pubspec.yaml` under `flutter: assets:` (folder or specific file).
3. Reference it in code with `AppImage.asset('assets/...')` (or the appropriate loader for SVGs).

## Folders

- **images/** – full images, backgrounds, logos.
- **icons/** – small icons, UI elements.
- **svg/** – vector graphics (SVG).
