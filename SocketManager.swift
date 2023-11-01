import Foundation
import SocketIO
import SwiftyJSON
import CoreLocation

typealias SocketOnResponseBlock = ((JSON) -> Void)

class SocketIOManager: NSObject {
    static let shared = SocketIOManager()
    var isReconnected: Bool = false
    let manager = SocketManager(socketURL: URL(string: NetworkEnvironment.socketBaseURL)!, config: [.log(false), .compress])
    lazy var socket = manager.defaultSocket
    
    private var isSocketOn: Bool {
        socket.status == .connected
    }
    
    override private init() {
        super.init()
        
        socket.on(clientEvent: .disconnect) { (data, ack) in
            print ("[SocketIO] socket is disconnected please reconnect")
        }
        
        socket.on(clientEvent: .reconnect) { (data, ack) in
            print ("[SocketIO] socket is reconnected")
            self.isReconnected = true
        }

        socket.on(clientEvent: .error) { (data, eck) in
            print(data)
            print(eck)
            print(self.socket.status)
            print("[SocketIO] socket error")
        }
        
        socket.on(clientEvent: .connect) {data, ack in
            print ("[SocketIO] socket connected")
            if self.isReconnected {
                self.isReconnected = false
                NotificationCenter.default.post(name: .init("socket_reconnected"), object: nil)
            }
        }
    }
    
    func establishConnection() {
        if socket.status != .connected {
            socket.connect()
        }
    }
    
    func closeConnection() {
        if isSocketOn {
            socket.disconnect()
        }
    }
    
    func observeOnEvent(_ key: SocketApiKeys, completion: @escaping SocketOnResponseBlock) {
        SocketIOManager.shared.socket.on(key.rawValue, callback: { (data, ack) in
            let result = self.dataSerializationToJson(data: data)
            guard result.status else { return }
            completion(result.json)
        })
    }

    func observeOnEventCodable<T: Decodable>(_ key: String, callback: @escaping (T)-> Void) {
        self.socket.on(key) { (data, _) in
            guard !data.isEmpty else {
                print("[SocketIO] \(key) data empty")
                return
            }
            print(data[0])
            guard let decoded = try? T(from: data[0]) else {
                print("[SocketIO] \(key) data \(data) cannot be decoded to \(T.self)")
                return
            }
            callback(decoded)
        }
    }

    func socketEmit(for key: String, with parameter: [String:Any]){
        socket.emit(key, with: [parameter], completion: nil)
        //        print ("Parameter Emitted for key - \(key) :: \(parameter)")
    }

    func emit(key: SocketApiKeys, parameter: [String: Any]) {
        socket.emit(key.rawValue, with: [parameter], completion: nil)
       // print ("Parameter Emitted for key - \(key.rawValue) :: \(parameter)")
    }
    
    func emitWithAck(
        key: SocketApiKeys,
        parameter: [String: Any],
        retryCount: Int = 0,
        completion: ((_ success: Bool) -> Void)? = nil
    ) {
        socket.emitWithAck(key.rawValue, parameter)
            .timingOut(after: 3) { data in
                let ack = data.first as? String ?? ""
                if ack != key.rawValue {
                    if retryCount > 0 {
                        self.emitWithAck(key: key, parameter: parameter, retryCount: retryCount - 1)
                    } else {
                        completion?(false)
                    }
                } else {
                    completion?(true)
                }
                print("Ack ", ack)
            }
      //  print ("Parameter Emitted for key - \(key.rawValue) :: \(parameter)")
    }

    func emitSocketEvent(_ type: SocketEmitType) {
        guard self.socket.status == .connected else {
            return
        }
        switch type {
        case .updateCustomerLocation(let customerId, let coordinates):
            let params: [String: Any] = ["customer_id": customerId, "lat": coordinates.latitude, "lng": coordinates.longitude]
            self.emit(key: .UpdateCustomerLatLng, parameter: params)
        case .requestForEstimateFare(let params):
            self.emit(key: .GetEstimateFare, parameter: params)
        case .requestForNearByDriver(let customerId, let coordinate):
            let param: [String: Any] = ["customer_id": customerId,
                                        "current_lng": coordinate.longitude,
                                        "current_lat": coordinate.latitude]
            emit(key: .NearByDriver, parameter: param)
        }
    }
    
    
    
    func dataSerializationToJson(data: [Any],_ description : String = "") -> (status: Bool, json: JSON){
        let json = JSON(data)
        //        print (description, ": \(json)")
        return (true, json)
    }

    /// Socket Off All
    func turnOffAllSocketOnMethods() {
        let events = SocketApiKeys.allCases
        events.forEach({
            SocketIOManager.shared.socket.off($0.rawValue)
        })
        SocketIOManager.shared.socket.off(clientEvent: .disconnect)// Socket Disconnect
    }
}

enum SocketEmitType {
    case updateCustomerLocation(customerId: String, coordinates: CLLocationCoordinate2D)
    case requestForEstimateFare(params: [String: Any])
    case requestForNearByDriver(customerId: String, coordinates: CLLocationCoordinate2D)
    
}

extension Decodable {
    init(from any: Any) throws {
        let data = try JSONSerialization.data(withJSONObject: any)
        self = try JSONDecoder().decode(Self.self, from: data)
    }
}
