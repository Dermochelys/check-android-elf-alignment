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
- Fails if only 32-bit libraries are present.  This enforces a previous Play Store requirement, that if 32-bit native libraries are present, there must also be 64-bit versions.  See [Improving app security and performance on Google Play for years to come](https://android-developers.googleblog.com/2017/12/improving-app-security-and-performance.html).

## Usage

### Basic Usage

```yaml
      - name: Check Android ELF Alignment
        uses: dermochelys/check-android-elf-alignment@v1
```

### Advanced Usage

```yaml
      - name: Check Android ELF Alignment
        uses: dermochelys/check-android-elf-alignment@v1
        with:
          path: './build/outputs'
          fail-on-unaligned: 'true'
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `path` | Path to search for .apk and .so files | No | `./` |
| `fail-on-unaligned` | Fail the action if unaligned libraries are found | No | `true` |

## Outputs

| Output | Description |
|--------|-------------|
| `apk-results` | Results of .apk alignment checks |
| `so-results` | Results of .so file alignment checks |

## Example with outputs

```yaml
- name: Check Android ELF Alignment
  id: elf-check
  uses: dermochelys/check-android-elf-alignment@v1
  with:
    path: './app/build/outputs'

- name: Display results
  run: |
    echo ".apk Results:"
    echo "${{ steps.elf-check.outputs.apk-results }}"
    echo ".so Results:"
    echo "${{ steps.elf-check.outputs.so-results }}"
```

## Understanding the output

- **ALIGNED**: 64-bit libraries are present and properly aligned
- **UNALIGNED**: Libraries are not properly aligned and will not pass the Google Play requirements starting November 1, 2025 for apps targeting Android 15+.

## Prerequisites

The action requires:
- `objdump` (usually available in standard Ubuntu runners)
- `file` command (usually available in standard Ubuntu runners)
- `unzip` (for .apk analysis)

For .apk zip-alignment checks, the action will also check for `zipalign` but will continue without it if not available.

## License

This project is licensed under the same license [Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0]) as the underlying `check_elf_alignment.sh` script, which is [part of AOSP](https://cs.android.com/android/platform/superproject/main/+/main:system/extras/tools/check_elf_alignment.sh).

