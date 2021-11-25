# OhMyShot: Automate your espresso machine!

OhMyShot! is an iOS app that supercharges your classic espresso machine.
It provides
* gravimetric control
* a shot timer
* advanced pressure profiles
* data analysis

and more! See the following video for a short introduction.

It requires a coffee machine with [the meCoffee (BLE version) installed](https://mecoffee.nl), and a bluetooth scale. As such it has the potential of supporting the Rancilio Silvia, Gaggia classic, and Vibiemme Domobar coffe machines.

See the following video for a quick introduction, and the following post at CoffeeForums.co.uk.

## Installation
The app is still under development and has not been tested thoroughly. Before using the repo, read its disclaimer below.

The repo uses [cocoa-pods for its dependencies](https://guides.cocoapods.org/using/getting-started.html). Upon downloading, run
```
pods install
```
to install the project's dependency, [AAChartKit-Swift](https://github.com/AAChartModel/AAChartKit-Swift). You can then proceed to compile and upload to your device.

Before using the repo, make sure you have **disabled the pre-infusion of meCoffee** using the me/uBarista app.

## Troubleshooting
The app currently assumes a meCoffee controller and a Felicita scale with [certain names, services, and characteristics](https://github.com/nrontsis/OhMyShot/blob/main/OhMyShot!/Hardware/bluetooth.swift#L5-L15).
You might have to modify them to match your own hardware. You can find the details of your BLE devices via e.g. the [LightBlue iOS app](https://punchthrough.com/lightblue-features/).

Future work includes supporting the Acaia, Decent and Skale bluetooth scales, which should be straighforward (just have to implement [this interface](https://github.com/nrontsis/OhMyShot/blob/main/OhMyShot!/Controller/brew_controller.swift#L20-L28) similarly to the [one for Felicita](https://github.com/nrontsis/OhMyShot/blob/main/OhMyShot!/Hardware/felicita_interface.swift)).

## Disclaimer
Note that the software is pre-release and under development.
It has only been **partially** tested on the following hardware setup: 
* Rancilio Silvia V6;
* meCoffee BLE controller (bought at 2021);
* Felicita scale.

No test has been performed on any other hardware. No responsibility or warranty is provided, as described in [the license file of this repo](https://github.com/nrontsis/OhMyShot/blob/main/LICENSE).

Before using it, on the same or different setups, you have to make sure that you have a thorough understanding of how your espresso machine works
and the risks of tampering with **electrical, pressurized, and high-temperature** systems.

## License and Acknowledgments
The [icons](https://www.behance.net/gallery/43384887/FREE-COFFEE-ICONS/modules/275833981) of the app are from the [designer "AomAom"](https://www.behance.net/iamaomam). They are free under a ["Attribution-NonCommercial-NoDerivatives 4.0 International (CC BY-NC-ND 4.0)" license](https://creativecommons.org/licenses/by-nc-nd/4.0/deed.en_US).

The code is distributed under [a GPLv2 license](https://github.com/nrontsis/OhMyShot/blob/main/LICENSE). Although the intention was to use a more permissive license, this work was partly based on [the source code of the meBarista app](https://git.mecoffee.nl/meBarista/meBarista_for_Android) that comes under [GPLv2 license](https://git.mecoffee.nl/meBarista/meBarista_for_Android/src/master/LICENSE.txt).

The C code, that relates to smoothing functionality via splines, was copied from the [GR Repo](https://github.com/sciapp/gr/blob/5adf47853b9c12128ac06bfe8fec19f4ea645506/lib/gr/spline.c), that is licensed under an [MIT license](https://github.com/sciapp/gr/blob/master/LICENSE.md).

Finally, the [btscale repo](https://github.com/fako1024/btscale) was very useful for the development of the bluetooth connectivity to the Felicita scale.

