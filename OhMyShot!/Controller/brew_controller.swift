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
    var minutes_since_coffee_machine_power_on: Double = Double.nan
    var coffee_machine_temperature: Double = Double.nan
    var brewing = false
    var current_brew_weight = Double.nan
    
    private var brew_weight_history = TimeSeries(times: [Double](), values: [Double]())

    class func requires_scale() -> Bool {
        return false
    }
    
    required init(scale: ScaleInterface, coffee_machine: CoffeeMachineInterface) {
        self.scale = scale
        self.coffee_machine = coffee_machine
        DispatchQueue.global(qos: .background).async{self.set_idle_coffee_machine_parameters()}
    }
    
    func process_coffee_machine_message(message: Data) {
        if let temperature = coffee_machine.get_temperature(message: message) {
            coffee_machine_temperature = temperature
        }
        if let runtime = coffee_machine.get_runtime(message: message) {
            minutes_since_coffee_machine_power_on = Double(runtime) / 60.0
        }
        if !brewing && coffee_machine.has_just_started_brewing(message: message) {
            DispatchQueue.global(qos: .background).async{
                self.brewing = true
                self.start_brewing_profile()
                self.wait_for(seconds: 1) // To allow recording of data etc. to finish
                self.brewing = false
            }
        }
        else if coffee_machine.has_just_stopped_brewing(message: message) { brewing = false }
    }
    
    func process_scale_message(message: Data) {
        if let weight = scale.get_weight(message: message) {
            current_brew_weight = weight
            if brewing && is_valid(weight) {
                brew_weight_history.values.append(weight)
                brew_weight_history.times.append(Date().timeIntervalSince1970)
            }
            else if !brewing {
                save_brew_weight_history()
                brew_weight_history = TimeSeries(times: [Double](), values: [Double]())
            }
        }
    }
    
    private func save_brew_weight_history() {
        if brew_weight_history.times.isEmpty { return }
        let history_seconds = brew_weight_history.times.last! - brew_weight_history.times.first!
        if history_seconds < 10 { return }
        let history_range = brew_weight_history.values.max()! - brew_weight_history.values.min()!
        if history_range < 5.0 { return }
        brew_weight_history.times = brew_weight_history.times.map{$0 - brew_weight_history.times[0]}
        save_shot_weight(brew_weight_history)
    }
    
    func start_brewing_profile() {  // This function runs in a separate thread
        precondition(false, "No brewing profile defined")
    }
    
    func set_idle_coffee_machine_parameters() {  // This function runs in a separate thread
        if coffee_machine.can_send() {
            coffee_machine.set_boiler_temperature_target_for_brewing(
                degrees_celcius: setting("boilerTemperatureSetpoint")
            )
        }
    }
    
    func desired_weight_was_reached() -> Bool {
        return is_valid(current_brew_weight) &&
            current_brew_weight > setting("desiredBrewWeight") - 1.5
    }
    
    func is_weight_positive() -> Bool {
        return is_valid(current_brew_weight) && current_brew_weight > setting("nonzeroWeightThreshold")
    }
    
    func wait_for(seconds: Double, sleep_microseconds: UInt32 = 10000) {
        let start_time = Date()
        while brewing && -start_time.timeIntervalSinceNow < seconds {
            usleep(sleep_microseconds)
        }
    }
    
    func wait_until(_ condition: () -> Bool, sleep_microseconds: UInt32 = 10000) {
        while brewing && !condition() {
            usleep(sleep_microseconds)
        }
    }
    
    func stop_brewing() {
        if brewing {
            brewing = false
            usleep(500000) // Wait .5 seconds for finilization of brewing method(send final commands etc)
        }
    }
    
    func is_valid(_ weight: Double) -> Bool {
        return weight >= 0 && weight <= 60
    }
}


class NoActionBrewController: BrewController {
    override func start_brewing_profile() {}  // This function runs in a separate thread
}


class PlainBrewController: BrewController {
    override class func requires_scale() -> Bool {
        return true
    }
    
    override func set_idle_coffee_machine_parameters() {  // This function runs in a separate thread
        super.set_idle_coffee_machine_parameters()
        coffee_machine.set_initial_pressure(percentage: 100)
        coffee_machine.set_final_pressure(percentage: 100)
    }
    
