import SwiftUI
import CoreHaptics

// MARK: - Settings Model
class MouseSettings: ObservableObject {
    @Published var sensitivity: Double {
        didSet { UserDefaults.standard.set(sensitivity, forKey: "sensitivity") }
    }
    @Published var acceleration: Double {
        didSet { UserDefaults.standard.set(acceleration, forKey: "acceleration") }
    }
    @Published var deadzone: Double {
        didSet { UserDefaults.standard.set(deadzone, forKey: "deadzone") }
    }
    @Published var friction: Double {
        didSet { UserDefaults.standard.set(friction, forKey: "friction") }
    }
    @Published var invertX: Bool {
        didSet { UserDefaults.standard.set(invertX, forKey: "invertX") }
    }
    @Published var invertY: Bool {
        didSet { UserDefaults.standard.set(invertY, forKey: "invertY") }
    }

    init() {
        sensitivity  = UserDefaults.standard.object(forKey: "sensitivity")  as? Double ?? 25.0
        acceleration = UserDefaults.standard.object(forKey: "acceleration") as? Double ?? 1.2
        deadzone     = UserDefaults.standard.object(forKey: "deadzone")     as? Double ?? 0.015
        friction     = UserDefaults.standard.object(forKey: "friction")     as? Double ?? 0.75
        invertX      = UserDefaults.standard.bool(forKey: "invertX")
        invertY      = UserDefaults.standard.bool(forKey: "invertY")
    }
}

// MARK: - App Root
struct ContentView: View {
    @StateObject private var ws       = WebSocketManager()
    @StateObject private var motion   = MotionManager()
    @StateObject private var settings = MouseSettings()

    @State private var screen: Screen = .setup
    @State private var showSettings   = false

    enum Screen { case setup, mouse }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch screen {
            case .setup:
                SetupView(ws: ws) {
                    applySettings()
                    motion.start()
                    withAnimation { screen = .mouse }
                }
            case .mouse:
                MouseView(ws: ws, motion: motion, settings: settings, showSettings: $showSettings)
            }

            if showSettings {
                SettingsView(settings: settings, showSettings: $showSettings) {
                    applySettings()
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    func applySettings() {
        motion.sensitivity  = settings.sensitivity
        motion.acceleration = settings.acceleration
        motion.deadzone     = settings.deadzone
        motion.invertX      = settings.invertX
        motion.invertY      = settings.invertY
    }
}

// MARK: - Setup Screen
struct SetupView: View {
    @ObservedObject var ws: WebSocketManager
    var onConnect: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 6) {
                Text("iMouse")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text("Desk Slide Mouse")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(white: 0.4))
                    .tracking(3)
                    .textCase(.uppercase)
            }

            // Mouse shape preview
            RoundedRectangle(cornerRadius: 50)
                .fill(Color(white: 0.12))
                .overlay(RoundedRectangle(cornerRadius: 50).stroke(Color(white:0.2), lineWidth: 1))
                .frame(width: 90, height: 130)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                            .font(.system(size: 22))
                            .foregroundColor(accent)
                        Text("Slide on desk")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(Color(white: 0.35))
                            .tracking(1)
                    }
                )

            VStack(alignment: .leading, spacing: 8) {
                Text("Laptop IP Address")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(white: 0.4))
                    .tracking(2)

                TextField("192.168.1.xxx", text: $ws.serverIP)
                    .keyboardType(.numbersAndPunctuation)
                    .autocorrectionDisabled()
                    .padding(16)
                    .background(Color(white: 0.08))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(white:0.15), lineWidth: 1))
                    .foregroundColor(.white)
                    .font(.system(size: 17, design: .monospaced))
            }
            .padding(.horizontal, 32)

            Button {
                ws.connect()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { onConnect() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "wifi")
                    Text("Connect & Start")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(18)
                .background(accent)
                .foregroundColor(.black)
                .cornerRadius(14)
                .font(.system(size: 16, weight: .bold))
            }
            .padding(.horizontal, 32)

            Text("Same WiFi • Slide phone on desk to move cursor")
                .font(.system(size: 12))
                .foregroundColor(Color(white: 0.3))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }
}

// MARK: - Mouse View
struct MouseView: View {
    @ObservedObject var ws: WebSocketManager
    @ObservedObject var motion: MotionManager
    @ObservedObject var settings: MouseSettings
    @Binding var showSettings: Bool

    @State private var leftDown  = false
    @State private var rightDown = false

