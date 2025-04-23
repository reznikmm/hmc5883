--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

--  This package offers a straightforward method for setting up the HMC5883L
--  when connected via I2C, especially useful when you need multiple sensors
--  of this kind. If you use only one sensor, it could be preferable to use the
--  HMC5883L.Sensor generic package.

with HAL.I2C;

package HMC5883.Sensors is

   type HMC5883_Sensor
     (I2C_Port : not null HAL.I2C.Any_I2C_Port) is tagged limited private;

   function Check_Chip_Id (Self : HMC5883_Sensor) return Boolean;
   --  Read the chip ID and check that it matches the expected value.

   procedure Configure
     (Self    : in out HMC5883_Sensor;
      Value   : Sensor_Configuration;
      Success : out Boolean);
   --  Setup sensor configuration, including
   --  * number of samples averaged (1 to 8) per measurement output
   --  * the rate at which data is written to data output registers
   --  * the gain for the device

   procedure Set_Mode
     (Self    : HMC5883_Sensor;
      Mode    : Operating_Mode;
      Success : out Boolean);
   --  Select the operating mode of the device.

   function Is_Idle (Self : HMC5883_Sensor) return Boolean;
   --  Check if the operating mode is idle

   function Is_Writing (Self : HMC5883_Sensor) return Boolean;
   --  The sensor is busy with writing new measurement into registers

   procedure Read_Measurement
     (Self    : HMC5883_Sensor;
      Value   : out Optional_Magnetic_Field_Vector;
      Success : out Boolean);
   --  Read scaled measurement values from the sensor

   procedure Read_Raw_Measurement
     (Self    : HMC5883_Sensor;
      Value   : out Raw_Vector;
      Success : out Boolean);
   --  Read the raw measurement values from the sensor

private

   type HMC5883_Sensor
     (I2C_Port : not null HAL.I2C.Any_I2C_Port) is tagged limited
   record
      Gain : Natural range 0 .. 7 := 1;
   end record;

end HMC5883.Sensors;
