# OhMyShot: Automate your espresso routine

OhMyShot is an iOS app that supercharges your old school espresso machine.
It provides gravimetric control, a shot timer, advanced pressure profiles, data analysis and more! See the following video for a short introduction.

It requires a coffee machine with meCoffee (BLE version) installed, and a bluetooth scale.

See the following video for a quick introduction, and the following post at CoffeeForums.co.uk.

## Installation
Before using the repo, make sure you have read its disclaimer below.


The repo uses [cocoa-pods for its dependencies](https://guides.cocoapods.org/using/getting-started.html). Upon downloading, run
```
pods installs
```
to install the project's dependencies.

You can then proceed to compile for your device.

## Troubleshooting
The app currently assumes a meCoffee controller and a Felicita scale with certain names, services, and characteristics.
You might have to modify them to match your own hardware. You can find the details of your BLE devices via e.g. the [LightBlue iOS app](https://punchthrough.com/lightblue-features/).

## Disclaimer:
Note that the software is pre-release and under development.
It has only been tested on the following hardware setup: 
* Rancilio Silvia V6;
* 2021 meCoffee BLE controller;
* Felicita scale.
No test has been performed on any other hardware.

Before using it, on the same or different setups, you have to make sure that you have a thorough understanding of how your espresso machine works
and the risks of tampering with **electrical, pressurized, and high-temperature** systems.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## License
The code is distributed under a GPLv2 license. Although the intention was to use a more permissive license, this work was partly based on [this work](https://git.mecoffee.nl/meBarista/meBarista_for_Android) that comes under GPLv2 license.

The icons of the app are from this [designer](https://www.behance.net/gallery/43384887/FREE-COFFEE-ICONS/modules/275833981).
