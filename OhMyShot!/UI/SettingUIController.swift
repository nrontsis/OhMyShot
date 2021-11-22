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
        plotsStartAtNonZeroWeight.isOn = Bool(get_value("plotsStartAtNonZeroWeight"))!
        
        disablePIDWhenBrewing.isOn = Bool(get_value("disablePIDWhenBrewing"))!
        
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
        
        
        warmupAddedBoilerPower.value = Float(get_value("warmupAddedBoilerPower"))!
        warmupAddedBoilerPowerLabel.text! = get_value("warmupAddedBoilerPower") + "%"
        
        warmupPumpPower.value = Float(get_value("warmupPumpPower"))!
        warmupPumpPowerLabel.text! = get_value("warmupPumpPower") + "%"
        
        warmupDuration.value = Float(get_value("warmupDuration"))!
        warmupDurationLabel.text! = get_value("warmupDuration") + " seconds"
    }
    
    func get_value(_ key: String) -> String {
        if let value = updated_values[key] {
            return value
        }
        else {
            return raw_setting(key)
        }
    }
    
    @IBOutlet weak var warmupPumpPowerLabel: UILabel!
    @IBOutlet weak var warmupAddedBoilerPowerLabel: UILabel!
    @IBOutlet weak var warmupDurationLabel: UILabel!
    @IBOutlet weak var warmupPumpPower: UISlider!
    @IBOutlet weak var warmupAddedBoilerPower: UISlider!
    @IBOutlet weak var warmupDuration: UISlider!
    @IBOutlet weak var rampDownRate: UISlider!
    @IBOutlet weak var stayAtFullPowerDuration: UISlider!
    @IBOutlet weak var initialRampUpRate: UISlider!
    @IBOutlet weak var initialPumpPower: UISlider!
    @IBOutlet weak var addedBoilerPowerWhileBrewing: UISlider!
    @IBOutlet weak var plotsStartAtNonZeroWeight: UISwitch!
    
    @IBOutlet weak var disablePIDWhenBrewing: UISwitch!
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
    @IBAction func warmupDurationChanged(_ sender: UISlider) {
        update_value("warmupDuration", String(format: "%.0f", sender.value))
    }
    
    @IBAction func warmupAddedBoilerPowerChanged(_ sender: UISlider) {
        update_value("warmupAddedBoilerPower", String(format: "%.0f", sender.value))
    }
    
    @IBAction func warmupPumpPowerChanged(_ sender: UISlider) {
        update_value("warmupPumpPower", String(format: "%.0f", sender.value))
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
    @IBAction func plotsStartAtNonZeroWeightChanged(_ sender: UISwitch) {
        update_value("plotsStartAtNonZeroWeight", String(sender.isOn))
    }
    
    @IBAction func disablePIDWhenBrewingChanged(_ sender: UISwitch) {
        update_value("disablePIDWhenBrewing", String(sender.isOn))
    }
    
}
