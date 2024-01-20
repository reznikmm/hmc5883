--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

--  This package offers a straightforward method for setting up the HMC5883L
--  when connected via I2C, especially useful when the use of only one sensor
--  is required. If you need multiple sensors, it is preferable to use the
--  HMC5883.I2C_Sensors package, which provides the appropriate tagged type.

with HAL.I2C;
with HAL.Time;

generic
   I2C_Port    : not null HAL.I2C.Any_I2C_Port;
   I2C_Address : HAL.UInt7 := 16#68#;  --  The HMC5883 7-bit I2C address
package HMC5883.I2C is

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

   function Measuring return Boolean;
   --  Check if a measurement is in progress

   --  procedure Read_Measurement
   --    (Value   : out Value_Vector;
   --     Success : out Boolean);
   --  Read scaled measurement values from the sensor

   procedure Read_Raw_Measurement
     (Value   : out Raw_Vector;
      Success : out Boolean);
   --  Read the raw measurement values from the sensor

end HMC5883.I2C;
