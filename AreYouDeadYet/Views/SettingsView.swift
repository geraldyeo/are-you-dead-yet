import SwiftUI
import Contacts

struct SettingsView: View {
    @EnvironmentObject var checkInManager: CheckInManager
    @EnvironmentObject var locationService: LocationService

    @State private var showingContactPicker = false
    @State private var showingContactConfirmation = false
    @State private var selectedCNContact: CNContact?
    @State private var showingDuplicateAlert = false
    @State private var duplicateContactName = ""

    var body: some View {
        NavigationStack {
            List {
                emergencyContactsSection

                checkInHistorySection

                locationSection

                aboutSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingContactPicker) {
                ContactPicker { contact in
                    selectedCNContact = contact
                    showingContactPicker = false
                    showingContactConfirmation = true
                }
            }
            .sheet(isPresented: $showingContactConfirmation) {
                if let contact = selectedCNContact {
                    ContactConfirmationSheet(cnContact: contact) { emergencyContact in
                        let result = checkInManager.addEmergencyContact(emergencyContact)
                        handleAddContactResult(result)
                    }
                }
            }
            .alert("Duplicate Contact", isPresented: $showingDuplicateAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This contact is already added as \"\(duplicateContactName)\".")
            }
        }
    }

    private func handleAddContactResult(_ result: CheckInManager.AddContactResult) {
        switch result {
        case .success:
            break
        case .limitReached:
            break // Button should be disabled, but handle gracefully
        case .duplicate(let existingName):
            duplicateContactName = existingName
            showingDuplicateAlert = true
        }
    }

    private var emergencyContactsSection: some View {
        Section {
            ForEach(checkInManager.emergencyContacts) { contact in
                ContactRowView(contact: contact)
            }
            .onDelete(perform: deleteContact)

            // Add contact button
            if checkInManager.canAddContact {
                Button {
                    showingContactPicker = true
                } label: {
                    Label("Add from Contacts", systemImage: "person.crop.circle.badge.plus")
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Add from Contacts", systemImage: "person.crop.circle.badge.plus")
                        .foregroundStyle(.secondary)
                    Text("Maximum \(CheckInManager.maxContacts) contacts. Remove one to add another.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Emergency Contacts (\(checkInManager.emergencyContacts.count)/\(CheckInManager.maxContacts))")
        } footer: {
            Text("These contacts will be notified with your location if you miss check-in for 2 consecutive days.")
        }
    }

    private var checkInHistorySection: some View {
        Section {
            if checkInManager.checkInHistory.isEmpty {
                Text("No check-ins yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(checkInManager.checkInHistory.prefix(10)) { checkIn in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(checkIn.date, format: .dateTime.month().day().hour().minute())
                    }
                }
            }
        } header: {
            Text("Recent Check-ins")
        }
    }

    private var locationSection: some View {
        Section {
            HStack {
                Text("Location Access")
                Spacer()
                Text(locationService.authorizationStatus)
                    .foregroundStyle(.secondary)
            }

            if !locationService.isAuthorized {
                Button("Enable Location Access") {
                    locationService.requestAuthorization()
                }
            }
        } header: {
            Text("Location")
        } footer: {
            Text("Location is only accessed when notifying emergency contacts.")
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Check-in Reminder")
                Spacer()
                Text("After 1 day")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Emergency Alert")
                Spacer()
                Text("After 2 days")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("About")
        }
    }

    private func deleteContact(at offsets: IndexSet) {
        checkInManager.removeEmergencyContacts(at: offsets)
    }
}

// MARK: - Contact Row View

struct ContactRowView: View {
    let contact: EmergencyContact

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Name
            Text(contact.name)
                .font(.headline)

            // Contact info
            HStack(spacing: 12) {
                if let phone = contact.phoneNumber, !phone.isEmpty {
                    Label(phone, systemImage: "phone.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let email = contact.email, !email.isEmpty {
                Label(email, systemImage: "envelope.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Enabled channels
            if !contact.enabledChannels.isEmpty {
                HStack(spacing: 8) {
                    ForEach(Array(contact.enabledChannels).sorted(by: { $0.rawValue < $1.rawValue })) { channel in
                        HStack(spacing: 2) {
                            Image(systemName: channel.systemImage)
                            Text(channel.displayName)
                        }
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsView()
        .environmentObject(CheckInManager())
        .environmentObject(LocationService())
}
