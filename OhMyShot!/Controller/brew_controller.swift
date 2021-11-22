import Foundation

protocol CoffeeMachineInterface {
    func can_send() -> Bool
    func get_runtime(message: Data) ->Int!
    func has_just_started_brewing(message: Data) -> Bool
    func has_just_stopped_brewing(message: Data) -> Bool
    func set_boiler_temperature_target_for_brewing(degrees_celcius: Double)
    func set_added_power_when_brewing(percent: Int)
    func set_preinfusion_time(seconds: Int)
    func set_preinfusion_rest_time(seconds: Int)
    func set_preinfusion_state(on: Bool)
    func set_maximum_shot_time(seconds: Int)
    func set_initial_pressure(percentage: Int)
    func set_final_pressure(percentage: Int)
    func set_pressure_rampup_time(seconds: Int)
    func get_temperature(message: Data) -> Double!
}

protocol ScaleInterface {
    func can_send() -> Bool
    func get_weight(message: Data) -> Double?
    func tare()
    func start_timer()
    func reset_timer()
    func stop_timer()
    func restart()
}


class BrewController {
    let scale: ScaleInterface
    let coffee_machine: CoffeeMachineInterface
    var current_brew_weight = Double.nan
    var desired_brew_weight = Double.nan
    var minutes_since_coffee_machine_power_on: Double = 0.0
    var coffee_machine_temperature: Double = Double.nan
    
    var brewing = false
    var recording = false
    var brew_weight_history = TimeSeries(times: [Double](), values: [Double]())

    class func requires_scale() -> Bool {
        return false
    }
    
    required init(scale: ScaleInterface, coffee_machine: CoffeeMachineInterface, desired_brew_weight: Double) {
        self.scale = scale
        self.coffee_machine = coffee_machine
        self.desired_brew_weight = desired_brew_weight
        self.set_idle_coffee_machine_parameters()
    }
    
    func process_coffee_machine_message(message: Data) {
        let str = String(data: message, encoding: .ascii)!
        if !str.contains("tmp ") && !str.contains("pid ") && str.count > 6 {
            print(str.replacingOccurrences(of: "[\\r\\n]", with: "", options: .regularExpression))
        }
        if let temperature = coffee_machine.get_temperature(message: message) {
            coffee_machine_temperature = temperature
        }
        if !brewing && coffee_machine.has_just_started_brewing(message: message) {
            brewing = true
            DispatchQueue.global(qos: .background).async{self.start_brewing_profile()}
            brewing = false
        }
        else if coffee_machine.has_just_stopped_brewing(message: message) {
            brewing = false
        }
    }
    
    func process_scale_message(message: Data) {
        if let weight = scale.get_weight(message: message) {
            if weight >= 0 && weight <= 60 {
                current_brew_weight = weight
                if brewing {
                    brew_weight_history.values.append(weight)
                    brew_weight_history.times.append(Date().timeIntervalSince1970)
                }
                else {
                    if brew_weight_history.times.count > 150 {
                        brew_weight_history.times = brew_weight_history.times.map{$0 - brew_weight_history.times[0]}
                        save_shot_weight(brew_weight_history)
                    }
                    brew_weight_history = TimeSeries(times: [Double](), values: [Double]())
                }
            }
        }
    }
    
    func start_brewing_profile() {  // This function runs in a separate thread
        precondition(false, "No brewing profile defined")
    }
    func set_idle_coffee_machine_parameters() {}
    func desired_weight_was_reached() -> Bool {
        return current_brew_weight > desired_brew_weight - 1.0
    }
    
    func wait_for(seconds: Double, sleep_microseconds: UInt32 = 10000) {
        let start_time = Date()
        while brewing && -start_time.timeIntervalSinceNow < seconds {
            usleep(sleep_microseconds)
        }
    }
    
    func wait_until(condition: () -> Bool, sleep_microseconds: UInt32 = 10000) {
        while brewing && condition() {
            usleep(sleep_microseconds)
        }
    }
    
    func stop_brewing() {
        if brewing {
            brewing = false
            usleep(500000) // Wait .5 seconds for finilization of brewing method(send final commands etc)
        }
    }
}


class NoActionBrewController: BrewController {
    override func start_brewing_profile() {}  // This function runs in a separate thread
}


class PlainBrewController: BrewController {
    override class func requires_scale() -> Bool {
        return true
    }
    
    override func set_idle_coffee_machine_parameters() {
        coffee_machine.set_preinfusion_state(on: false)
        coffee_machine.set_initial_pressure(percentage: 100)
        coffee_machine.set_final_pressure(percentage: 100)
    }
    
