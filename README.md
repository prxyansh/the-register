# The Register

> A highly accurate, privacy-first, offline attendance tracking application.

**The Register** is a Flutter-based attendance tracking system engineered for precision and automation. It allows students to reliably track their classes locally on their devices, ensuring maximum privacy without relying on cloud services or external APIs.

---

## // Core Features

- **High-Accuracy Smart Automation:** Background tracking fuses GPS coordinates and specific Campus WiFi SSIDs to accurately detect when you are physically sitting in a lecture hall.
- **100% Offline & Private:** Built on top of local Drift SQLite. Your location data and schedule never leave your device. Zero cloud analytics. Zero API keys.
- **OpenStreetMap Integration:** Precisely pin your venues on a fully free and open map interface. Navigate and set accurate radii for geofencing without Google Maps API keys.
- **Timetable Sharing & Export:** Export and share your entire semester's timetable with classmates using base64 share codes or direct JSON file transfers.
- **Automated Background Checks:** Relies on robust Android background services to periodically check location and network state, ensuring you never miss logging a class.

## // Getting Started

To build and run this project, you will need to have [Flutter](https://flutter.dev/docs/get-started/install) installed on your machine.

1. **Clone the repository:**
   ```bash
   git clone https://github.com/prxyansh/the-register.git
   cd the-register
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

4. **Build the optimized Android Release APK:**
   ```bash
   flutter build apk --release --split-per-abi
   ```

## // Tech Stack

- **Framework:** Flutter (Dart)
- **State Management:** Riverpod
- **Database:** Drift (SQLite)
- **Mapping:** `flutter_map` (OpenStreetMap tiles) & `latlong2`
- **Location & Sensors:** `geolocator`, `network_info_plus`, `sensors_plus`

## // License

This project is licensed under the MIT License - see the LICENSE file for details.

---

*Crafted with 🚬 and precision by prx.*
