# The Register

> A minimalist, privacy-first attendance tracking app engineered with precision.

**The Register** is a Flutter-based attendance tracking application designed with a strict, brutalist "ink-on-paper" aesthetic. It rejects modern bubbly UI trends in favor of vintage ledgers, mechanical split-flap displays, and crisp typography. 

Crafted strictly for students who want a beautiful, automated way to track their classes without sacrificing their data to cloud servers.

---

## // Features

- **100% Offline & Private:** Built on top of local Drift SQLite. Your location data and schedule never leave your device. Zero cloud analytics. Zero API keys.
- **Smart Automation:** Background tracking fuses GPS coordinates and specific Campus WiFi SSIDs to accurately detect when you are physically sitting in a lecture hall.
- **OpenStreetMap Integration:** Accurately pin your venues on a fully free and open map interface, no Google Maps API keys required.
- **Timetable Sharing:** Export and share your entire semester's timetable with classmates using base64 share codes or JSON files.
- **"Ledger" Aesthetic:** Designed around the IBM Plex font family, utilizing hairline borders, high-contrast monochrome tones, and mechanical animations.

## // Aesthetic Philosophy

The app is built around the **"Register"** design language:
- **Colors:** Ink black, stark white, cream (`#F8F7F2`), and a single striking red accent (`#E53935`).
- **Typography:** IBM Plex Sans for modern legibility, IBM Plex Mono for data. 
- **Motion:** Micro-animations mimic physical mechanics (rubber stamps pressing down, split-flap numbers rotating).

## // Getting Started

To build and run this project, you will need to have [Flutter](https://flutter.dev/docs/get-started/install) installed on your machine.

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/the-register.git
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
