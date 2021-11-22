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
        updateCharts()
    }
    
    func received_scale_message(data: Data) {
        recreate_controller_if_necessary(data)
        controller!.process_scale_message(message: data)
        weightLabel.text = String(format: "%.1f", controller!.current_brew_weight) + " g"
    }
    
    func received_coffee_machine_message(data: Data) {
        recreate_controller_if_necessary(data)
        controller!.process_coffee_machine_message(message: data)
        controllerTypeSelection.isEnabled = !controller!.brewing
        temperatureLabel.text = String(format: "%.2f", controller!.coffee_machine_temperature) + " °C"
        coffeeMachineRuntime.text = "\(Int(round(controller!.minutes_since_coffee_machine_power_on)))m"
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
            "Warmup": PlainBrewController.self,
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
            coffee_machine: coffee_machine_interface,
            desired_brew_weight: setting("desiredBrewWeight")
        )
    }
    
    func updateCharts() {
        /*
        let chart = create_past_shots_chart(
            width: plotView.frame.width, height: plotView.frame.height, show_rate: plotStyle!.selectedSegmentIndex == 0
        )
        chart.delegate = self
        plotView.addSubview(chart)
        */
    }
    
    @IBOutlet weak var plotView: UIView!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var coffeeMachineRuntime: UILabel!
    @IBOutlet weak var desiredBrewWeightLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    @IBAction func desiredBrewWeightChanged(_ sender: UISlider) {
        let value = String(format: "%.1f", sender.value)
        desiredBrewWeightLabel.text = value + " g"
        save_setting("desiredBrewWeight", value, should_reload: false)
        controller?.desired_brew_weight = Double(value)!
    }
    @IBOutlet weak var plotStyle: UISegmentedControl!
    @IBAction func controllerTypeChanged(_ sender: UISegmentedControl) {
        let mode = sender.titleForSegment(at: sender.selectedSegmentIndex)
        save_setting("controllerType", mode!)
    }
    @IBOutlet weak var controllerTypeSelection: UISegmentedControl!
    @IBOutlet weak var desiredBrewWeightSlider: UISlider!
    @IBAction func refreshPlot(_ sender: Any) { updateCharts() }
    @IBAction func plotStyleChanged(_ sender: Any) { updateCharts() }
}




extension MainUIController: AAChartViewDelegate {
    open func aaChartViewDidFinishLoad(_ aaChartView: AAChartView) {
       for i in 2...3 {
           aaChartView.aa_hideTheSeriesElementContentWithSeriesElementIndex(i)
       }
    }
}
