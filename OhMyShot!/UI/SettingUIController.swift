import UIKit

class SettingUIController: UITableViewController {
    var updated_values: [String : String] = [String : String]()
    
    func update_value(_ key: String, _ value: String) {
        updated_values[key] = value
        updateUI()
        saveButton.isEnabled = is_there_something_to_save()
    }
    
    func is_there_something_to_save() -> Bool {
        for (key, value) in updated_values {
            if raw_setting(key) != value {
                return true
            }
        }
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        saveButton.isEnabled = false
        updateUI()
    }
    
    func updateUI() {
        plotsStartAtNonZeroWeight.isOn = Bool(get_value("plotsStatAtNonZeroWeight"))!
        
        rampDownRate.value = Float(get_value("rampDownRate"))!
        rampDownRateLabel.text! = get_value("rampDownRate") + "% per second"
        
        
        stayAtFullPowerDuration.value = Float(get_value("stayAtFullPowerDuration"))!
        stayAtFullPowerDurationLabel.text! = get_value("stayAtFullPowerDuration") + " seconds"
        
        initialRampUpRate.value = Float(get_value("initialRampUpRate"))!
        initialRampUpRateLabel.text! = get_value("initialRampUpRate") + "% per second"
        
        initialPumpPower.value = Float(get_value("initialPumpPower"))!
        initialPumpPowerLabel.text! = get_value("initialPumpPower") + "%"
        
        addedBoilerPowerWhileBrewing.value = Float(get_value("addedBoilerPowerWhileBrewing"))!
        addedBoilerPowerWhileBrewingLabel.text! = get_value("addedBoilerPowerWhileBrewing") + "%"
        
        boilerTemperatureSetpoint.value = Float(get_value("boilerTemperatureSetpoint"))!
        boilerTemperatureSetpointLabel.text! = get_value("boilerTemperatureSetpoint") + " °C"
    }
    
    func get_value(_ key: String) -> String {
        if let value = updated_values[key] {
            return value
        }
        else {
            return raw_setting(key)
        }
    }
    
    @IBOutlet weak var rampDownRate: UISlider!
    @IBOutlet weak var stayAtFullPowerDuration: UISlider!
    @IBOutlet weak var initialRampUpRate: UISlider!
    @IBOutlet weak var initialPumpPower: UISlider!
    @IBOutlet weak var addedBoilerPowerWhileBrewing: UISlider!
    @IBOutlet weak var plotsStartAtNonZeroWeight: UISwitch!
    @IBOutlet weak var boilerTemperatureSetpoint: UISlider!
    @IBOutlet weak var rampDownRateLabel: UILabel!
    @IBOutlet weak var stayAtFullPowerDurationLabel: UILabel!
    @IBOutlet weak var initialRampUpRateLabel: UILabel!
    @IBOutlet weak var initialPumpPowerLabel: UILabel!
    @IBOutlet weak var addedBoilerPowerWhileBrewingLabel: UILabel!
    @IBOutlet weak var boilerTemperatureSetpointLabel: UILabel!
    @IBAction func boilerSetpointChanged(_ sender: UISlider) {
        update_value("boilerTemperatureSetpoint", String(format: "%.1f", sender.value))
    }
    @IBAction func powerWhileBrewingChanged(_ sender: UISlider) {
        update_value("addedBoilerPowerWhileBrewing", String(format: "%.0f", sender.value))
    }
    @IBAction func initialPumpPowerChanged(_ sender: UISlider) {
        update_value("initialPumpPower", String(format: "%.0f", sender.value))
    }
    @IBAction func initialRampUpRateChanged(_ sender: UISlider) {
        update_value("initialRampUpRate", String(format: "%.1f", sender.value))
    }
    @IBAction func stayAtFullPowerDurationChanged(_ sender: UISlider) {
        update_value("stayAtFullPowerDuration", String(format: "%.1f", sender.value))
    }
    @IBOutlet weak var saveButton: UIButton!
    @IBAction func save(_ sender: UIButton) {
        for (key, value) in updated_values {
            save_setting(key, value)
            saveButton.isEnabled = false
        }
    }
    @IBAction func rampDownRateChanged(_ sender: UISlider) {
        update_value("rampDownRate", String(format: "%.1f", sender.value))
    }
    @IBAction func plotStartChanged(_ sender: UISwitch) {
        update_value("plotsStatAtNonZeroWeight", String(sender.isOn))
    }
}
