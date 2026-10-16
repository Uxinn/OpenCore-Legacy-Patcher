# Status: MacBookPro14,3 on Sequoia, dual-display problem

Last updated: 2026-10-16

## Goal
Run current macOS (Sequoia 15.8.1 through OCLP) on a 2017 15" MacBook Pro (MacBookPro14,3) that is used at a desk with an
**external monitor and keyboard every day**. The built-in screen and keyboard are rarely used.

## Current state
- Sequoia 15.8.1 (24H32), OCLP 2.5.1, root patched. Boots through OpenCore on the internal disk (built for MacBookPro14,3).
- `pmset gpuswitch 1` (AMD only) is set. External monitor (MSI MPG341CX OLED, 3440x1440, TB3/DP) works.
- Built-in screen: dark while the external monitor is connected, flickers with no monitor connected.
- MacPorts tools installed. After the OS upgrade, `sudo port migrate` is still TODO.

## Symptoms (details in bug-report.md)
| Setting | Built-in screen | External monitor |
|---|---|---|
| `gpuswitch 2` (auto) | OK | plugging in makes CoreDisplayXPCService crash |
| switching to `gpuswitch 1` while running | system freezes | - |
| `gpuswitch 1` after restart, no monitor | flickers | - |
| `gpuswitch 1` + monitor | dark (macOS says online) | works |
| `gpuswitch 1` + monitor, **lid closed** | - | first a reconfiguration storm (170 WindowServer 0.25 s timeouts), then a **display-sleep loop**: AGDP `PMDisplaySleep` on ports 0 and 1 at about 4.5/s; the pointer updates about once a second; the loop continues after opening the lid (built-in screen shows garbage). Fixed by unplugging and replugging the monitor. Refresh rate resets to 60 Hz and audio moves to the monitor (DP). |
| `gpuswitch 1` + monitor, **after a restart, lid closed** (2026-10-16; lid state checked afterwards) | - | external monitor flashes: same AGDP `PMDisplaySleep` loop on port 1 plus a ValidateModeTiming storm (3440x1440 at 320/583/659 MHz pixel clocks, i.e. 60/100/120 Hz). Same lid-closed trigger as above. |
| unplugging the monitor (after the above) | stays blank, not listed by macOS | - |

## Findings
- **2026-10-16, key finding: Mac A's AMD Polaris patch never took effect.** Its patch run (2026-10-15 17:03) started
  offline, never downloaded or merged the Kernel Debug Kit, and only rebuilt the Auxiliary Kernel Collection. Mac A runs
  Sequoia's own AMD kexts 7.0.0 (generic `ATY,AMD,RadeonFramebuffer`, "AMD Radeon Polaris", Metal 2), even though
  `OpenCore-Legacy-Patcher.plist` lists "AMD Polaris". Mac B, patched online (KDK 24H32 merged, Boot/System KC rebuilt),
  runs the 13.5.2 kexts 4.1.4 (`ATY,Longavi`, "Radeon Pro 555", Metal 3). Check with
  `kextstat | grep AMDFramebuffer` (4.1.4 = patched, 7.0.0 = not). The display bugs may come from this broken patch.
- OCLP patches for MacBookPro14,3 on Sonoma+ (see `opencore_legacy_patcher/sys_patch/patchsets/hardware/graphics/amd_polaris.py`):
  only AMDFramebuffer, AMD9500Controller, AMD10000Controller and AMDSupport are replaced with **13.5.2** versions.
  AMDRadeonX4000 and the Metal and other bundles stay Sequoia's own, so the AMD stack is mixed.
- Intel KBL graphics are not patched (Sequoia still supports them natively).
- AppleGraphicsControl, Ventura 7.1.18 vs Sequoia 8.1.10 (from the Kernel Debug Kits):
  - AppleMuxControl and AppleGPUWrangler are effectively unchanged (same functions and strings).
  - AppleGraphicsDevicePolicy changed its modeset and link validation (DSC override, HDMI link fit, timing assert; old
    "vendor modeset" warnings removed).
  - AGDCBacklightControl: the default ApplePanels blob is 2 bytes shorter.
  - Conclusion: downgrading the mux driver is unlikely to help. The suspect is the mixed AMD stack combined with the newer AGDP.
- MacRumors: no fix found. The Sequoia thread says T1 MacBook Pros (13,2/13,3/14,2/14,3) have iCloud, FaceTime and AirDrop problems.
  Others report the internal screen going black with an external display, even on Sonoma.
- GitHub issues on dortania/OCLP are limited to collaborators. Report through Discord instead: https://discord.gg/rqdPgH8xSN

