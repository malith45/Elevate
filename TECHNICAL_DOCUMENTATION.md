# Elevate Technical Documentation

This document provides a deep dive into the architectural design, data flow, and implementation patterns used in the Elevate iOS application.

---

## 1. Architectural Overview

Elevate follows a **Clean Architecture** approach with **MVVM (Model-View-ViewModel)** at its core. This ensures that the code is testable, maintainable, and decoupled from the UI framework.

### Layered Structure
1.  **View Layer (SwiftUI):** Handles UI rendering and user interactions. Views are stateless and observe ViewModels for data.
2.  **ViewModel Layer:** Manages state, handles user intent, and communicates with Services.
3.  **Service Layer:** Encapsulates external APIs (Firebase), local persistence (Core Data), and cross-cutting concerns (SyncManager).
4.  **Model Layer:** Defines the "Domain Entities" used throughout the app.

---

## 2. Core Modules

### 2.1 Synchronization Engine (`SyncManager.swift`)
The `SyncManager` is the most critical component, enabling offline productivity.
-   **Queueing:** Actions taken while offline are stored as `PendingAction` objects.
-   **Execution:** Upon reconnection, the manager iterates through the queue and executes Firebase operations.
-   **Conflict Resolution:** Uses timestamp comparison (`updatedAt`) to resolve data discrepancies between local and remote states.

### 2.2 Session Management (`AppSession.swift`)
The global `@StateObject` that manages the user's authentication state, role-based routing, and real-time listeners.
-   **Role Switching:** Dynamically switches between `ManagerTabRouter` and `TechnicianTabRouter` based on user role.
-   **Background Tracking:** Manages the lifecycle of background location updates for technicians.

### 2.3 Real-Time Database (`FirebaseService.swift`)
A centralized wrapper for Firestore, Auth, and Messaging.
-   **Snapshot Listeners:** Efficiently manages real-time subscriptions to prevent memory leaks.
-   **Batch Operations:** Uses Firestore batches for atomic updates (e.g., deleting an organization and all associated data).

### 2.4 Local Persistence (`LocalStorageService.swift` & `CoreDataStack.swift`)
-   **Core Data:** Used for high-volume entities like Jobs and Notifications.
-   **UserDefaults:** Used for lightweight session metadata and shared app-group data (Widget support).

---

## 3. Advanced Features Implementation

### 3.1 Geospatial Tracking
Technician locations are tracked using `CoreLocation`. To minimize battery drain, we use a hybrid approach:
-   **Distance Filter:** 50 meters.
-   **Time Filter:** 30 seconds.
-   Updates are throttled and only pushed if the technician is in "Working" status.

### 3.2 Biometric Security
We use the `LocalAuthentication` framework to gate sensitive actions. 
```swift
// Pattern used in ViewModels
func performSensitiveAction(completion: @escaping (Bool) -> Void) {
    let context = LAContext()
    context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Confirm action") { success, _ in
        DispatchQueue.main.async { completion(success) }
    }
}
```

### 3.3 Dynamic Analytics
The `StatisticsViewModel` computes KPIs locally using cached data, allowing for instant performance reports even while offline. It supports time-based filtering (7 days, 30 days, 1 year) and team-average comparisons.

---

## 4. UI/UX Design System

### Accessibility Settings
The app includes a global `AccessibilitySettings` singleton that propagates changes to custom components:
-   `AccessibleHeading` / `AccessibleBody`
-   `AccessibleButton`
-   `AccessibleCard`

### Navigation Router
Elevate uses a custom routing system to handle deep links from Notifications and Widgets, ensuring users land on the correct detail screen regardless of the app's current state.

---

## 5. Security & Privacy

-   **Data Isolation:** All database queries are strictly scoped by `organizationId`.
-   **Multi-tenancy:** Users can only access data belonging to their verified organization.
-   **Minimal Permissions:** The app only requests Location and Notification permissions when strictly necessary for the core workflow.

---

## 6. Maintenance & Troubleshooting

### Common Logs
-   `🔔 [NotificationSync]`: Tracks real-time alert delivery.
-   `🔄 [SyncManager]`: Tracks the state of the offline queue.
-   `📍 [LocationService]`: Tracks GPS updates and thresholds.

### Resetting State
To clear all local data and reset the session, call `AppSession.shared.signOut()`, which purges Core Data and UserDefaults.
