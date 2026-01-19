# evechatv1

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# Eve Chat
[![Ask DeepWiki](https://devin.ai/assets/askdeepwiki.png)](https://deepwiki.com/EVE-v1/eve-chat)

Eve Chat is a cross-platform Flutter application designed for local, serverless, peer-to-peer communication. It allows users on the same local network to discover each other and engage in text chat, voice messaging, and real-time voice and video calls without needing an internet connection or a central server.

## Features

*   **Offline Communication**: Operates entirely offline using a combination of Bluetooth and Wi-Fi.
*   **Device Discovery**: Automatically scans for and advertises to nearby devices.
*   **Text Messaging**: Real-time, one-to-one text chat.
*   **Voice Messaging**: Record and send audio clips.
*   **Voice & Video Calls**: Initiate and receive high-quality, low-latency audio and video calls powered by WebRTC.
*   **Cross-Platform**: Built with Flutter for a consistent experience on both Android and iOS.

## How It Works

The application leverages Google's **Nearby Connections API** for the initial device discovery, connection management, and data transfer for text and signaling messages.

1.  **Discovery**: A user can make their device "Discoverable", which starts advertising its presence. Other users can "Find Devices" to scan for nearby advertisers.
2.  **Connection**: When a user selects a device from the discovered list, a connection request is sent. The connection is automatically accepted, establishing a stable peer-to-peer link.
3.  **Messaging**: Text and voice messages are serialized (with audio files encoded to Base64) and sent as byte payloads over the established Nearby Connection.
4.  **Calls (WebRTC)**: For voice and video calls, the application uses the Nearby Connection link for the initial WebRTC signaling process.
    *   The caller sends an **offer** to the receiver.
    *   The receiver responds with an **answer**.
    *   Both devices exchange **ICE candidates** to find the best path for direct communication.
    *   Once the handshake is complete, the audio/video media stream is exchanged directly between the peers using the `flutter_webrtc` package, ensuring low latency.

## Technology Stack

*   **Framework**: Flutter
*   **Connectivity & Discovery**: `nearby_connections`
*   **Real-time Calls**: `flutter_webrtc`
*   **Audio Handling**: `record` for recording, `audioplayers` for playback
*   **Permissions**: `permission_handler`

## Getting Started

### Prerequisites

*   Flutter SDK installed.
*   Two physical Android or iOS devices. The application relies on hardware features not available in emulators/simulators.

### Installation & Running

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/EVE-v1/eve-chat.git
    cd eve-chat
    ```

2.  **Install dependencies:**
    ```sh
    flutter pub get
    ```

3.  **Run the application on two devices:**
    ```sh
    flutter run
    ```
    You will need to run this command for each device, targeting their respective device IDs.

### Usage

1.  On both devices, enter a username.
2.  On one device, tap **Make Discoverable**.
3.  On the other device, tap **Find Devices**.
4.  The first device should appear in the list on the second device. Tap on it to connect.
5.  Once connected, you will be taken to the chat screen where you can send messages or initiate calls.

## Permissions

The app requires the following permissions to function correctly:

*   **Android**: `BLUETOOTH_SCAN`, `BLUETOOTH_ADVERTISE`, `BLUETOOTH_CONNECT`, `NEARBY_WIFI_DEVICES`, `ACCESS_FINE_LOCATION`, `RECORD_AUDIO`, `CAMERA`.
*   **iOS**: `NSBluetoothAlwaysUsageDescription`, `NSBluetoothPeripheralUsageDescription`. Microphone and Camera permissions are requested at runtime when a call is initiated.

## Project Structure

```
lib/
├── main.dart             # App entry point and theme setup
├── models/               # Data models
│   ├── device_model.dart
│   └── message_model.dart
├── screens/              # UI screens
│   ├── scan_screen.dart    # Device discovery and advertising
│   ├── chat_screen.dart    # Chat and call initiation UI
│   └── call_screen.dart    # Voice/video call UI
├── services/             # Business logic and service wrappers
│   ├── nearby_service.dart # Manages Nearby Connections API
│   └── webrtc_service.dart # Manages WebRTC lifecycle for calls
└── widgets/              # Reusable UI widgets
    └── message_bubble.dart
