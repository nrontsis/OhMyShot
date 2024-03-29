import Foundation
import CoreBluetooth


let MECOFFEE_BLE_NAME = "meCoffee"
let SCALE_BLE_NAME = "FELICITA"
let CHARACTERISTICS_CBUUIDS = [
    MECOFFEE_BLE_NAME: "0000ffe1-0000-1000-8000-00805f9b34fb",
    SCALE_BLE_NAME: "0000ffe1-0000-1000-8000-00805f9b34fb",
]
let SERVICES_CBUUIDS = [
    MECOFFEE_BLE_NAME: "0000ffe0-0000-1000-8000-00805f9b34fb",
    SCALE_BLE_NAME: "0000ffe0-0000-1000-8000-00805f9b34fb",
]


let CONNECTED = "CONNECTED PERIPHERAL".data(using: .ascii)!
let DISCONNECTED_MECOFFEE = "DISCONNECTED MECOFEEE".data(using: .ascii)!
let DISCONNECTED_SCALE = "DISCONNECTED SCALE".data(using: .ascii)!


class BluetoothController: NSObject, CBPeripheralDelegate, CBCentralManagerDelegate {
    var coffe_machine_message_callback: ((_ data: Data) -> Void)?
    var scale_message_callback: ((_ data: Data) -> Void)?
    private let ble_manager: CBCentralManager
    private var peripherals: [String: CBPeripheral] = [:]
    private var characteristics: [String: CBCharacteristic] = [:]
    private var coffee_message_cache = ""
    private var latest_coffee_machine_command_acknowledgement = Data()

    override init() {
        ble_manager = CBCentralManager(delegate: nil, queue: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey:true])
        super.init()
        ble_manager.delegate = self
    }
    
    func create_scale_interface() -> ScaleInterface {
        func send_cmd(_ data: Data) -> Void {
            peripherals[SCALE_BLE_NAME]?.writeValue(
                data, for: characteristics[SCALE_BLE_NAME]!, type: .withResponse
            )
            usleep(100000)
        }
        return FelicitaInterface(send_command: characteristics[SCALE_BLE_NAME] != nil ? send_cmd: nil)
    }
    
    func create_coffee_machine_interface() -> CoffeeMachineInterface {
        func send_cmd(_ data: Data, _ expected_response: Data) -> Void {
            latest_coffee_machine_command_acknowledgement = Data()
            for attempt in 1...4 {
                if latest_coffee_machine_command_acknowledgement == expected_response || characteristics[MECOFFEE_BLE_NAME] == nil { break }
                if attempt > 1 {
                    print(
                        "BLE command failed to be acknowledged (attempt #\(attempt))",
                        [
                            String(data:latest_coffee_machine_command_acknowledgement, encoding: .ascii)!,
                            String(data:expected_response, encoding: .ascii)!
                        ],
                        latest_coffee_machine_command_acknowledgement == expected_response
                    )
                }
                latest_coffee_machine_command_acknowledgement = Data()
                peripherals[MECOFFEE_BLE_NAME]?.writeValue(data, for: characteristics[MECOFFEE_BLE_NAME]!, type: .withResponse)
                for _ in 1...attempt*30 { if latest_coffee_machine_command_acknowledgement == Data() { usleep(UInt32(10000)) }}
            }
        }
        return MeCoffeeInterface(send_command_with_expected_response: characteristics[MECOFFEE_BLE_NAME] != nil ? send_cmd: nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print([CBUUID(string: CHARACTERISTICS_CBUUIDS[peripheral.name!]!)])
        peripheral.services?.forEach{peripheral.discoverCharacteristics([CBUUID(string: CHARACTERISTICS_CBUUIDS[peripheral.name!]!)], for: $0)}
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let characteristic = service.characteristics![0]
        characteristics[peripheral.name!] = characteristic
        peripheral.setNotifyValue(true, for: characteristic)
        let callback = peripheral.name == MECOFFEE_BLE_NAME ? coffe_machine_message_callback : scale_message_callback
        callback?(CONNECTED)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if peripheral.name == MECOFFEE_BLE_NAME {
            let message = String(data: characteristic.value!, encoding: .ascii)!
            let components = message.components(separatedBy: "\n")
            for part in components.dropLast() {
                let full_message = coffee_message_cache + part + "\n"
                print(full_message)
                coffe_machine_message_callback?(full_message.data(using: .ascii)!)
                coffee_message_cache = ""
                if full_message.contains("cmd set s_") {
                    latest_coffee_machine_command_acknowledgement = full_message.data(using: .ascii)!
                }
            }
            coffee_message_cache = coffee_message_cache + components.last!
        }
        else if peripheral.name == SCALE_BLE_NAME {
            scale_message_callback?(characteristic.value!)
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: SERVICES_CBUUIDS.values.map{CBUUID(string: $0)})
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to:", peripheral.name!, " - Discovering services.")
        peripheral.discoverServices([CBUUID(string: SERVICES_CBUUIDS[peripheral.name!]!)])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect", peripheral.name ?? "[no name]")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("BLE Manager: disconnected \(peripheral.name!)")
        let callback = peripheral.name == MECOFFEE_BLE_NAME ? coffe_machine_message_callback : scale_message_callback
        characteristics.removeValue(forKey: peripheral.name!)
        callback?(peripheral.name == MECOFFEE_BLE_NAME ? DISCONNECTED_MECOFFEE : DISCONNECTED_SCALE)
        ble_manager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("BLE Manager: discovered \(peripheral), rssi: \(RSSI)")
        if [SCALE_BLE_NAME, MECOFFEE_BLE_NAME].contains(peripheral.name) {
            print("Connecting to", peripheral.name!)
            peripherals[peripheral.name!] = peripheral
            peripheral.delegate = self
            ble_manager.connect(peripheral, options: nil)
        }
    }
}
