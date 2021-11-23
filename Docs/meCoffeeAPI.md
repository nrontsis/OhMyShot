
### List of meCoffee settings:  
By sending the following command to meCoffee
```
"\ncmd dump OK\n"
```
to the following
we obtain the following list of all the settings of the meCoffee platform. A description for each of them was derived from [this file](https://git.mecoffee.nl/meBarista/meBarista_for_Android/src/master/res/xml/preference.xml) and by manual experimentation.
As an example, we can change the boiler temperature to 105 degrees by sending the following command:
```
"\ncmd set tmpsp 10500 OK\n"
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
| pd1sz     | 1000         | Polling interval (for controller?) [ms] |
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
