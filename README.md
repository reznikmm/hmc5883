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
- Configure the sensor (average count, gain, self-test bias)
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
   package HMC5883_I2C is new HCM5883.Sensor
     (I2C_Port => STM32.Device.I2C_1'Access);

begin
   if HMC5883_I2C.Check_Chip_Id then
      ...
```

While declaring object of the tagged type looks like this:

```ada
declare
   Sensor : HMC5883.Sensors.HMC5883_Sensor
     (I2C_Port => STM32.Device.I2C_1'Access);
begin
   if Sensor.Check_Chip_Id then
      ...
```

### Sensor Configuration

To configure the sensor, use the Configure procedure by passing the settings
(`Sensor_Configuration` type).

Settings include:

- `Average`: Return the average value from the last 8, 4, 2, or 1
  measurements. This setting does not affect the measurement frequency.

- `ODR` (Output Data Rate): Desired measurement frequency from a predefined
  list of values. Only applicable in Continuous-Measurement Mode.

- `Gain`: Sensor sensitivity from a predefined list of values.

- `Bias`: Switch between normal mode and self-test mode. In self-test mode,
  the induced field is measured. This mode can be used for sensor
  verification or calculating the temperature influence on sensor readings.

### Sensor Mode

Change the sensor mode using the `Set_Mode` procedure by passing one of three
values: `Continuous_Measurement`, `Single_Measurement`, `Idle`.

In `Single_Measurement` mode, the sensor performs one measurement and then
enters `Idle`. The other two modes need to be changed manually.

The best way to determine data readiness is through interrupts using
a separate pin. Otherwise you can ascertain that the data is ready by
monitoring the sensor's registers, specifically by observing the
`Is_Writing` status. This value briefly becomes `True` (250 μs),
and when it becomes `False` again, new data can be read.

Another option is to initiate a single measurement using
`Single_Measurement` mode and read the data after >1/160s.

### Read Measurement

Read raw data (as provided by the sensor) with the `Read_Raw_Measurement`
procedure.

Calling `Read_Measurement` returns scaled measurements in Gauss based on
the current Gain setting.

The sensor signals overflow for each axis separately.

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
- [Advanced example for STM32 F4VE board and LCD & touch panel](examples/hmc5883_lcd) -
  complete example of the tagged type usage.
