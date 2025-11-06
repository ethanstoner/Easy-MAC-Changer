# Easy MAC Address Changer

A simple Windows batch script that automatically changes your network adapter's MAC address to bypass WiFi blockers (like Netgear Nighthawk parental controls) and restore your internet connection.

## 🎯 Purpose

This tool was designed to help bypass network restrictions by changing your MAC address. When a router blocks your device by MAC address, running this script will generate a new random MAC address and apply it, effectively restoring your WiFi connection.

## ✨ Features

- **Automatic Adapter Detection** - Automatically finds your active WiFi or Ethernet adapter
- **Random MAC Generation** - Generates a valid, locally-administered unicast MAC address
- **One-Click Operation** - Simple double-click to change MAC and restore connection
- **Auto-Elevation** - Automatically requests administrator privileges when needed
- **Visual Feedback** - Clear status messages throughout the process
- **Verification** - Confirms the MAC address change was successful

## 🚀 Usage

1. **Download** the `Easy-MAC-Changer.bat` file
2. **Right-click** and select "Run as administrator" (or just double-click - it will auto-elevate)
3. Wait for the script to:
   - Detect your network adapter
   - Generate a new MAC address
   - Apply the change
   - Restore your connection

That's it! Your WiFi should be restored after the adapter restarts.

## 📋 Requirements

- **Windows** (Windows 7 or later)
- **Administrator privileges** (script will request automatically)
- **Active network adapter** (WiFi or Ethernet)

## 🔧 How It Works

1. **Detection**: Scans for active network adapters (prefers WiFi)
2. **MAC Generation**: Creates a random, valid MAC address using PowerShell
3. **Registry Update**: Modifies the Windows registry to set the new MAC address
4. **Adapter Restart**: Disables and re-enables the adapter to apply changes
5. **Verification**: Confirms the new MAC address is active

## ⚠️ Important Notes

- **Administrator Required**: This script modifies Windows registry and network settings, requiring admin privileges
- **Temporary Disconnection**: Your network connection will be briefly interrupted while the adapter restarts
- **Router Compatibility**: Works with most routers that block by MAC address (including Netgear Nighthawk)
- **No Permanent Change**: The MAC address change persists until you manually change it again or reinstall the adapter driver

## 🛠️ Technical Details

- **MAC Format**: Generates locally-administered unicast MAC addresses (second bit of first octet set)
- **Registry Path**: `HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}`
- **Method**: Uses Windows `reg` command and `netsh` interface commands

## 📝 License

This project is provided as-is for educational and personal use.

## 🤝 Contributing

Feel free to submit issues or improvements!

---

**Disclaimer**: This tool is intended for legitimate network troubleshooting and bypassing restrictions on networks you have permission to access. Use responsibly and in accordance with your local laws and network policies.

