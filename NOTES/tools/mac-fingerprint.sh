#!/bin/bash
# Prints the hardware and firmware details that matter for OCLP patching, without serial numbers or UUIDs.
# Run on each Mac and compare:  bash mac-fingerprint.sh > mac-A.txt ; diff mac-A.txt mac-B.txt
set -u

section() { printf '\n## %s\n' "$1"; }

section "Model"
sysctl -n hw.model
sysctl -n machdep.cpu.brand_string
ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/"board-id"/{print "board-id: " $4}'
echo "memory: $(( $(sysctl -n hw.memsize) / 1073741824 )) GB"

section "Firmware"
system_profiler SPHardwareDataType 2>/dev/null |
  grep -E "System Firmware Version|OS Loader Version|SMC Version|Apple ROM Info|Boot ROM" | sed 's/^ *//'
system_profiler SPiBridgeDataType 2>/dev/null | grep -E "Model Name|Firmware Version" | sed 's/^ *//'

section "Graphics"
system_profiler SPDisplaysDataType 2>/dev/null |
  grep -E "Chipset Model|Device ID|Revision ID|ROM Revision|VBIOS Version|EFI Driver Version|VRAM|gMux Version|Metal Support" |
  sed 's/^ *//'

section "Built-in display"
ioreg -lw0 -r -c AppleBacklightDisplay 2>/dev/null | grep -o -E '"(DisplayProductID|DisplayVendorID)" = [0-9]+' | sort -u

section "PCI devices (vendor:device subsystem)"
ioreg -l -w0 -r -c IOPCIDevice 2>/dev/null | awk -F'= ' '
  /"IOName"/            {name=$2}
  /"vendor-id"/         {v=$2}
  /"device-id"/         {d=$2}
  /"subsystem-id"/      {s=$2; print name, "vendor", v, "device", d, "subsys", s}' | sort -u

section "Wi-Fi / Bluetooth"
system_profiler SPAirPortDataType 2>/dev/null | grep -E "Card Type|Firmware Version" | head -2 | sed 's/^ *//'
system_profiler SPBluetoothDataType 2>/dev/null | grep -E "Chipset|Firmware Version|Transport" | head -3 | sed 's/^ *//'

section "Storage"
system_profiler SPNVMeDataType SPSerialATADataType 2>/dev/null | grep -E "Model:|Capacity:|Revision:" | head -3 | sed 's/^ *//'

section "Software"
sw_vers | sed 's/^ *//'
for v in OCLP-Model OCLP-Version; do nvram "4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:$v" 2>/dev/null | sed 's/%00$//'; done
