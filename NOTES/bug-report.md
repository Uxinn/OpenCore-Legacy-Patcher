### Machine Model
Other/Non-Applicable — **MacBookPro14,3** (15-inch, 2017, Intel HD 630 + Radeon Pro 555 / Polaris `1002:67EF`)

### Application Version
Latest Release (2.5.1, PatcherSupportPkg 1.9.7)

### Application Variant
GUI (Graphical User Interface)

### Have you verified whether this issue has been opened before?
true. I searched existing issues and checked #1008. That issue notes that MacBookPro14,3 has no known graphics issues, and none of its tables covers this.

### Have you verified whether this issue is covered in the guide?
true

### Describe the issue
macOS **15.8.1 (24H32)**. I installed it over Ventura 13.7.8, then applied root patches: AMD Polaris (Ventura 13.5.2 `AMDFramebuffer`/`AMD9500Controller`/`AMD10000Controller`/`AMDSupport`), Modern Wireless and T1. SIP is set by OCLP, FileVault is off, and nothing else was changed.

Switching GPUs while the system is running fails, and so does the internal panel when the dGPU drives it:

1. **Automatic graphics switching (`gpuswitch 2`, the default):** connecting an external display over Thunderbolt 3, either directly or through a dock, makes the system unstable. `CoreDisplayXPCService` crashes with SIGABRT in `__assert_rtn`.
2. **Running `sudo pmset -a gpuswitch 1` while running on the iGPU:** the system **freezes** and needs a hard reboot. `CoreDisplayXPCService` crashes the same way.
3. **After rebooting with `gpuswitch 1` (dGPU only):** the system boots fine, but the **internal panel flickers regularly**. The flicker isn't there with `gpuswitch 2`.
4. **With `gpuswitch 1`, connecting an external display** (MSI MPG341CX OLED, 3440x1440, TB3/DP): the external display works and the flicker stops, but the **internal panel goes dark**. WindowServer runs about 70 display reconfigurations in roughly 2 seconds and sets the internal display offline. "Detect Displays" brings it back as `Online: Yes`, driven by the AMD GPU, with brightness reported at 430/1024 and `bklt` at 255, but the panel physically shows nothing. The gmux seems to stay switched to the iGPU.

All of this worked on Ventura 13.7.8 with the same hardware.

### Steps to reproduce
1. MacBookPro14,3, OCLP 2.5.1, Sequoia 15.8.1, root patched.
2. With the default `gpuswitch 2`, connect a TB3 display. CoreDisplayXPCService crashes.
3. Alternatively, run `sudo pmset -a gpuswitch 1`. The system freezes.
4. Reboot with `gpuswitch 1`. The internal panel flickers. Connect an external display, and the internal panel goes dark and doesn't come back.

### Relevant logs

<details><summary>CoreDisplayXPCService crash (identical on 3 occasions)</summary>

```
app_name: CoreDisplayXPCService, app_version 288, macOS 15.8.1 (24H32)
exception: EXC_CRASH (SIGABRT), Abort trap: 6
Thread (triggered):
  __pthread_kill
  pthread_kill
  abort
  __assert_rtn
  ??? (CoreDisplayXPCService)
  _xpc_connection_call_event_handler
  _xpc_connection_mach_event
  _dispatch_client_callout4
```
</details>

<details><summary>WindowServer / AGDP log when connecting the external display with gpuswitch 1</summary>

```
WindowServer [com.apple.CoreDisplay] [ERROR] - Setting offline display 0x41dc9d0b main in CGXVFBSelectOnlineState   (x10, displays ...d01–...d0b)
WindowServer [com.apple.CoreDisplay] [ERROR] - Setting main display 0x41dc9d06 offline
WindowServer [com.apple.CoreDisplay] [WARN]  - get_display_device_info: ... isBDW=YES isSKL=YES isCNL=NO isAcc=YES isMUX=YES ...
WindowServer [com.apple.CoreDisplay] [WARN]  - _CDS_GetDisplaySystemState: Cached display system state is not valid. Recreating system state.   (x71 within ~2 s)
WindowServer [com.apple.CoreDisplay] [ERROR] - Attempting to get capabilities from capabilities with no devices   (x186)
WindowServer [com.apple.SkyLight] Timed out 0.250 second wait for reply ... kCGSDisplayWillReconfigure / kCGSDisplayPrepareForReprobe / kCGSDisplayDidReconfigure2
WindowServer [com.apple.CoreDisplay] backtrace: displayConnectChange -> CoreDisplay::AddMainOfflineBreadcrumb
kernel (AppleGraphicsDevicePolicy) AGDP:: VendorEventHandler [GFX0:AMD]: Event:ValidateModeTiming ... FB:1 -> 3440 x 1440   (hundreds)
kernel (AppleIntelKBLGraphicsFramebuffer) [IGFB][DISPLAY] [AGDC] Get port status / Get link config   (x31, during the dGPU-only session)
```
</details>

I can provide full logs or test patches.
