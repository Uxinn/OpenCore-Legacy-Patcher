# Fork notes: MacBookPro14,3 display experiment

This is a personal fork of OpenCore Legacy Patcher, used to fix dual-display and GPU-switching problems on a
2017 15" MacBook Pro (MacBookPro14,3) running macOS Sequoia.

Read before doing anything:
- `NOTES/STATUS.md`: current state, symptoms, findings, next steps. Keep it up to date after every session.
- `NOTES/RECOVERY.md`: how to recover the Mac (USB stick layout, revert patches, reinstall, back to Ventura).
- `NOTES/bug-report.md`: the bug report, written for the OCLP developers.

Working rules:
- Branch `mbp14-3-display` is based on tag `2.5.1` (the version installed on the Mac). `main` follows upstream.
- Never push to `upstream` (dortania). `origin` is the user's fork (Uxinn), and it is **public**.
  Don't commit serial numbers, UUIDs, hostnames, crash reports or other personal data.
- Never commit installers, Kernel Debug Kits, .pkg/.dmg files or other large binaries.
- Root patching and restarting change the user's only Mac. Make sure the recovery USB exists, and say what will
  happen before asking the user to apply patches or restart.
- The user always works at a desk with an external monitor and keyboard. Optimise for that setup.
