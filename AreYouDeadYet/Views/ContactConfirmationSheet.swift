import SwiftUI
import Contacts

/// Sheet for confirming contact details and selecting notification channels
struct ContactConfirmationSheet: View {
    @Environment(\.dismiss) var dismiss

    let cnContact: CNContact
    var onSave: (EmergencyContact) -> Void

    // Selected phone/email (for contacts with multiple)
    @State private var selectedPhone: String?
    @State private var selectedEmail: String?

    // Manual email entry (when contact has no email)
    @State private var showEmailInput = false
    @State private var manualEmail = ""
    @State private var emailValidationError: String?

    // Notification channels
    @State private var enabledChannels: Set<NotificationChannel> = [.email]

    // Selection sheets
    @State private var showPhoneSelection = false
    @State private var showEmailSelection = false

    private var contactName: String {
        [cnContact.givenName, cnContact.familyName]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private var phoneNumbers: [String] {
        cnContact.phoneNumbers.map { $0.value.stringValue }
    }

    private var emailAddresses: [String] {
        cnContact.emailAddresses.map { $0.value as String }
    }

    private var finalPhone: String? {
        selectedPhone ?? phoneNumbers.first
    }

    private var finalEmail: String? {
        if !manualEmail.isEmpty {
            return manualEmail
        }
        return selectedEmail ?? emailAddresses.first
    }

    private var canSave: Bool {
        // Must have at least phone or email
        finalPhone != nil || finalEmail != nil
    }

    private var isValidEmail: Bool {
        guard !manualEmail.isEmpty else { return true }
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return manualEmail.range(of: emailRegex, options: .regularExpression) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                contactInfoSection
                manualEmailSection
                notificationChannelsSection
            }
            .navigationTitle("Add Emergency Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add Contact") {
                        saveContact()
                    }
                    .disabled(!canSave || !isValidEmail)
                }
            }
            .sheet(isPresented: $showPhoneSelection) {
                PhoneEmailSelectionSheet(
                    title: "Select Phone Number",
                    options: phoneNumbers,
                    onSelect: { selectedPhone = $0 }
                )
            }
            .sheet(isPresented: $showEmailSelection) {
                PhoneEmailSelectionSheet(
                    title: "Select Email",
                    options: emailAddresses,
                    onSelect: { selectedEmail = $0 }
                )
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            setupInitialState()
        }
    }

    // MARK: - Sections

    private var contactInfoSection: some View {
        Section {
            // Name
            HStack {
                Image(systemName: "person.fill")
                    .foregroundStyle(.secondary)
                Text(contactName)
                    .font(.headline)
            }

            // Phone
            if let phone = finalPhone {
                HStack {
                    Image(systemName: "phone.fill")
                        .foregroundStyle(.secondary)
                    Text(phone)
                    Spacer()
                    if phoneNumbers.count > 1 {
                        Button("Change") {
                            showPhoneSelection = true
                        }
                        .font(.caption)
                    }
                }
            } else {
                HStack {
                    Image(systemName: "phone.fill")
                        .foregroundStyle(.secondary)
                    Text("No phone number")
                        .foregroundStyle(.secondary)
                }
            }

            // Email
            if let email = finalEmail, !email.isEmpty {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(.secondary)
                    Text(email)
                    Spacer()
                    if emailAddresses.count > 1 && manualEmail.isEmpty {
                        Button("Change") {
                            showEmailSelection = true
                        }
                        .font(.caption)
                    }
                }
            } else if !showEmailInput {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(.secondary)
                    Text("No email")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Add Email") {
                        showEmailInput = true
                    }
                    .font(.caption)
                }
            }
        } header: {
            Text("Contact Info")
        }
    }

    @ViewBuilder
    private var manualEmailSection: some View {
        if showEmailInput {
            Section {
                TextField("Email address", text: $manualEmail)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                if !manualEmail.isEmpty && !isValidEmail {
                    Text("Please enter a valid email address")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } header: {
                Text("Add Email Address")
            } footer: {
                Text("Email enables free notifications. We recommend adding one.")
            }
        } else if emailAddresses.isEmpty && finalPhone != nil {
            Section {
                Label {
                    Text("Add an email to enable free notifications")
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
                .font(.subheadline)
            }
        }
    }

    private var notificationChannelsSection: some View {
        Section {
            ForEach(NotificationChannel.allCases) { channel in
                channelRow(for: channel)
            }
        } header: {
            Text("Notification Channels")
        } footer: {
            Text("Select how this contact will be notified in an emergency.")
        }
    }

    @ViewBuilder
    private func channelRow(for channel: NotificationChannel) -> some View {
        let canUse = canUseChannel(channel)
        let isEnabled = enabledChannels.contains(channel)

        HStack {
            Image(systemName: channel.systemImage)
                .foregroundStyle(canUse ? .primary : .secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(channel.displayName)
                    if channel.isPremium {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(channelSubtitle(for: channel))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if canUse && !channel.isPremium {
                Toggle("", isOn: Binding(
                    get: { isEnabled },
                    set: { newValue in
                        if newValue {
                            enabledChannels.insert(channel)
                        } else {
                            enabledChannels.remove(channel)
                        }
                    }
                ))
                .labelsHidden()
            } else if channel.isPremium {
                Text("Premium")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if channel == .telegram {
                Button("Setup") {
                    // TODO: Telegram setup flow
                }
                .font(.caption)
                .disabled(true)
            }
        }
        .opacity(canUse ? 1 : 0.6)
    }

    // MARK: - Helpers

    private func setupInitialState() {
        // If multiple phones, show selection
        if phoneNumbers.count > 1 {
            showPhoneSelection = true
        }

        // Default email channel on if email available
        if finalEmail != nil {
            enabledChannels = [.email]
        } else {
            enabledChannels = []
        }
    }

    private func canUseChannel(_ channel: NotificationChannel) -> Bool {
        switch channel {
        case .email:
            return finalEmail != nil && !finalEmail!.isEmpty
        case .telegram:
            return false // Requires setup
        case .sms, .whatsapp:
            return finalPhone != nil && !finalPhone!.isEmpty
        }
    }

    private func channelSubtitle(for channel: NotificationChannel) -> String {
        switch channel {
        case .email:
            if finalEmail == nil || finalEmail!.isEmpty {
                return "No email address"
            }
            return "Free"
        case .telegram:
            return "Free - Requires setup"
        case .sms:
            return "Premium only"
        case .whatsapp:
            return "Premium only"
        }
    }

    private func saveContact() {
        let contact = EmergencyContact(
            from: cnContact,
            phoneNumber: finalPhone,
            email: finalEmail
        )
        var mutableContact = contact
        mutableContact.enabledChannels = enabledChannels
        onSave(mutableContact)
        dismiss()
    }
}

// MARK: - Phone/Email Selection Sheet

struct PhoneEmailSelectionSheet: View {
    @Environment(\.dismiss) var dismiss

    let title: String
    let options: [String]
    var onSelect: (String) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(options, id: \.self) { option in
                    Button {
                        onSelect(option)
                        dismiss()
                    } label: {
                        Text(option)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