    override func start_brewing_profile() {  // This function runs in a separate thread
        let start_time = Date()
        scale.restart()
        coffee_machine.set_maximum_shot_time(seconds: 60)
        wait_until{!desired_weight_was_reached() && brewing}
        coffee_machine.set_maximum_shot_time(seconds: Int(-start_time.timeIntervalSinceNow))
        sleep(1) // To account for the fact that the scale timer started a bit after brewing
        scale.stop_timer()
    }
}

class ProfiledBrewController: BrewController {
    override class func requires_scale() -> Bool {
        return true
    }
    
    override func start_brewing_profile() {  // This function runs in a separate thread
        let start_time = Date()
        scale.restart()
        coffee_machine.set_boiler_temperature_target_for_brewing(degrees_celcius: 0)
        wait_until(condition: {current_brew_weight < setting("nonzeroWeightThreshold")})
        if brewing {full_power_with_delayed_rampdown(brew_start_time: start_time)}
        wait_until(condition: {current_brew_weight < setting("nonzeroWeightThreshold")})
        coffee_machine.set_maximum_shot_time(seconds: Int(-start_time.timeIntervalSinceNow))
        sleep(1) // To account for the fact that the scale timer started a bit after brewing
        scale.stop_timer()
    }
    
    func full_power_with_delayed_rampdown(brew_start_time: Date) {
        let duration = 30.0
        let ramp_down_parameters = get_pump_parameters_for_ramp_at(
            shot_time: -brew_start_time.timeIntervalSinceNow + setting("stayAtFullPowerDuration"),
            power_start: 100.0,
            power_end: 100.0 - setting("rampDownRate")*duration,
            duration: duration
        )
        coffee_machine.set_initial_pressure(percentage: ramp_down_parameters["initial_power"]!)
        coffee_machine.set_pressure_rampup_time(seconds: ramp_down_parameters["duration"]!)
        coffee_machine.set_final_pressure(percentage: ramp_down_parameters["final_power"]!)
    }
    
    override func set_idle_coffee_machine_parameters() {
        coffee_machine.set_preinfusion_state(on: false)
        coffee_machine.set_initial_pressure(percentage: Int(round(setting("initialPumpPower"))))
        coffee_machine.set_final_pressure(percentage: 100)
        let rampup_time = (100.0 - setting("initialPumpPower"))/setting("initialRampUpRate")
        coffee_machine.set_pressure_rampup_time(seconds: Int(rampup_time))
        coffee_machine.set_added_power_when_brewing(percent: Int(setting("addedBoilerPowerWhileBrewing")))
        coffee_machine.set_boiler_temperature_target_for_brewing(degrees_celcius: setting("boilerTemperatureSetpoint"))
    }
}



class BackFlushingBrewController: BrewController {
    override func process_coffee_machine_message(message: Data) {
        // Don't listened to the stopped brewing messages
        // Many messages like this will be generated while backflushign
        // because we repeatedly start and stop brewing
        if !coffee_machine.has_just_stopped_brewing(message: message) {
            super.process_coffee_machine_message(message: message)
        }
    }
    
    override func set_idle_coffee_machine_parameters() {
        coffee_machine.set_preinfusion_state(on: false)
        coffee_machine.set_initial_pressure(percentage: 100)
        coffee_machine.set_final_pressure(percentage: 100)
    }
    
    override func start_brewing_profile() {  // This function runs in a separate thread
        let backflush_iterations = 5
        for backflush_iteration in 1...backflush_iterations {
            if brewing {coffee_machine.set_maximum_shot_time(seconds: 0)}
            wait_for(seconds: 4.5)
            if brewing {coffee_machine.set_maximum_shot_time(seconds: 1)}
            if brewing && backflush_iteration < backflush_iterations {
                wait_for(seconds: 10)
            }
        }
        coffee_machine.set_maximum_shot_time(seconds: max(backflush_iterations*15 - 10, 60))
    }
}

class WarmupCoffeeController: BrewController {
    override func set_idle_coffee_machine_parameters() {
        coffee_machine.set_preinfusion_state(on: false)
        coffee_machine.set_initial_pressure(percentage: Int(setting("warmupPumpPower")))
        coffee_machine.set_final_pressure(percentage: Int(setting("warmupPumpPower")))
        coffee_machine.set_added_power_when_brewing(percent: Int(setting("warmupAddedBoilerPower")))
        coffee_machine.set_maximum_shot_time(seconds: Int(setting("warmupDuration")))
    }
    
    override func start_brewing_profile() {}  // This function runs in a separate thread
}


