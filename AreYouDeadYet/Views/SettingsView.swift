import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var checkInManager: CheckInManager
    @EnvironmentObject var locationService: LocationService
    @State private var showingAddContact = false
    @State private var newContactName = ""
    @State private var newContactPhone = ""
    @State private var newContactEmail = ""

    var body: some View {
        NavigationStack {
            List {
                emergencyContactsSection

                checkInHistorySection

                locationSection

                aboutSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAddContact) {
                addContactSheet
            }
        }
    }

    private var emergencyContactsSection: some View {
        Section {
            ForEach(checkInManager.emergencyContacts) { contact in
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.name)
                        .font(.headline)
                    Text(contact.phoneNumber)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let email = contact.email, !email.isEmpty {
                        Text(email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .onDelete(perform: deleteContact)

            Button {
                showingAddContact = true
            } label: {
                Label("Add Emergency Contact", systemImage: "plus.circle.fill")
            }
        } header: {
            Text("Emergency Contacts")
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

    private var addContactSheet: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $newContactName)
                TextField("Phone Number", text: $newContactPhone)
                    .keyboardType(.phonePad)
                TextField("Email (optional)", text: $newContactEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
            }
            .navigationTitle("Add Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        resetContactForm()
                        showingAddContact = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveContact()
                    }
                    .disabled(newContactName.isEmpty || newContactPhone.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func deleteContact(at offsets: IndexSet) {
        checkInManager.removeEmergencyContacts(at: offsets)
    }

    private func saveContact() {
        let contact = EmergencyContact(
            name: newContactName,
            phoneNumber: newContactPhone,
            email: newContactEmail.isEmpty ? nil : newContactEmail
        )
        checkInManager.addEmergencyContact(contact)
        resetContactForm()
        showingAddContact = false
    }

    private func resetContactForm() {
        newContactName = ""
        newContactPhone = ""
        newContactEmail = ""
    }
}

#Preview {
    SettingsView()
        .environmentObject(CheckInManager())
        .environmentObject(LocationService())
}
