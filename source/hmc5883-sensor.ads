--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

--  This package offers a straightforward method for setting up the HMC5883L
--  when connected via I2C, especially useful when the use of only one sensor
--  is required. If you need multiple sensors, it is preferable to use the
--  HMC5883.I2C_Sensors package, which provides the appropriate tagged type.

with HAL.I2C;

generic
   I2C_Port : not null HAL.I2C.Any_I2C_Port;
package HMC5883.Sensor is

   function Check_Chip_Id return Boolean;
   --  Read the chip ID and check that it matches the expected value.

   procedure Configure
     (Value   : Sensor_Configuration;
      Success : out Boolean);
   --  Setup sensor configuration, including
   --  * number of samples averaged (1 to 8) per measurement output
   --  * the rate at which data is written to data output registers
   --  * the gain for the device

   procedure Set_Mode
     (Mode    : Operating_Mode;
      Success : out Boolean);
   --  Select the operating mode of the device.

   function Is_Idle return Boolean;
   --  Check if the operating mode is idle

   function Is_Writing return Boolean;
   --  The sensor is busy with writing new measurement into registers

   procedure Read_Measurement
     (Value   : out Optional_Magnetic_Field_Vector;
      Success : out Boolean);
   --  Read scaled measurement values from the sensor

   procedure Read_Raw_Measurement
     (Value   : out Raw_Vector;
      Success : out Boolean);
   --  Read the raw measurement values from the sensor

end HMC5883.Sensor;
