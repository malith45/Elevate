import Foundation
import Combine
import CoreLocation
import FirebaseFirestore

@MainActor
final class AppSession: ObservableObject {
    @Published private(set) var currentUser: User?

    private let sessionStore = SessionStore.shared
    private let localStorage = LocalStorageService.shared
    private var locationSubscriber: AnyCancellable?
    private var lastSyncedLocation: CLLocationCoordinate2D?
    private var lastSyncTime: Date?
    private var jobsListener: ListenerRegistration?
    private let calendarSync = CalendarSyncService.shared

    init() {
        if let userId = sessionStore.getUserId(), let user = localStorage.fetchUser(id: userId) {
            currentUser = user
            setupLocationTracking()
            setupJobSync()
            if let token = NotificationService.shared.notificationToken() {
                FirebaseService.shared.saveFcmToken(userId: user.id, token: token)
            }
        }
    }

    func signIn(user: User) {
        sessionStore.saveUserId(user.id)
        currentUser = user
        setupLocationTracking()
        setupJobSync()
        if let token = NotificationService.shared.notificationToken() {
            FirebaseService.shared.saveFcmToken(userId: user.id, token: token)
        }
    }

    func updateCurrentUser(_ user: User) {
        localStorage.saveUser(user)
        currentUser = user
        setupJobSync()
    }

    @MainActor
    func signOut() {
        locationSubscriber?.cancel()
        jobsListener?.remove()
        jobsListener = nil
        sessionStore.clear()
        currentUser = nil
        ManagerTabRouter.shared.currentScreen = .dashboard
        ManagerTabRouter.shared.selectedTab = .dashboard
    }

    private func setupLocationTracking() {
        locationSubscriber?.cancel()
        guard let user = currentUser, user.role == "TECHNICIAN" else { return }

        locationSubscriber = LocationService.shared.$currentLocation
            .sink { [weak self] location in
                guard let self = self, let location = location else { return }
                self.handleLocationUpdate(location)
            }
    }

    private func setupJobSync() {
        jobsListener?.remove()
        guard let user = currentUser else { return }

        if user.role == "TECHNICIAN" {
            jobsListener = FirebaseService.shared.listenToJobs(organizationId: user.organizationId, assignedUserId: user.id) { [weak self] jobs in
                Task { @MainActor in
                    guard let self = self else { return }
                    self.localStorage.saveJobs(jobs)
                    self.calendarSync.syncJobsIfAuthorized(jobs)
                }
            }
        } else if user.role == "MANAGER" {
            // Managers listen to all jobs in organization to sync their own + others' events
            jobsListener = FirebaseService.shared.listenToOrganizationJobs(organizationId: user.organizationId) { [weak self] jobs in
                Task { @MainActor in
                    guard let self = self else { return }
                    self.localStorage.saveJobs(jobs)
                    self.calendarSync.syncJobsIfAuthorized(jobs)
                }
            }
        }
    }

    private func handleLocationUpdate(_ location: CLLocationCoordinate2D) {
        guard let user = currentUser else { return }

        let now = Date()
        if let lastTime = lastSyncTime, now.timeIntervalSince(lastTime) < 30 {
            // Wait at least 30 seconds between syncs
            return
        }

        if let lastLoc = lastSyncedLocation {
            let p1 = CLLocation(latitude: lastLoc.latitude, longitude: lastLoc.longitude)
            let p2 = CLLocation(latitude: location.latitude, longitude: location.longitude)
            if p2.distance(from: p1) < 50 {
                // Only sync if moved > 50 meters
                return
            }
        }

        lastSyncedLocation = location
        lastSyncTime = now
        FirebaseService.shared.updateUserLocation(userId: user.id, latitude: location.latitude, longitude: location.longitude)
    }
}