## Next steps
1. [done 2026-10-16, boot test pending] Recovery USB (64 GB): EFI with OpenCore for 14,3 (copy of the internal OCLP 2.5.1 build), Sequoia 15.8.1 + Ventura 13.7.8 installers, NOTES partition (notes, OCLP pkg, logs, git bundle).
2. Test the **desk setup** on the current Sequoia, keeping `gpuswitch 1`:
   - lid closed (clamshell) with charger, external monitor and keyboard
   - sleep, then wake from the external keyboard
   - restart with everything connected
   - unplugging the monitor or dock
   - a full workday without freezes
   **Result 2026-10-16: lid closed FAILS (display-sleep loop, see the symptoms table).** Lid-open desk use works.
   If these pass, the problem is solved for daily use. The experiment below is then optional.
3. Time-boxed experiment (one evening) on branch `mbp14-3-display`: give MacBookPro14,3 a complete, matching AMD stack
   instead of only the 13.5.2 framebuffers. First check which AMD binaries PatcherSupportPkg already ships
   (Universal-Binaries.dmg), then change `amd_polaris.py`, run OCLP from source, root patch, and run the tests above.
4. Fallback: Ventura 13.7.8 from the USB stick (clean install).

## Second Mac for testing (Mac B)
The user has a second, identical MacBook Pro. Run experiments on it, and keep Mac A (the daily machine) stable.
1. On Mac B, run `bash NOTES/tools/mac-fingerprint.sh > mac-B.txt` and diff it against `NOTES/logs/mac-A-fingerprint.txt`.
   It must match on model, board-id, CPU, both GPU device and revision IDs, AMD ROM/VBIOS, gMux version, built-in display
   IDs, Wi-Fi/BT chips, and ideally firmware (System Firmware, SMC, T1). RAM, SSD size and macOS version can differ.
   **Result 2026-10-16: identical hardware**: same model, board-id, CPU, 16 GB, System Firmware 529.140.2.0.0,
   SMC 2.45f5, T1 14Y910, both GPU device/revision IDs, AMD ROM/VBIOS, gMux 4.0.29, built-in display IDs and PCI
   subsystem IDs. Only OS-dependent lines differ (Mac B on Ventura 13.7.8).
2. Bring Mac B to the same baseline as Mac A: Sequoia 15.8.1 plus OCLP 2.5.1, with OpenCore built **on Mac B for Mac B**.
   Never copy an EFI between Macs (see the iMac15,1 leftover incident in RECOVERY.md).
   2026-10-16: OpenCore installed to Mac B's internal disk from Ventura. Running Install macOS Sequoia.app from the stick
   first said "not compatible" (Ventura had started without OpenCore). Starting via ⌥ → internal EFI Boot → Macintosh HD
   (so Ventura runs through OpenCore) made the installer accept the Mac. Sequoia 15.8.1 installed.
   First root patch ran **offline** (no Wi-Fi without the patch): OCLP then applies only "Modern Wireless" and skips the
   rest ("Network connection missing ... removing other patches"; no KDK). AMD Polaris and T1 need a second run once online.
3. Reproduce the symptoms on Mac B first. If they don't reproduce, Mac A may have a hardware fault.
   **Result 2026-10-16 (Mac B, fully patched, gpuswitch 1, MSI on TB3):** built-in screen normal with no monitor;
   monitor plugged in = both screens on; **lid closed = no display-sleep loop, no WindowServer timeouts, WindowServer
   ~0% CPU**; **restart with lid closed + monitor** = MSI shows login screen, no loop; **unplug monitor + open lid** =
   built-in screen comes back as main display. All tests pass. So the symptoms do NOT reproduce on a correctly patched
   14,3; Mac A's incomplete patch is the likely cause. Next: re-run the root patch on Mac A **online** (KDK merge).

## Desk-use tips
- Wake: any key on a USB keyboard (direct or through the dock) wakes it. Bluetooth keyboards normally do too.
- Lid-closed use needs the charger connected.
- Power on without opening the lid: prefer sleep over shutdown. 2016+ MBPs also start when the charger is connected.
  Scheduled start-up: `sudo pmset repeat wakeorpoweron MTWRF 08:00:00`. Cancel with `sudo pmset repeat cancel`.
- OpenCore and the Apple logo may only show on the built-in screen. Wait about a minute and the external monitor comes on at login.

## Alternatives considered
- Windows 11 (Boot Camp, unsupported CPU/TPM): AMD only, so external monitors work. Windows 10 is out of support.
- Linux: AMD and external monitors work. The BCM43602 Wi-Fi is unusable (needs a USB Wi-Fi adapter), audio needs the
  davidjo/snd_hda_macbookpro driver, and resume only works with the Intel GPU. Not preferred, because the user wants macOS.
