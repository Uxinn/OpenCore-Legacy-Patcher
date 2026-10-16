# MacBook Pro 15" 2017 (MacBookPro14,3): Recovery and OCLP notes

Prepared 2026-10-16. This stick is the recovery kit for this Mac.

## The Mac
- MacBookPro14,3: i7-7700HQ, 16 GB RAM, Intel HD 630 + AMD Radeon Pro 555 (Polaris), T1 chip, 500 GB SSD
- Last version Apple supports: **Ventura 13.7.8**
- Now runs **Sequoia 15.8.1 (24H32)** through **OpenCore Legacy Patcher (OCLP) 2.5.1**
- Root patches applied by OCLP: AMD Polaris (Ventura 13.5.2 AMDFramebuffer/AMD9500Controller/AMD10000Controller/AMDSupport), Modern Wireless, T1 Security Chip
- SIP is partly disabled (OCLP needs this), FileVault is OFF (keep it off)

## What's on this stick
| Partition | Contents |
|---|---|
| EFI | OpenCore built by OCLP 2.5.1 **for MacBookPro14,3** |
| Install macOS Sequoia | Sequoia 15.8.1 installer |
| Install macOS Ventura | Ventura 13.7.8 installer (runs on this Mac **without** OpenCore) |
| NOTES | This file, the OCLP installer, the bug report and logs |

## How to start up from the stick
1. Plug in the stick, then restart holding **⌥ Option**.
2. Pick what you need:
   - **EFI Boot** (the stick's) opens the OpenCore menu. From there you can start Macintosh HD, the Sequoia installer, or Recovery (press **Space** to show hidden entries).
   - **Install macOS Ventura** goes straight to the Ventura installer, without OpenCore.

## Recovery scenarios

### A. An experiment broke graphics or startup, but OpenCore still works
1. Start up through OpenCore (internal disk, or the stick's EFI Boot), then pick Macintosh HD.
   If the screen is black, try connecting an external monitor, or use the **Safe Mode** entry.
2. Open OpenCore-Patcher, choose **Post-Install Root Patch**, then **Revert Root Patches**, and restart.
3. Apply the official 2.5.1 root patches again.

### B. OpenCore on the internal disk is broken (no OpenCore menu)
1. Start up from the stick's **EFI Boot**, then pick Macintosh HD.
2. Open OCLP, choose **Build and Install OpenCore**, and install it to the **internal** disk (disk0).

### C. Reinstall Sequoia
1. Start up from the stick's EFI Boot, then pick **Install macOS Sequoia**.
2. Install it on Macintosh HD. Choosing **not** to erase the disk keeps your files.
3. After setup, install OCLP (`NOTES/OpenCore-Patcher-2.5.1.pkg`), run **Build and Install OpenCore** to the internal disk, apply **root patches**, and restart.

### D. Go back to Ventura (the safest fallback)
1. Restart holding ⌥ and pick **Install macOS Ventura**. OpenCore isn't needed.
2. In the installer, open Disk Utility and **erase** Macintosh HD (APFS), then install Ventura. A downgrade needs a clean install.
3. Optional: remove OpenCore from the internal disk's EFI partition. Ventura doesn't need it.
4. If anything looks odd afterwards, reset NVRAM: shut down, power on, and hold ⌥⌘PR for about 20 seconds.

## Known problem on Sequoia (the reason for the experiment)
- With automatic graphics switching (`gpuswitch 2`), plugging in an external display or dock makes CoreDisplayXPCService crash.
- Running `sudo pmset -a gpuswitch 1` while on the Intel graphics freezes the Mac.
- After restarting with `gpuswitch 1` (AMD only), the built-in screen flickers.
- With `gpuswitch 1` and an external display connected, the external display works but the built-in screen goes dark, even though macOS says it's online.
- Workaround: use one screen at a time. Use `gpuswitch 2` and restart with no monitor connected for the built-in screen, or `gpuswitch 1` for the external monitor.
- Details: `oclp-issue.md`. GitHub issues are closed to the public, so report on the OCLP Discord: https://discord.gg/rqdPgH8xSN

## Findings so far
- `AppleGraphicsControl` (graphics switching): comparing Ventura 13.5.2 (7.1.18) with Sequoia 15.8.1 (8.1.10), **AppleMuxControl and AppleGPUWrangler are effectively unchanged**. `AppleGraphicsDevicePolicy` changed how it sets display modes. So swapping the switch driver for Ventura's is unlikely to help.
- Likely cause: OCLP gives this model a **mixed AMD driver set**, Ventura 13.5.2 display drivers (AMDFramebuffer) with Sequoia's acceleration driver (AMDRadeonX4000).
- Experiment idea: give MacBookPro14,3 a complete, matching AMD driver set. OCLP already ships the Monterey 12.5 set it uses for non-AVX2 Polaris Macs; see `amd_polaris.py` in OCLP.

## Other setup on this Mac (for rebuilding)
- MacPorts, plus: git gh jq yq ripgrep fd wget tree coreutils gsed gawk shellcheck fzf bat htop python312 py312-pip nodejs22 npm10
  - After a reinstall: install the MacPorts package for the macOS version, run `sudo port install <list above>`, then
    `sudo port select --set python3 python312` and `sudo port select --set pip3 pip312`
  - After a macOS upgrade: `sudo port migrate`
- GitHub CLI account: Uxinn (`gh auth login`)

## Lesson learned: never reuse an OpenCore EFI between Macs
On 2026-10-15, OCLP showed "Unsupported Configuration Detected: booting OpenCore built for iMac15,1". NVRAM still held
`OCLP-Model=iMac15,1` / `OCLP-Version=2.4.1` from an OpenCore built on another Mac. The fix: reset NVRAM (hold ⌥⌘PR for
about 20 seconds), then boot through the OpenCore built on this Mac.
Each Mac needs OpenCore built by OCLP **on that Mac**.

## Rule: macOS updates (2026-10-16)
- Do **not** upgrade to Tahoe (26.x). OCLP 2.5.1 has no Tahoe support; upstream Tahoe support is still 3.0.0-rc.
- Turn off automatic install of macOS updates (System Settings → General → Software Update → ⓘ). Any macOS update,
  even 15.8.x, removes the root patches, and Wi-Fi needs the patch, so OCLP's auto-patch would run **offline** and
  install only the Wi-Fi patch (the same incomplete state that caused the display bugs).
- Update by hand with the **USB Ethernet cable** connected, then run
  `sudo /Applications/OpenCore-Patcher.app/Contents/MacOS/OpenCore-Patcher --patch_sys_vol` and check the log for
  "Merging KDK with Root Volume" and "Rebuilding Boot and System Kernel Collections" before restarting.
- Verify after restart: `kextstat | grep AMDFramebuffer` must show 4.1.4 (7.0.0 = AMD patch not active).
