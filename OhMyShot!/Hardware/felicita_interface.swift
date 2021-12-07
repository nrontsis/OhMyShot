import Foundation

class FelicitaInterface : ScaleInterface {
    private let send_command: ((Data) -> ())?
    
    init(send_command: ((Data) -> ())?) {
        self.send_command = send_command
    }
    
    func can_send() -> Bool {
        return send_command != nil
    }
    
    func tare() {
        send_command?(Data(bytes: [84], count: 1))
    }
    
    func start_timer() {
        send_command?(Data(bytes: [82], count: 1))
    }
    
    func reset_timer() {
        send_command?(Data(bytes: [67], count: 1))
    }

    func stop_timer() {
        send_command?(Data(bytes: [83], count: 1))
    }
    
    func restart() {
        tare()
        reset_timer()
        start_timer()
        tare()
    }

    func get_weight(message: Data) -> Double? {
        if message.count == 18, let weight_str = String(data: message[2...8], encoding: .ascii) {
            if let grams_over_a_hundred = Int(weight_str) {
                return Double(grams_over_a_hundred) / 100.0
            }
        }
        return nil
    }
}
