--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with HMC5883.Internal;

package body HMC5883.Sensors is

   procedure Read
     (Self    : HMC5883_Sensor'Class;
      Data    : out HAL.UInt8_Array;
      Success : out Boolean);

   procedure Write
     (Self    : HMC5883_Sensor'Class;
      Data    : HAL.UInt8_Array;
      Success : out Boolean);

   package Sensor is new Internal (HMC5883_Sensor'Class, Read, Write);

   -------------------
   -- Check_Chip_Id --
   -------------------

   function Check_Chip_Id (Self : HMC5883_Sensor) return Boolean is
      (Sensor.Check_Chip_Id (Self));

   ---------------
   -- Configure --
   ---------------

   procedure Configure
     (Self    : in out HMC5883_Sensor;
      Value   : Sensor_Configuration;
      Success : out Boolean) is
   begin
      Sensor.Configure (Self, Value, Self.Gain, Success);
   end Configure;

   -------------
   -- Is_Idle --
   -------------

   function Is_Idle (Self : HMC5883_Sensor) return Boolean is
      (Sensor.Is_Idle (Self));

   ----------------
   -- Is_Writing --
   ----------------

   function Is_Writing (Self : HMC5883_Sensor) return Boolean is
      (Sensor.Is_Writing (Self));

   ----------
   -- Read --
   ----------

   procedure Read
     (Self    : HMC5883_Sensor'Class;
      Data    : out HAL.UInt8_Array;
      Success : out Boolean)
   is
      use type HAL.I2C.I2C_Status;
      use type HAL.UInt10;

      Status : HAL.I2C.I2C_Status;
   begin
      Self.I2C_Port.Mem_Read
        (Addr          => 2 * HAL.UInt10 (I2C_Address),
         Mem_Addr      => HAL.UInt16 (Data'First),
         Mem_Addr_Size => HAL.I2C.Memory_Size_8b,
         Data          => Data,
         Status        => Status);

      Success := Status = HAL.I2C.Ok;
   end Read;

   ----------------------
   -- Read_Measurement --
   ----------------------

   procedure Read_Measurement
     (Self    : HMC5883_Sensor;
      Value   : out Magnetic_Field_Vector;
      Success : out Boolean) is
   begin
      Sensor.Read_Measurement (Self, Self.Gain, Value, Success);
   end Read_Measurement;

   --------------------------
   -- Read_Raw_Measurement --
   --------------------------

   procedure Read_Raw_Measurement
     (Self    : HMC5883_Sensor;
      Value   : out Raw_Vector;
      Success : out Boolean) is
   begin
      Sensor.Read_Raw_Measurement (Self, Value, Success);
   end Read_Raw_Measurement;

   --------------
   -- Set_Mode --
   --------------

   procedure Set_Mode
     (Self    : HMC5883_Sensor;
      Mode    : Operating_Mode;
      Success : out Boolean) is
   begin
      Sensor.Set_Mode (Self, Mode, Success);
   end Set_Mode;

   -----------
   -- Write --
   -----------

   procedure Write
     (Self    : HMC5883_Sensor'Class;
      Data    : HAL.UInt8_Array;
      Success : out Boolean)
   is
      use type HAL.I2C.I2C_Status;
      use type HAL.UInt10;

      Status : HAL.I2C.I2C_Status;
   begin
      Self.I2C_Port.Mem_Write
        (Addr          => 2 * HAL.UInt10 (I2C_Address),
         Mem_Addr      => HAL.UInt16 (Data'First),
         Mem_Addr_Size => HAL.I2C.Memory_Size_8b,
         Data          => Data,
         Status        => Status);

      Success := Status = HAL.I2C.Ok;
   end Write;

end HMC5883.Sensors;
