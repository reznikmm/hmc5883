--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with HAL.Time;

generic
   type Device_Context (<>) is limited private;

   with procedure Read
     (Device  : Device_Context;
      Data    : out HAL.UInt8_Array;
      Success : out Boolean);
   --  Read the values from the HMC5883L chip registers into Data.
   --  Each element in the Data corresponds to a specific register address
   --  in the chip, so Data'Range determines the range of registers to read.
   --  The value read from register X will be stored in Data(X), so
   --  Data'Range should be of the Register_Address subtype.

   with procedure Write
     (Device  : Device_Context;
      Data    : HAL.UInt8_Array;
      Success : out Boolean);
   --  Write the Data values to the HMC5883L chip registers.
   --  Each element in the Data corresponds to a specific register address
   --  in the chip, so Data'Range determines the range of registers to write.
   --  The value read from Data(X) will be stored in register X, so
   --  Data'Range should be of the Register_Address subtype.

package HMC5883.Internal is

   function Check_Chip_Id (Device : Device_Context) return Boolean;
   --  Read the chip ID and check that it matches

   procedure Configure
     (Device  : Device_Context;
      Value   : Sensor_Configuration;
      Success : out Boolean);
   --  Write Configuration Registers (00, 01)

   procedure Set_Mode
     (Device  : Device_Context;
      Mode    : Operating_Mode;
      Success : out Boolean);
   --  Write Mode Register (02)

   function Measuring (Device  : Device_Context) return Boolean;
   --  Check Status Register (09)

   --  procedure Read_Measurement
   --    (Device  : Device_Context;
   --     GFSR    : Gyroscope_Full_Scale_Range;
   --     AFSR    : Accelerometer_Full_Scale_Range;
   --     Gyro    : out Angular_Speed_Vector;
   --     Accel   : out Acceleration_Vector;
   --     Success : out Boolean);
   --  Read scaled measurement values from the sensor

   procedure Read_Raw_Measurement
     (Device  : Device_Context;
      Value   : out Raw_Vector;
      Success : out Boolean);
   --  Read the raw measurement values from the sensor

end HMC5883.Internal;
