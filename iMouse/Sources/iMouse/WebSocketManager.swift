import Foundation
import Combine

class WebSocketManager: ObservableObject {
    @Published var isConnected = false
    @Published var serverIP: String = UserDefaults.standard.string(forKey: "serverIP") ?? ""

    private var webSocketTask: URLSessionWebSocketTask?
    private var pingTimer: Timer?

    func connect() {
        guard !serverIP.isEmpty else { return }
        UserDefaults.standard.set(serverIP, forKey: "serverIP")

        let urlString = "ws://\(serverIP):8765"
        guard let url = URL(string: urlString) else { return }

        disconnect()

        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()

        receiveMessage()

        pingTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.webSocketTask?.sendPing { _ in }
        }

        // Optimistic — confirm on first message or ping
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isConnected = true
        }
    }

    func disconnect() {
        pingTimer?.invalidate()
        pingTimer = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        DispatchQueue.main.async { self.isConnected = false }
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    if let data = text.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let type_ = json["type"] as? String, type_ == "sensitivity",
                       let val = json["value"] as? Double {
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .sensitivityUpdate, object: val)
                        }
                    }
                default: break
                }
                self?.receiveMessage()
            case .failure:
                DispatchQueue.main.async { self?.isConnected = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self?.connect() }
            }
        }
    }

    func send(_ dict: [String: Any]) {
        guard isConnected,
              let data = try? JSONSerialization.data(withJSONObject: dict),
              let str = String(data: data, encoding: .utf8) else { return }
        webSocketTask?.send(.string(str)) { _ in }
    }
}

extension Notification.Name {
    static let sensitivityUpdate = Notification.Name("sensitivityUpdate")
}
