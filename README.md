# HMC5883

[![Build status](https://github.com/reznikmm/hmc5883/actions/workflows/alire.yml/badge.svg)](https://github.com/reznikmm/hmc5883/actions/workflows/alire.yml)
[![Alire](https://img.shields.io/endpoint?url=https://alire.ada.dev/badges/hmc5883.json)](https://alire.ada.dev/crates/hmc5883.html)
[![REUSE status](https://api.reuse.software/badge/github.com/reznikmm/hmc5883)](https://api.reuse.software/info/github.com/reznikmm/hmc5883)

> Driver for HMC5883L magnetic sensor.

- [Datasheet](https://cdn.sparkfun.com/datasheets/Sensors/Magneto/HMC5883L-FDS.pdf)

The sensor is available as a module for DIY projects from various
manufacturers, such as
[SparkFun](https://www.sparkfun.com/products/retired/10530),
[DfRobot](https://www.dfrobot.com/product-535.html)
or [GY-271](https://www.aliexpress.com/item/1005006291063452.html).
It boasts 5 milli-gauss resolution, low power consumption, a compact size,
and up to 160 Hz output rate.

The HMC5883L driver enables the following functionalities:

- Detect the presence of the sensor.
- Perform a reset operation.
- Configure XXX...
- Conduct measurements as raw 12-bit values and scaled values.

## Install

Add `hmc5883` as a dependency to your crate with Alire:

    alr with hmc5883

## Usage

The driver implements two usage models: the generic package, which is more
convenient when dealing with a single sensor, and the tagged type, which
allows easy creation of objects for any number of sensors and uniform handling.

Generic instantiation looks like this:

```ada
declare
   package HMC5883_I2C is new HCM5883.I2C
     (I2C_Port => STM32.Device.I2C_1'Access);

begin
   if HMC5883_I2C.Check_Chip_Id then
      ...
```

While declaring object of the tagged type looks like this:

```ada
declare
   Sensor : HMC5883.I2C_Sensors.HMC5883_I2C_Sensor :=
     (I2C_Port => STM32.Device.I2C_1'Access);
begin
   if Sensor.Check_Chip_Id then
      ...
```

## Examples

You need `Ada_Drivers_Library` in `adl` directory. Clone it then run Alire
to build:

    git clone https://github.com/AdaCore/Ada_Drivers_Library.git adl
    cd examples
    alr build

### GNAT Studio

Launch GNAT Studio with Alire:

    cd examples; alr exec gnatstudio -- -P hmc5883_put/hmc5883_put.gpr

### VS Code

Make sure `alr` in the `PATH`.
Open the `examples` folder in VS Code. Use pre-configured tasks to build
projects and flash (openocd or st-util). Install Cortex Debug extension
to launch pre-configured debugger targets.

- [Simple example for STM32 F4VE board](examples/hmc5883_put) - complete
  example for the generic instantiation.
