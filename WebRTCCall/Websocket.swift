//
//  Websocket.swift
//  pushme
//
//  Created by lynn on 2025/6/16.
//
import Starscream
import Foundation


class WebSocketManager: WebSocketDelegate {
    static let shared = WebSocketManager()
    
    var socket: WebSocket!
    var pingTimer: Timer?
    private let maxCount = 5
    var connectionTimes = 0
    private init() {
        let userId = KeychainHelper.shared.getDeviceID()
        var request = URLRequest(url: URL(string: "ws://192.168.1.7:8080?call=\(userId)")!)
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        socket.delegate = self
        socket.connect()
        startPing()
    }
    
    deinit{
        socket.disconnect()
        pingTimer?.invalidate()
    }
    
    func startPing() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            self?.socket.write(ping: "ping".data(using: .utf8)!){}
        }
    }
    
    func connect() {
        socket.connect()
    }
    
    func disconnect() {
        socket.disconnect()
    }
    
    func send(message: String) {
        socket.write(string: message)
    }
    
    // MARK: - WebSocketDelegate
    func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
        switch event {
        case .connected(let headers):
            print("WebSocket connected: \(headers)")
        case .disconnected(let reason, let code):
            print("WebSocket disconnected: \(reason) (code: \(code))")
        case .text(let text):
            print("Received text: \(text)")
        case .binary(let data):
            print("Received data: \(data.count) bytes")
        case .error(let error):
            print("WebSocket error: \(error?.localizedDescription ?? "Unknown")")
            if connectionTimes < maxCount{
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(connectionTimes) * 0.2){
                    self.connectionTimes += 1
                    self.socket.connect()
                }
            }
        case .ping(_), .pong(_):
            print("收到心跳包")
        case .viabilityChanged(_), .reconnectSuggested(_), .cancelled, .peerClosed:
            break
        }
    }
}

