import Foundation


class MeCoffeeInterface: CoffeeMachineInterface {
    private let send_command: ((Data) -> ())?
    
    init(send_command: ((Data) -> ())?) {
        self.send_command = send_command
    }
    
    func can_send() -> Bool {
        return send_command != nil
    }
    
    func has_just_started_brewing(message: Data) -> Bool {
        if let str: String = String(data: message, encoding: .ascii) {
            return get_brew_runtime(message: str) == "0"
        }
        return false
    }

    func get_runtime(message: Data) ->Int! {
        if let str: String = String(data: message, encoding: .ascii) {
            if str.contains("tmp ") {
                return Int(str.components(separatedBy: "tmp ").last!.components(separatedBy: " ")[0])
            }
        }
        return nil
    }
    
    func get_temperature(message: Data) -> Double! {
        if let str: String = String(data: message, encoding: .ascii) {
            if str.contains("tmp ") {
                let temperature_messages = str.components(separatedBy: "tmp ").last!.components(separatedBy: " ")
                if temperature_messages.count >= 3 {
                    return (Double(temperature_messages[2]) ?? Double.nan)/100
                }
            }
        }
        return nil
    }

    func has_just_stopped_brewing(message: Data) -> Bool {
        if let str: String = String(data: message, encoding: .ascii) {
            return !(["0", nil].contains(get_brew_runtime(message: str)))
        }
        return false
    }

    func get_brew_runtime(message: String) -> String? {
        if message.contains("sht ") {
            let shot_details = message.components(separatedBy: "sht ").last!.components(separatedBy: " ")
            if shot_details.count >= 2 {
                return shot_details[1]
            }
        }
        return nil
    }


    func set_boiler_temperature_target_for_brewing(degrees_celcius: Double) {
        return cmd("tmpsp", Int(round(degrees_celcius*100)))
    }

    func set_preinfusion_time(seconds: Int) {
        return cmd("pistrt", seconds*1000)
    }

    func set_preinfusion_rest_time(seconds: Int) {
        return cmd("piprd", seconds*1000)
    }

    func set_preinfusion_state(on: Bool) {
        return cmd("pinbl", on ? 1 : 0)
    }

    func set_maximum_shot_time(seconds: Int) {
        return cmd("shtmx", seconds)
    }
    
    func set_initial_pressure(percentage: Int) {
        return cmd("pp1", percentage)
    }

    func set_final_pressure(percentage: Int) {
        return cmd("pp2", percentage)
    }

    func set_pressure_rampup_time(seconds: Int) {
        return cmd("ppt", seconds)
    }
    
    func set_added_power_when_brewing(percent: Int) {
        return cmd("tmppap", percent)
    }

    func cmd(_ name: String, _ value: Int) {
        send_command?("\ncmd set \(name) \(value) OK\n".data(using: .ascii)!)
    }
}


func get_pump_parameters_for_ramp_at(shot_time: Double, power_start: Double, power_end: Double, duration: Double) -> [String: Int]{
    /*
    The pressure is defined as
    power(t) = initial_power*(1 - t/ramp_duration) + final_power*t/ramp_up_duration
    when t <= ramp_up_duration; otherwise it is equal to power(ramp_up_duration).
    
    In our case, we know that final_power = power_end and that ramp_duration = shot_time + duration
    the initial_power, comes from the requirement power(shot_time) = power_start
    */
    let final_power = power_end
    let ramp_duration = shot_time + duration
    let initial_power = (power_start - final_power*shot_time/ramp_duration)/(1 - shot_time/ramp_duration)
    return [
        "duration": Int(round(ramp_duration)),
        "initial_power": Int(initial_power),
        "final_power": Int(round(final_power))
    ]
}
