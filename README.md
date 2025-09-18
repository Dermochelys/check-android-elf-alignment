# Check Android ELF Alignment Action

A GitHub Action that checks ELF alignment of shared libraries in Android .apk files and .so files. This action helps ensure that your Android applications have properly aligned native libraries that comply with the [Google Play Store requirements](https://developer.android.com/guide/practices/page-sizes).

```
Starting November 1st, 2025, all new apps and updates to existing apps submitted 
to Google Play and targeting Android 15+ devices must support 16 KB page sizes on 
64-bit devices.
```

## What this action does

This action:
- Focuses on 64-bit architectures (`arm64-v8a` and `x86_64`) as 32-bit `.so` files do not need to be aligned.
- Scans for any/all `.apk` and `.so` files present, checks the ELF alignment, and reports on the results.

## Usage

### Basic Usage

```yaml
      - name: Check Android ELF Alignment
        uses: Dermochelys/check-android-elf-alignment@v2
```

### Advanced Usage

```yaml
      - name: Check Android ELF Alignment
        uses: Dermochelys/check-android-elf-alignment@v2
        with:
          path: './build/outputs'
```

## Options

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `path` | Path to search for .apk and .so files | No | `./` |

## Understanding the output

- **ALIGNED**: no 64-bit libraries are present OR 64-bit libraries are present and are properly aligned
- **UNALIGNED**: 64-bit libraries are present that were not properly aligned

## Prerequisites

The action requires:
- `objdump` (usually available in standard Ubuntu runners)
- `file` command (usually available in standard Ubuntu runners)
- `unzip` (for .apk analysis)

For .apk zip-alignment checks, the action will also check for `zipalign` but will continue without it if not available.

## License

This project is licensed under the same license [Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0]) as the underlying `check_elf_alignment.sh` script, which is [part of AOSP](https://cs.android.com/android/platform/superproject/main/+/main:system/extras/tools/check_elf_alignment.sh).

