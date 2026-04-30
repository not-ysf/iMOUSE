import CoreMotion
import Combine

class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()

    // Settings
    var sensitivity: Double = 25.0
    var acceleration: Double = 1.2
    var deadzone: Double = 0.015
    var invertX: Bool = false
    var invertY: Bool = false

    var onMove: ((Double, Double) -> Void)?

    // Velocity for smoothing
    private var velX: Double = 0
    private var velY: Double = 0
    private let friction: Double = 0.75

    func start() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0

        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion, error == nil else { return }

            // Use userAcceleration — this is movement WITHOUT gravity
            // x = left/right slide, y = forward/back slide on desk
            var ax = motion.userAcceleration.x
            var ay = -motion.userAcceleration.y  // flip so forward = up on screen

            // Deadzone — ignore tiny vibrations
            if abs(ax) < self.deadzone { ax = 0 }
            if abs(ay) < self.deadzone { ay = 0 }

            // Invert axes if needed
            if self.invertX { ax = -ax }
            if self.invertY { ay = -ay }

            // Apply acceleration curve
            let accX = ax < 0 ? -pow(abs(ax), self.acceleration) : pow(abs(ax), self.acceleration)
            let accY = ay < 0 ? -pow(abs(ay), self.acceleration) : pow(abs(ay), self.acceleration)

            // Add to velocity (momentum feel)
            self.velX = (self.velX + accX * self.sensitivity) * self.friction
            self.velY = (self.velY + accY * self.sensitivity) * self.friction

            let dx = self.velX
            let dy = self.velY

            if abs(dx) > 0.1 || abs(dy) > 0.1 {
                self.onMove?(dx, dy)
            }
        }
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
        velX = 0
        velY = 0
    }

    func resetVelocity() {
        velX = 0
        velY = 0
    }
}
