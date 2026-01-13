import SwiftUI

struct CheckInView: View {
    @EnvironmentObject var checkInManager: CheckInManager
    @State private var isPressed = false
    @State private var showConfirmation = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()

                statusSection

                checkInButton

                Spacer()

                lastCheckInInfo
            }
            .padding()
            .navigationTitle("Are You Dead Yet?")
            .alert("You're Alive!", isPresented: $showConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Check-in recorded. See you tomorrow!")
            }
        }
    }

    private var statusSection: some View {
        VStack(spacing: 12) {
            Image(systemName: statusIcon)
                .font(.system(size: 60))
                .foregroundStyle(statusColor)

            Text(statusMessage)
                .font(.title2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
        }
    }

    private var checkInButton: some View {
        Button {
            performCheckIn()
        } label: {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.green.opacity(0.8), .green],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 250, height: 250)
                    .shadow(color: .green.opacity(0.5), radius: isPressed ? 5 : 20, x: 0, y: isPressed ? 2 : 10)

                VStack(spacing: 8) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 50))

                    Text("I'M ALIVE")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .foregroundStyle(.white)
            }
        }
        .buttonStyle(CheckInButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .disabled(checkInManager.hasCheckedInToday)
        .opacity(checkInManager.hasCheckedInToday ? 0.6 : 1.0)
    }

    private var lastCheckInInfo: some View {
        VStack(spacing: 8) {
            if let lastCheckIn = checkInManager.lastCheckIn {
                Text("Last check-in:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(lastCheckIn.date, style: .relative)
                    .font(.subheadline)
                    .fontWeight(.medium)
            } else {
                Text("No check-ins yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    private var statusIcon: String {
        if checkInManager.hasCheckedInToday {
            return "checkmark.circle.fill"
        } else if checkInManager.daysSinceLastCheckIn >= 2 {
            return "exclamationmark.triangle.fill"
        } else if checkInManager.daysSinceLastCheckIn >= 1 {
            return "clock.badge.exclamationmark.fill"
        } else {
            return "heart.circle"
        }
    }

    private var statusColor: Color {
        if checkInManager.hasCheckedInToday {
            return .green
        } else if checkInManager.daysSinceLastCheckIn >= 2 {
            return .red
        } else if checkInManager.daysSinceLastCheckIn >= 1 {
            return .orange
        } else {
            return .blue
        }
    }

    private var statusMessage: String {
        if checkInManager.hasCheckedInToday {
            return "You've checked in today!\nSee you tomorrow."
        } else if checkInManager.daysSinceLastCheckIn >= 2 {
            return "Emergency contacts have been notified.\nPlease check in now!"
        } else if checkInManager.daysSinceLastCheckIn >= 1 {
            return "You missed yesterday's check-in.\nTap the button below!"
        } else {
            return "Tap the button below\nto confirm you're alive"
        }
    }

    private func performCheckIn() {
        withAnimation {
            isPressed = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                isPressed = false
            }
            checkInManager.checkIn()
            showConfirmation = true
        }
    }
}

struct CheckInButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

#Preview {
    CheckInView()
        .environmentObject(CheckInManager())
}
