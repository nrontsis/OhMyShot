import Foundation
let persistent_data = UserDefaults(suiteName: "com.nikitas.OhMyShot!")!

let number_of_shots_saved = 4

struct TimeSeries: Codable {
    var times: [Double]
    var values: [Double]
}

func raw_setting(_ key: String) -> String {
    if let setting_value = persistent_data.value(forKey: key) as? String  {
        return setting_value
    }
    else {
        let defaults: [String : String] = [
            "plotsStartAtNonZeroWeight": "false",
            "boilerTemperatureSetpoint": "101.0",
            "addedBoilerPowerWhileBrewing": "6.0",
            "initialPumpPower": "40",
            "initialRampUpRate": "1.0",
            "stayAtFullPowerDuration": "5.0",
            "rampDownRate": "2.0",
            "controllerType": "Profiled",
            "desiredBrewWeight": "36.0",
            "shouldReloadSettings": "true",
            "nonzeroWeightThreshold": "0.3",
            "warmupDuration": "25",
            "warmupPumpPower": "40",
            "warmupAddedBoilerPower": "45",
            "disablePIDWhenBrewing": "true",
        ]
        return defaults[key]!
    }
}

func save_setting(_ key: String, _ value: String, should_reload: Bool = true) {
    persistent_data.set(value, forKey: key)
    if !(["shouldReloadSettings", "plotsStartAtNonZeroWeight"].contains(key)) && should_reload {
        persistent_data.set("true", forKey: "shouldReloadSettings")
    }
}

func setting(_ key: String) -> Double {
    return Double(raw_setting(key))!
}

func is_true(_ key: String) -> Bool {
    return Bool(raw_setting(key))!
}

func string_setting(_ key: String) -> String {
    return raw_setting(key)
}

func save_shot_weight(_ series: TimeSeries){
    print("Saving:", series)
    shift_saved_shots()
    persistent_data.set(series.times + series.values, forKey: "shotWeight[0]")
}

func saved_shots_exist() -> Bool {
    for i in 0..<number_of_shots_saved {
        if load_shot_weight_series(i).times.count > 0 {
            return true
        }
    }
    return false
}

func shift_saved_shots() {
    for i in (1..<number_of_shots_saved).reversed() {
        persistent_data.set(
            persistent_data.value(forKey: "shotWeight[\(i - 1)]"),
            forKey: "shotWeight[\(i)]"
        )
    }
}

func load_shot_weight_per_decisecond(_ index: Int = 0) -> [Double] {
    let series = load_shot_weight_series(index)
    if series.times.count > 1 && series.values.count > 1 {
        return interpolate_interior(x: series.times, y: series.values, step: 0.1)
    }
    else {
        return [Double]()
    }
}

func load_shot_weight_series(_ index: Int = 0) -> TimeSeries {
    if let data = persistent_data.value(forKey: "shotWeight[\(index)]") as? [Double] {
        let series = TimeSeries(times: Array(data[0..<data.count/2]), values: Array(data[(data.count/2)...]))
        return drop_delayed_measurements(series, dt_threshold: 0.3)
    }
    return TimeSeries(times: [Double](), values: [Double]())
}

func write_dummy_shots() {
    for i in 1...number_of_shots_saved {
        let series = TimeSeries(times: [0.0, 0.5, 1.0, 7.0, 10.0], values: [0.0, 0.0, 1.0, Double(i)*8.0, Double(i)*11.0])
        persistent_data.set(
            series.times + series.values,
            forKey: "shotWeight[\(i - 1)]"
        )
    }
}