    override func start_brewing_profile() {  // This function runs in a separate thread
        let start_time = Date()
        scale.restart()
        if is_true("disablePIDWhenBrewing") { coffee_machine.set_boiler_temperature_target_for_brewing(degrees_celcius: 0)
        }
        coffee_machine.set_maximum_shot_time(seconds: 60)
        wait_until{desired_weight_was_reached()}
        coffee_machine.set_maximum_shot_time(seconds: Int(-start_time.timeIntervalSinceNow))
        wait_for(seconds: 1) // To account for the fact that the scale timer started a bit after brewing
        scale.stop_timer()
        coffee_machine.set_boiler_temperature_target_for_brewing(
            degrees_celcius: setting("boilerTemperatureSetpoint")
        )
    }
}

class ProfiledBrewController: BrewController {
    override class func requires_scale() -> Bool {
        return true
    }
    
    override func start_brewing_profile() {  // This function runs in a separate thread
        let start_time = Date()
        scale.restart()
        if is_true("disablePIDWhenBrewing") { coffee_machine.set_boiler_temperature_target_for_brewing(degrees_celcius: 0)
        }
        coffee_machine.set_maximum_shot_time(seconds: 60)
        wait_until({is_weight_positive()})
        full_power_with_delayed_rampdown(brew_start_time: start_time)
        wait_until({desired_weight_was_reached()})
        coffee_machine.set_maximum_shot_time(seconds: Int(-start_time.timeIntervalSinceNow))
        wait_for(seconds: 1) // To account for the fact that the scale timer started a bit after brewing
        scale.stop_timer()
        set_idle_coffee_machine_parameters()
    }
    
    func full_power_with_delayed_rampdown(brew_start_time: Date) {
        if !brewing {return}
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
    
    override func set_idle_coffee_machine_parameters() {  // This function runs in a separate thread
        super.set_idle_coffee_machine_parameters()
        coffee_machine.set_initial_pressure(percentage: Int(round(setting("initialPumpPower"))))
        coffee_machine.set_final_pressure(percentage: 100)
        let rampup_time = (100.0 - setting("initialPumpPower"))/setting("initialRampUpRate")
        coffee_machine.set_pressure_rampup_time(seconds: Int(rampup_time))
        coffee_machine.set_added_power_when_brewing(percent: Int(setting("addedBoilerPowerWhileBrewing")))
    }
}



class BackFlushingBrewController: BrewController {
    private let pause_time = 10
    private let brew_time = 4
    
    override func process_coffee_machine_message(message: Data) {
        // Don't listen to the stopped brewing messages
        // Many messages like this will be generated while backflushign
        // because we repeatedly start and stop brewing
        if !coffee_machine.has_just_stopped_brewing(message: message) {
            super.process_coffee_machine_message(message: message)
        }
    }
    
    override func set_idle_coffee_machine_parameters() {  // This function runs in a separate thread
        super.set_idle_coffee_machine_parameters()
        coffee_machine.set_initial_pressure(percentage: 100)
        coffee_machine.set_final_pressure(percentage: 100)
        coffee_machine.set_maximum_shot_time(seconds: brew_time + 1)
    }
    
    override func start_brewing_profile() {  // This function runs in a separate thread
        let start_time = Date()
        let backflush_iterations = 2
        for backflush_iteration in 1...backflush_iterations {
            let current_shot_end_time = (backflush_iteration - 1)*(brew_time + pause_time) + brew_time
            if brewing && backflush_iteration > 1 { // First shot slightly longer than the rest
                coffee_machine.set_maximum_shot_time(seconds: current_shot_end_time)
            }
            if backflush_iteration < backflush_iterations {
                wait_until(
                    {-start_time.timeIntervalSinceNow > Double(current_shot_end_time + pause_time) - 0.5}
                )
            }
            else {
                wait_until({-start_time.timeIntervalSinceNow > Double(current_shot_end_time)})
            }
        }
        coffee_machine.set_maximum_shot_time(seconds: brew_time + 1)
    }
}

class WarmupCoffeeController: BrewController {
    override func set_idle_coffee_machine_parameters() {  // This function runs in a separate thread
        super.set_idle_coffee_machine_parameters()
        coffee_machine.set_initial_pressure(percentage: Int(setting("warmupPumpPower")))
        coffee_machine.set_final_pressure(percentage: Int(setting("warmupPumpPower")))
        coffee_machine.set_added_power_when_brewing(percent: Int(setting("warmupAddedBoilerPower")))
        coffee_machine.set_maximum_shot_time(seconds: Int(setting("warmupDuration")))
    }
    
    override func start_brewing_profile() {}  // This function runs in a separate thread
}


