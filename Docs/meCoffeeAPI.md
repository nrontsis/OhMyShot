## meCoffee messages
The meCoffee board emits the following messages:
```
b'pid -8175 13107 0 0 OK\r\n'
```
at a frequency equal to the `pd1sz` setting listed below. The four numbers on these messages are for the "P", "I", "D" and "Active" (i.e. feed-forward) parts of the boiler power. They are expressed in percentage of maximum power times the `655.36` constant.

Furthermore, temperature is reported every second via the following messages:
```
b'tmp 404 10200 10537 0 OK\r\n'
```
The first number corresponds to the number of seconds since the coffee machine has been on, the second to the boiler temperature set-point, the third to the current boiler temperature and the last one is reserved for auxiliary sensor measurements.

When a shot starts, a message like the following is emitted:
```
b'sht 406 0 OK\r\n'
```
and when a shot finishes, a message like so:
```
b'sht 406 25000 OK\r\n'
```
where the last number on the above message corresponds to the shot duration. The first number is, again, seconds since the coffee machine has been on.

As a result, one can detect the start of a shot either by the two above messages, or by the presence of a non-zero "Active PID" power in the `pid` messages. The former is more explicit, but the latter might have less latency, because the `sht` messages are reported once every second, while the `pid` messages with a frequency equal to `pd1sz`.

These messages are sometimes be split in more than one BLE messages. Each BLE message, however, contains data from only one string message. For example:
```
message #1 -> b'pid -7900 13107 0 39'
message #2 -> b'32 OK\r\n'
message #3 -> b'sht 406 1110 OK\r\n'
```

### List of meCoffee settings:  
By sending the following command to meCoffee
```
b'\ncmd dump OK\n'
```
to the following
we obtain the following list of all the settings of the meCoffee platform. A description for each of them was derived from [this file](https://git.mecoffee.nl/meBarista/meBarista_for_Android/src/master/res/xml/preference.xml) and by manual experimentation.
As an example, we can change the boiler temperature to 105 degrees by sending the following command:
```
b'\ncmd set tmpsp 10500 OK\n'
```
meCoffee that will respond that the setting was applied successfully with the following message:
```
b'cmd set tmpsp 10500 OK\r\n'
```

| Setting   | Example value | Description              |
|-----------|--------------|--------------------------|
| tmpsp     | 10100        | Temperature setpoint [°C/100]    |
| tmpstm    | 13000        | Steam temperature setpoint [°C/100] |
| pd1p      | 25           | PID "P" gain [0-100]                  |
| pd1i      | 30           | PID "D" gain [0-1000 - scaled by 0.01 in meBarista iOS] |
| pd1d      | 128          | PID "I" gain [0-300]                 |
| pd1imn    | 0            | PID "I" gain "wind-up" minimum [%/655.36] |
| pd1imx    | 13107        | PID "I" gain "wind-up" maximum [%/655.36]      |
| pd1sz     | 1000         | Polling interval for PID power [ms] |
| tmpcntns  | 1            | Continuous boiler control [0 or 1] |
| tmppap    | 20           | Active PID [%]           |
| pinbl     | 1            | Preinfusion enabled [0 or 1] |
| pistrt    | 10000        | Preinfusion time [ms]    |
| piprd     | 20000        | Preinfusion rest time [ms]       |
| pivlv     | 0            | Release pressure when resting [0 or 1] **See grnd below** |
| grnd      | 1000         | Must be equal 1000 when pivlv == 0 else 0 |
| pp1       | 42           | Pressure start [%]       |
| pp2       | 100          | Pressure end [%]         |
| ppt       | 30           | Presure ramp time [s]    |
| shtmx     | 60           | Maximum shot time [s]    |
| tmrwnbl   | 0            | Wakeup timer enabled [0 or 1] |
| tmrsnbl   | 0            | Shutdown timer enabled [0 or 1] |
| tmrosdnbl | 0            | Inactivity timer enabled [0 or 1] |
| tmrosd    | 60           | Inactivity time threshold [minutes] |
| tmron     | 0            | Wakeup time [0 or 24h-style HH:MM] |
| tmroff    | 0            | Shutdown time [0 or 24h-style HH:MM] |
| tmrpwr    | 0            | Installed as a timer [0 or 1] |
| pwrflp    | 0            | Is power button flipping (V5+) style? [0 or 1]|
| o0        | 112          | Output 1 (NEUTRAL) mapping: [98 for Boiler, 112 for Pump, 118 for Valve, 110 for None] |
| o1        | 98           | Output 2 (LIVE) mapping: [same as o0] |
| o2        | 118          | Output 3 (LIVE) mapping: [same as o0] |
| cntgrndr  | 0            | Legacy counter for grinder [non-negative integer] |
| pd1lck    | 120          | ?                        |
| s1nb      | 0            | ?                        |
| s2cr      | 0            | ?                        |
| btstp     | 42           | ?                        |
