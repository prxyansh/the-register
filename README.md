# The Register

> A highly accurate, privacy-first, brutalist, **fully automatic**, offline attendance tracking application.

![Release](https://img.shields.io/badge/Release-v1.0.0-black?style=for-the-badge)
![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?style=for-the-badge&logo=flutter)
![Platform](https://img.shields.io/badge/Platform-Android-green?style=for-the-badge&logo=android)
![License](https://img.shields.io/badge/License-MIT-white?style=for-the-badge)

---

## The Problem (Why another attendance tracker?)

There are hundreds of attendance tracking apps on the app stores. However, almost all of them suffer from three critical flaws:
1. **Manual Entry Fatigue:** You have to remember to open the app and click a button every single time you attend a class. If you forget, your data is completely ruined.
2. **Invasive Privacy Practices:** The few apps that *do* offer automated tracking upload your highly sensitive, minute-by-minute physical GPS location to remote cloud servers.
3. **Paywalls & Ads:** Core features like timetables and data export are locked behind subscriptions or flooded with advertisements.

## Why "The Register"?

**The Register** was engineered specifically to solve these problems for students. It is a true "set it and forget it" system built on a foundation of absolute privacy, wrapped in a heavy, high-contrast **brutalist aesthetic**.

By fusing your device's background GPS coordinates with specific Campus WiFi SSIDs, the app **automatically detects** when you are physically sitting in a lecture hall and logs your attendance silently in the background. 

Most importantly: **Your data never leaves your phone.** There are no cloud servers, no analytics trackers, and zero API keys. Everything is stored locally on your device via Drift SQLite. 

---

## Core Features (v1.1.0)

- **High-Accuracy Smart Automation:** Background tracking intelligently fuses GPS data and WiFi networks to ensure you never miss logging a class.
- **100% Offline & Private:** Zero cloud analytics. Zero API keys. Total ownership of your data.
- **Doze-Proof Battery Resilience:** Android's aggressive background-killing mechanics are bypassed natively. The app dynamically schedules checks and requests `IGNORE_BATTERY_OPTIMIZATIONS` so you never miss a tick.
- **Advanced Attendance Analytics & Reports:** Deep insights into your attendance percentages, visualizing safe-to-miss classes, and tracking performance over the semester.
- **Intelligent Calendar Integration:** Instantly parse and import your entire semester's class schedule using standard `.ics` file imports.
- **Holidays & Exception Handling:** Comprehensive support for holidays to intelligently pause background automation, ensuring you aren't marked absent during term breaks.
- **Encrypted Local Backups & Restore:** Keep your data safe with robust JSON-based offline backups, ensuring 100% data portability across devices.
- **Granular Notification System:** Dynamic, non-intrusive local notifications keeping you in the loop on class start times and background attendance checks.
- **Universal Manual Overrides:** If your phone dies, you can manually tap any class on the Today screen to retroactively mark yourself as Present, Absent, Sick, or Cancelled.
- **OpenStreetMap Integration:** Precisely pin your venues on a fully free and open map interface without relying on proprietary Google Maps APIs.
- **Heavy Haptics & Brutalist UX:** Thick borders, monospaced typography, stark empty states, and aggressive haptic feedback that makes every interaction feel premium and tactile.

---

## Getting Started

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
   flutter build apk --release
   ```

## Tech Stack

- **Framework:** Flutter (Dart)
- **State Management:** Riverpod
- **Database:** Drift (SQLite)
- **Mapping:** `flutter_map` (OpenStreetMap tiles) & `latlong2`
- **Background Execution:** `workmanager`, `permission_handler`
- **Location & Sensors:** `geolocator`, `network_info_plus`, `sensors_plus`

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

*Crafted with precision by prx.*
