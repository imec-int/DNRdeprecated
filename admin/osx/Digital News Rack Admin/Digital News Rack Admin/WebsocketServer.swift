//
//  WebsocketServer.swift
//
//  Created by Sam Decrock on 29/04/16.
//  Copyright © 2016 Sam. All rights reserved.
//

import Foundation
import PocketSocket
import EmitterKit

class WebsocketServer: NSObject, PSWebSocketServerDelegate {
    
    private var server: PSWebSocketServer!

    private var sockets = [PSWebSocket]()
    
    var onSocketConnected = Event<PSWebSocket>()
    var onSocketMessage = Event<String>()
    var onAllSocketsDisconnected = Signal()
    
    override init() {
        server = PSWebSocketServer(host: "127.0.0.1", port: 8021)
        super.init()
        
        
        server.delegate = self
        server.start()
    }
    
    func sendObject(data: [String: AnyObject]) {
        for socket in sockets {
            socket.send(JSON.stringify(data))
        }
    }
    
    func sendText (text: String) {
        for socket in sockets {
            socket.send(text)
        }
    }
    
    // MARK: Websocket delegates:
    func serverDidStart(server:PSWebSocketServer!) {
        print("WebsocketServer> started")
    }
    
    func serverDidStop(server:PSWebSocketServer!) {
        print("WebsocketServer> stopped")
    }
    
    func server(server:PSWebSocketServer!, acceptWebSocketWithRequest request:NSURLRequest) -> (Bool) {
        print("WebsocketServer> accepting incoming request on: \(request.URL!)")
        return true
    }
    
    func server(server:PSWebSocketServer!, webSocketDidOpen webSocket:PSWebSocket!) {
        print("WebsocketServer> socket connected: \(webSocket.readyState)")
        sockets.append(webSocket)
        self.onSocketConnected.emit(webSocket)
    }
    
    func server(server:PSWebSocketServer!, webSocket:PSWebSocket!, didReceiveMessage message: AnyObject) {
        print("WebsocketServer> incoming message:", message)
        
        if let text = message as? String {
            self.onSocketMessage.emit(text)
        }
    }
    
    func server(server:PSWebSocketServer!, webSocket:PSWebSocket!, didCloseWithCode code:NSInteger, reason:String, wasClean:Bool) {
        print("WebsocketServer> socket disconnected with code: \(code), reason: \(reason), wasClean: \(wasClean)")
        
        
        sockets = sockets.filter { (socket) -> Bool in
            return socket != webSocket
        }
        if sockets.count == 0 {
            self.onAllSocketsDisconnected.emit()
        }
    }
    
    func server(server:PSWebSocketServer!, webSocket:PSWebSocket!, didFailWithError error:NSError) {
        print("WebsocketServer> socket disconnected with error")
        
        sockets = sockets.filter { (socket) -> Bool in
            return socket != webSocket
        }
        if sockets.count == 0 {
            self.onAllSocketsDisconnected.emit()
        }
    }
}