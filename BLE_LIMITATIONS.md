Eve Chat - Simple BLE Chat App

## Important Notes

### Device Names
The app already shows the Bluetooth device name from your phone settings. The name you see is the actual Bluetooth name set on each device.

To change your device's Bluetooth name:
- **Android**: Settings → Connected devices → Connection preferences → Bluetooth → Device name
- **iOS**: Settings → General → About → Name

### Chat Functionality - IMPORTANT

**BLE Limitations for Phone-to-Phone Chat:**

Standard BLE communication works in a **Central-Peripheral** model:
- **Central** = Scanner (finds devices)
- **Peripheral** = Advertiser (broadcasts services)

**The Problem:** Most phones can only be Central OR Peripheral, not both simultaneously. This means:
- Phone A can connect to Phone B
- But Phone B cannot send data back to Phone A using standard BLE

**For True Two-Way Chat Between Phones, You Need:**

1. **Option 1: Use a dedicated BLE peripheral device**
   - One phone connects to a BLE device (like Arduino, ESP32, etc.)
   - That device can handle bidirectional communication

2. **Option 2: Use BLE with GATT Server (Complex)**
   - Requires one phone to act as a BLE peripheral with GATT server
   - The other phone acts as central
   - This is platform-dependent and may not work on all devices

3. **Option 3: Use WiFi Direct or Nearby Connections API**
   - Better suited for phone-to-phone communication
   - Requires different implementation

### Current Implementation
The current code supports:
- ✅ Scanning for nearby BLE devices
- ✅ Connecting to BLE devices
- ✅ Sending messages to connected devices
- ✅ Receiving messages from devices that support BLE notify characteristic
- ❌ Full two-way chat between two phones (BLE hardware limitation)

### Testing the App
To test messaging:
1. You need a BLE peripheral device (not another phone)
2. Or use BLE simulator apps that can act as peripherals
3. Or modify one phone to run in peripheral mode (requires additional code)

### Alternative: Phone-to-Phone Chat
If you specifically need phone-to-phone chat, consider:
- **Nearby Connections API** (Google)
- **MultipeerConnectivity** (iOS)
- **WiFi Direct**
- **Local network sockets**

These technologies are designed for peer-to-peer communication between phones.
