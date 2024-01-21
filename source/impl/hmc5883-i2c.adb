--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

pragma Ada_2022;

with HMC5883.Internal;

package body HMC5883.I2C is

   I2C_Address : constant := 16#1E#;

   type Chip_Settings is record
      Gain : Natural range 0 .. 7 := 1;
   end record;

   Chip : Chip_Settings;

   procedure Read
     (Ignore  : Chip_Settings;
      Data    : out HAL.UInt8_Array;
      Success : out Boolean);
   --  Read registers starting from Data'First

   procedure Write
     (Ignore  : Chip_Settings;
      Data    : HAL.UInt8_Array;
      Success : out Boolean);
   --  Write registers starting from Data'First

   package Sensor is new Internal (Chip_Settings, Read, Write);

   -------------------
   -- Check_Chip_Id --
   -------------------

   function Check_Chip_Id return Boolean is (Sensor.Check_Chip_Id (Chip));

   ---------------
   -- Configure --
   ---------------

   procedure Configure
     (Value   : Sensor_Configuration;
      Success : out Boolean)
   is
      Gain : Natural range 0 .. 7;
   begin
      Sensor.Configure (Chip, Value, Gain, Success);
      Chip.Gain := Gain;
   end Configure;

   -------------
   -- Is_Idle --
   -------------

   function Is_Idle return Boolean is (Sensor.Is_Idle (Chip));

   ----------------
   -- Is_Writing --
   ----------------

   function Is_Writing return Boolean is (Sensor.Is_Writing (Chip));

   ----------
   -- Read --
   ----------

   procedure Read
     (Ignore  : Chip_Settings;
      Data    : out HAL.UInt8_Array;
      Success : out Boolean)
   is
      use type HAL.I2C.I2C_Status;
      use type HAL.UInt10;

      Status : HAL.I2C.I2C_Status;
   begin
      I2C_Port.Mem_Read
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
     (Value   : out Magnetic_Field_Vector;
      Success : out Boolean) is
   begin
      Sensor.Read_Measurement (Chip, Chip.Gain, Value, Success);
   end Read_Measurement;

   --------------------------
   -- Read_Raw_Measurement --
   --------------------------

   procedure Read_Raw_Measurement
     (Value   : out Raw_Vector;
      Success : out Boolean) is
   begin
      Sensor.Read_Raw_Measurement (Chip, Value, Success);
   end Read_Raw_Measurement;

   --------------
   -- Set_Mode --
   --------------

   procedure Set_Mode
     (Mode    : Operating_Mode;
      Success : out Boolean) is
   begin
      Sensor.Set_Mode (Chip, Mode, Success);
   end Set_Mode;

   -----------
   -- Write --
   -----------

   procedure Write
     (Ignore  : Chip_Settings;
      Data    : HAL.UInt8_Array;
      Success : out Boolean)
   is
      use type HAL.I2C.I2C_Status;
      use type HAL.UInt10;

      Status : HAL.I2C.I2C_Status;
   begin
      if Data'Length = 0 then
         I2C_Port.Master_Transmit
           (Addr          => 2 * HAL.UInt10 (I2C_Address),
            Data          => [HAL.UInt8 (Data'First)],
            Status        => Status);
      else
         I2C_Port.Mem_Write
           (Addr          => 2 * HAL.UInt10 (I2C_Address),
            Mem_Addr      => HAL.UInt16 (Data'First),
            Mem_Addr_Size => HAL.I2C.Memory_Size_8b,
            Data          => Data,
            Status        => Status);
      end if;

      Success := Status = HAL.I2C.Ok;
   end Write;

end HMC5883.I2C;