    var body: some View {
        VStack(spacing: 0) {

            // Top bar
            HStack {
                // Status
                HStack(spacing: 8) {
                    Circle()
                        .fill(ws.isConnected ? accent : Color.red)
                        .frame(width: 8, height: 8)
                        .shadow(color: ws.isConnected ? accent : .red, radius: 4)
                    Text(ws.isConnected ? "Connected" : "Disconnected")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(white: 0.4))
                        .tracking(1)
                }
                Spacer()
                // Settings button
                Button {
                    motion.resetVelocity()
                    showSettings = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18))
                        .foregroundColor(Color(white: 0.5))
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Spacer()

            // Mouse body
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                ZStack {
                    // Shell
                    RoundedRectangle(cornerRadius: w * 0.5)
                        .fill(LinearGradient(
                            colors: [Color(white: 0.16), Color(white: 0.09)],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .overlay(
                            RoundedRectangle(cornerRadius: w * 0.5)
                                .stroke(Color(white: 0.22), lineWidth: 1)
                        )

                    // Left button zone highlight
                    if leftDown {
                        LeftButtonShape(w: w, h: h)
                            .fill(Color.white.opacity(0.08))
                    }
                    // Right button zone highlight
                    if rightDown {
                        RightButtonShape(w: w, h: h)
                            .fill(Color.white.opacity(0.08))
                    }

                    // Divider line
                    Rectangle()
                        .fill(Color(white: 0.2))
                        .frame(width: 1, height: h * 0.42)
                        .offset(y: -h * 0.29)

                    // Button separator
                    Rectangle()
                        .fill(Color(white: 0.18))
                        .frame(height: 1)
                        .offset(y: -h * 0.07)

                    // Scroll wheel
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color(white: 0.12))
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color(white:0.25), lineWidth: 1))
                        .frame(width: w * 0.14, height: h * 0.13)
                        .offset(y: -h * 0.135)

                    // Labels
                    HStack(spacing: 0) {
                        Text("L").frame(maxWidth: .infinity)
                        Text("R").frame(maxWidth: .infinity)
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(white: 0.25))
                    .offset(y: -h * 0.28)

                    // Center icon — slide indicator
                    VStack(spacing: 6) {
                        Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                            .font(.system(size: 20))
                            .foregroundColor(accent.opacity(0.6))
                        Text("Slide to move")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(Color(white: 0.25))
                            .tracking(1)
                    }
                    .offset(y: h * 0.1)

                    // Click zones (invisible but tappable)
                    HStack(spacing: 0) {
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if !leftDown {
                                        leftDown = true
                                        ws.send(["type":"click","button":"left","state":"down"])
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    }
                                }
                                .onEnded { _ in
                                    leftDown = false
                                    ws.send(["type":"click","button":"left","state":"up"])
                                }
                            )
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if !rightDown {
                                        rightDown = true
                                        ws.send(["type":"click","button":"right","state":"down"])
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    }
                                }
                                .onEnded { _ in
                                    rightDown = false
                                    ws.send(["type":"click","button":"right","state":"up"])
                                }
                            )
                    }
                    .frame(height: h * 0.44)
                    .offset(y: -h * 0.28)
                }
            }
            .padding(.horizontal, 50)
            .frame(maxHeight: 360)

            Spacer()

            Text("Slide phone on desk  •  Tap halves to click")
                .font(.system(size: 11))
                .foregroundColor(Color(white: 0.22))
                .tracking(0.5)
                .padding(.bottom, 36)
        }
    }
}

// MARK: - Button Shapes
struct LeftButtonShape: Shape {
    let w, h: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY + h * 0.44))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY + h * 0.1), control: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + h * 0.44))
        p.closeSubpath()
        return p
    }
}
struct RightButtonShape: Shape {
    let w, h: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY + h * 0.44))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.1), control: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.44))
        p.closeSubpath()
        return p
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var settings: MouseSettings
    @Binding var showSettings: Bool
    var onApply: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    // Handle
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(white: 0.3))
                        .frame(width: 40, height: 5)
                        .padding(.top, 14)
                        .padding(.bottom, 20)

                    Text("Mouse Settings")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.bottom, 24)

                    ScrollView {
                        VStack(spacing: 6) {
                            SettingSlider(label: "Sensitivity",  value: $settings.sensitivity,  range: 5...80,   format: "%.0f")
                            SettingSlider(label: "Acceleration", value: $settings.acceleration, range: 0.8...2.0, format: "%.1f×")
                            SettingSlider(label: "Smoothing",    value: $settings.friction,     range: 0.3...0.95,format: "%.2f")
                            SettingSlider(label: "Deadzone",     value: $settings.deadzone,     range: 0.005...0.08, format: "%.3f")

                            Divider().background(Color(white:0.2)).padding(.vertical, 8)

                            SettingToggle(label: "Invert X (left/right)", value: $settings.invertX)
                            SettingToggle(label: "Invert Y (forward/back)", value: $settings.invertY)

                            Divider().background(Color(white:0.2)).padding(.vertical, 8)

                            // Presets
                            Text("Presets")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(white: 0.4))
                                .tracking(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)

                            HStack(spacing: 10) {
                                PresetButton(label: "Slow & Precise") {
                                    settings.sensitivity  = 12
                                    settings.acceleration = 1.0
                                    settings.friction     = 0.6
                                    settings.deadzone     = 0.025
                                }
                                PresetButton(label: "Normal") {
                                    settings.sensitivity  = 25
                                    settings.acceleration = 1.2
                                    settings.friction     = 0.75
                                    settings.deadzone     = 0.015
                                }
                                PresetButton(label: "Fast") {
                                    settings.sensitivity  = 55
                                    settings.acceleration = 1.5
                                    settings.friction     = 0.85
                                    settings.deadzone     = 0.01
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 4)
                        }
                    }
                    .frame(maxHeight: 420)

                    Button {
                        onApply()
                        dismiss()
                    } label: {
                        Text("Apply")
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(accent)
                            .foregroundColor(.black)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
                .background(Color(white: 0.08))
                .cornerRadius(24)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.35), value: showSettings)
    }

    func dismiss() {
        onApply()
        withAnimation { showSettings = false }
    }
}

struct SettingSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let format: String

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text(String(format: format, value))
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(accent)
            }
            Slider(value: $value, in: range)
                .tint(accent)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

struct SettingToggle: View {
    let label: String
    @Binding var value: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            Toggle("", isOn: $value)
                .tint(accent)
                .labelsHidden()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
    }
}

struct PresetButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(white: 0.15))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white:0.25), lineWidth: 1))
        }
    }
}

// MARK: - Accent color
let accent = Color(red: 0, green: 1, blue: 0.53)
