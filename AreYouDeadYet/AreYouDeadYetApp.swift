import SwiftUI
import UserNotifications
import BackgroundTasks

@main
struct AreYouDeadYetApp: App {
    @StateObject private var checkInManager = CheckInManager()
    @StateObject private var notificationService = NotificationService()
    @StateObject private var locationService = LocationService()

    init() {
        registerBackgroundTasks()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(checkInManager)
                .environmentObject(notificationService)
                .environmentObject(locationService)
                .onAppear {
                    notificationService.requestAuthorization()
                    scheduleBackgroundTasks()
                }
        }
    }

    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.after6ix.AreYouDeadYet.checkInReminder",
            using: nil
        ) { task in
            handleCheckInReminderTask(task: task as! BGAppRefreshTask)
        }

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.after6ix.AreYouDeadYet.emergencyCheck",
            using: nil
        ) { task in
            handleEmergencyCheckTask(task: task as! BGProcessingTask)
        }
    }

    private func scheduleBackgroundTasks() {
        let reminderRequest = BGAppRefreshTaskRequest(identifier: "com.after6ix.AreYouDeadYet.checkInReminder")
        reminderRequest.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 60 * 60) // 24 hours

        let emergencyRequest = BGProcessingTaskRequest(identifier: "com.after6ix.AreYouDeadYet.emergencyCheck")
        emergencyRequest.earliestBeginDate = Date(timeIntervalSinceNow: 48 * 60 * 60) // 48 hours
        emergencyRequest.requiresNetworkConnectivity = true

        do {
            try BGTaskScheduler.shared.submit(reminderRequest)
            try BGTaskScheduler.shared.submit(emergencyRequest)
        } catch {
            print("Could not schedule background tasks: \(error)")
        }
    }

    private func handleCheckInReminderTask(task: BGAppRefreshTask) {
        scheduleBackgroundTasks()

        let lastCheckIn = checkInManager.lastCheckIn
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        if let lastCheckIn = lastCheckIn, lastCheckIn.date < oneDayAgo {
            notificationService.sendMissedCheckInReminder()
        }

        task.setTaskCompleted(success: true)
    }

    private func handleEmergencyCheckTask(task: BGProcessingTask) {
        scheduleBackgroundTasks()

        let lastCheckIn = checkInManager.lastCheckIn
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!

        if let lastCheckIn = lastCheckIn, lastCheckIn.date < twoDaysAgo {
            locationService.getCurrentLocation { location in
                EmergencyContactService.shared.notifyEmergencyContacts(with: location)
                task.setTaskCompleted(success: true)
            }
        } else {
            task.setTaskCompleted(success: true)
        }
    }
}
