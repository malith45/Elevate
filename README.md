# Elevate: Field Service Management System

Elevate is a native iOS application designed to bridge the gap between management and field technicians. It provides real-time job tracking, inventory management, and geospatial visualization for service-based organizations.

## 🚀 Key Features

- **Dual-Role Interface:** Specialized dashboards for Managers and Technicians.
- **Offline-First Resilience:** Robust synchronization engine ensuring data consistency without internet.
- **Real-time Map Tracking:** Geospatial visualization of technicians and job sites.
- **Inventory Management:** Centralized stock tracking linked to field jobs.
- **Secure Approvals:** Biometric-gated (FaceID/TouchID) sensitive operations.
- **Inclusive Design:** Full accessibility support (High Contrast, Dynamic Type).

## 🛠 Tech Stack

- **Frontend:** Swift, SwiftUI, MapKit, CalendarKit.
- **Backend:** Firebase (Firestore, Auth, Cloud Messaging).
- **Persistence:** Core Data, UserDefaults.
- **Reactive Logic:** Combine Framework.
- **Security:** LocalAuthentication (Biometrics).

## 📦 Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 17.0+
- A Firebase project with `GoogleService-Info.plist` configured.

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/your-repo/elevate.git
   ```
2. Open `Elevate.xcodeproj` in Xcode.
3. Ensure the `GoogleService-Info.plist` is placed in the `Elevate/` directory.
4. Run the project on a physical device or simulator.

## 🏗 Project Structure

```text
Elevate/
├── Core/           # App entry point, session management, and routing
├── Models/         # Data structures and entities
├── ViewModels/     # Business logic and state management
├── Views/          # SwiftUI views (Auth, Dashboard, Jobs, etc.)
├── Services/       # API, Firebase, and Sync logic
├── Components/     # Reusable UI components
├── CoreData/       # Local persistence stack
└── Utils/          # Helper classes and extensions
```

## 📄 Documentation

For detailed technical architecture and implementation details, please refer to:
- [TECHNICAL_DOCUMENTATION.md](TECHNICAL_DOCUMENTATION.md)
- [ACCESSIBILITY_GUIDE.md](Elevate/ACCESSIBILITY_GUIDE.md)

## 🤝 Contributing

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## ⚖️ License

Distributed under the MIT License. See `LICENSE` for more information.

---
*Built with ❤️ by the malith45.*
