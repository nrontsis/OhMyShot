import UIKit
import UserNotifications
import AAInfographics


class MainUIController: UIViewController {
    var ble_controller = BluetoothController()
    var controller: BrewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ble_controller.scale_message_callback = self.received_scale_message
        ble_controller.coffe_machine_message_callback = self.received_coffee_machine_message
        controller = recreate_controller()
        desiredBrewWeightSlider.value = Float(setting("desiredBrewWeight"))
        desiredBrewWeightChanged(desiredBrewWeightSlider)
        for i in 0..<controllerTypeSelection.numberOfSegments {
            if string_setting("controllerType") == controllerTypeSelection.titleForSegment(at: i) {
                controllerTypeSelection.selectedSegmentIndex = i
            }
        }
        if saved_shots_exist() { plotView.isHidden = true}
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.updateCharts() }
    }
    
    func received_scale_message(data: Data) {
        recreate_controller_if_necessary(data)
        controller!.process_scale_message(message: data)
        update_info_label(weight: controller!.current_brew_weight)
    }
    
    func received_coffee_machine_message(data: Data) {
        recreate_controller_if_necessary(data)
        controller!.process_coffee_machine_message(message: data)
        controllerTypeSelection.isEnabled = !controller!.brewing
        update_info_label(
            temperature: controller!.coffee_machine_temperature,
            runtime: controller!.minutes_since_coffee_machine_power_on
        )
    }
    
    func recreate_controller_if_necessary(_ msg: Data) {
        let controller_type = type(of: controller!)
        let reset_for_settings_change = is_true("shouldReloadSettings") && !controller!.brewing
        let reset_for_new_device = (msg == CONNECTED && controller_type == NoActionBrewController.self)
        let reset_for_mecoffee_disconnected = (msg == DISCONNECTED_MECOFFEE)
        let reset_for_scale_disconnected = (msg == DISCONNECTED_SCALE && controller_type.requires_scale())
        
        if reset_for_settings_change || reset_for_new_device || reset_for_mecoffee_disconnected || reset_for_scale_disconnected {
            save_setting("shouldReloadSettings", "false")
            controller = recreate_controller()
        }
    }
    
    func recreate_controller() -> BrewController {
        var controller_type = [
            "Profiled": ProfiledBrewController.self,
            "Plain": PlainBrewController.self,
            "Warmup": WarmupCoffeeController.self,
            "Backflush": BackFlushingBrewController.self,
        ][string_setting("controllerType")]!
        let coffee_machine_interface = ble_controller.create_coffee_machine_interface()
        let scale_interface = ble_controller.create_scale_interface()
        
        if !coffee_machine_interface.can_send() || (controller_type.requires_scale() && !scale_interface.can_send()) {
            controller_type = NoActionBrewController.self
            statusLabel.textColor = UIColor.red
        }
        else {
            statusLabel.textColor = UIColor.green
        }
        return controller_type.init(
            scale: scale_interface,
            coffee_machine: coffee_machine_interface
        )
    }
    
    func updateCharts() {
        if !saved_shots_exist() { return }
        plotView.isHidden = false
        if let chart = plotView.subviews.last as? AAChartView {
            chart.removeFromSuperview()
        }
        let chart = create_past_shots_chart(
            parent_frame: plotView.frame,
            units: plotStyle!.selectedSegmentIndex == 0 ? "g/s" : "g"
        )
        chart.delegate = self
        plotView.addSubview(chart)
    }
    
    @IBOutlet weak var plotView: UIView!
    @IBOutlet weak var desiredBrewWeightLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBAction func desiredBrewWeightChanged(_ sender: UISlider) {
        let value = String(format: "%.1f", sender.value)
        desiredBrewWeightLabel.text = value + " g"
        save_setting("desiredBrewWeight", value, should_reload: false)
    }
    @IBOutlet weak var plotStyle: UISegmentedControl!
    @IBAction func controllerTypeChanged(_ sender: UISegmentedControl) {
        let mode = sender.titleForSegment(at: sender.selectedSegmentIndex)
        save_setting("controllerType", mode!)
    }
    
    func update_info_label(temperature: Double? = nil, runtime: Double? = nil, weight: Double? = nil) {
        let info = infoLabel.text!
        var runtime_str = String(info[...info.firstIndex(of: "⌛")!])
        var temperature_str = String(info[info.firstIndex(of: "⌛")!...info.firstIndex(of: "🌡")!].dropFirst())
        var weight_str = String(info[info.firstIndex(of: "🌡")!...].dropFirst())
        
        let is_valid: (Double?) -> Bool = {$0 != nil && !$0!.isNaN}
        if is_valid(runtime) { runtime_str = String(format:"%2.0fm ⌛", runtime!) }
        if is_valid(temperature) { temperature_str = String(format:" %5.1f°C 🌡", temperature!) }
        if is_valid(weight) { weight_str = String(format:" %4.1fg ⚖️", weight!) }
        
        infoLabel.text = runtime_str + temperature_str + weight_str
    }
    @IBOutlet weak var controllerTypeSelection: UISegmentedControl!
    @IBOutlet weak var desiredBrewWeightSlider: UISlider!
    @IBAction func refreshPlot(_ sender: Any) {
        updateCharts()
    }
    @IBAction func helpButtonClicked(_ sender: Any) {
        if let chart = plotView.subviews.last as? AAChartView {
            chart.removeFromSuperview()
        }
    }
    @IBAction func plotStyleChanged(_ sender: Any) { updateCharts() }
}




extension MainUIController: AAChartViewDelegate {
    open func aaChartViewDidFinishLoad(_ aaChartView: AAChartView) {
       for i in 2..<number_of_shots_saved {
           aaChartView.aa_hideTheSeriesElementContentWithSeriesElementIndex(i)
       }
    }
}

extension String {
    func subString(from: Int, to: Int) -> String {
       let startIndex = self.index(self.startIndex, offsetBy: from)
       let endIndex = self.index(self.startIndex, offsetBy: to)
       return String(self[startIndex..<endIndex])
    }
}
