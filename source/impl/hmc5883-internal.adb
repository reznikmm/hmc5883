--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

pragma Ada_2022;

with Ada.Unchecked_Conversion;

package body HMC5883.Internal is

   I2C_Address : constant := 16#1E#;

   -------------------
   -- Check_Chip_Id --
   -------------------

   function Check_Chip_Id (Device : Device_Context) return Boolean is
      use type HAL.UInt8_Array;

      Ok   : Boolean;
      Data : HAL.UInt8_Array (10 .. 12);
   begin
      Read (Device, Data, Ok);

      return Ok and Data = [16#48#, 16#34#, 16#33#];
   end Check_Chip_Id;

   ---------------
   -- Configure --
   ---------------

   procedure Configure
     (Device  : Device_Context;
      Value   : Sensor_Configuration;
      Success : out Boolean)
   is
      use type HAL.UInt8;

      type CRA_Register is record
         MS       : Natural range 0 .. 3;
         DOR      : Natural range 0 .. 7;
         MA       : Natural range 0 .. 3;
         Reserved : Natural range 0 .. 0 := 0;
      end record;

      for CRA_Register use record
         MS       at 0 range 0 .. 1;
         DOR      at 0 range 2 .. 4;
         MA       at 0 range 5 .. 6;
         Reserved at 0 range 7 .. 7;
      end record;

      function Cast_CRA is new Ada.Unchecked_Conversion
        (CRA_Register, HAL.UInt8);

      type CRB_Register is record
         Reserved : Natural range 0 .. 0 := 0;
         GN       : Natural range 0 .. 3;
      end record;

      for CRB_Register use record
         Reserved at 0 range 0 .. 4;
         GN       at 0 range 5 .. 7;
      end record;

      function Cast_CRB is new Ada.Unchecked_Conversion
        (CRB_Register, HAL.UInt8);

      MA : constant Natural :=
        (case Value.Average is
            when 1 => 0,
            when 2 => 1,
            when 4 => 2,
            when 8 => 3);

      DOR : constant Natural :=
        (if    Value.ODR =  0.75 then 0
         elsif Value.ODR =  1.5  then 1
         elsif Value.ODR =  3.0  then 2
         elsif Value.ODR =  7.5  then 3
         elsif Value.ODR =  15.0 then 4
         elsif Value.ODR =  30.0  then 5
         else 6);

      GN : constant Natural :=
        (case Value.Gain is
            when 230  => 7,
            when 330  => 6,
            when 390  => 5,
            when 440  => 4,
            when 660  => 3,
            when 820  => 2,
            when 1090 => 1,
            when 1370 => 0);

      Data : constant HAL.UInt8_Array (00 .. 01) :=
        [00 => Cast_CRA ((MS => 0, DOR => DOR, MA => MA, Reserved => 0)),
         01 => Cast_CRB ((GN => GN, Reserved => 0))];
   begin
      Write (Device, Data, Success);
   end Configure;

   ---------------
   -- Measuring --
   ---------------

   function Measuring (Device : Device_Context) return Boolean is
      use type HAL.UInt8;

      Ok   : Boolean;
      Data : HAL.UInt8_Array (09 .. 09);
   begin
      Read (Device, Data, Ok);

      return Ok and (Data (Data'First) and 8) = 0;
    end Measuring;

   --------------
   -- Set_Mode --
   --------------

   procedure Set_Mode
     (Device  : Device_Context;
      Mode    : Operating_Mode;
      Success : out Boolean)
   is
      use type Interfaces.Integer_16;
   begin
      Write (Device, [02 => Operating_Mode'Pos (Mode)], Success);
   end Set_Mode;

   ------------------------------
   -- Set_Accelerometer_Offset --
   ------------------------------

   procedure Set_Accelerometer_Offset
     (Device  : Device_Context;
      Value   : Raw_Vector;
      Success : out Boolean)
   is
      use type Interfaces.Integer_16;

      Data_X : constant HAL.UInt8_Array (16#77# .. 16#78#) :=
        [HAL.UInt8 (Value.X / 256),
         HAL.UInt8 (Value.X mod 256)];
      Data_Y : constant HAL.UInt8_Array (16#7A# .. 16#7B#) :=
        [HAL.UInt8 (Value.Y / 256),
         HAL.UInt8 (Value.Y mod 256)];
      Data_Z : constant HAL.UInt8_Array (16#7D# .. 16#7E#) :=
        [HAL.UInt8 (Value.Z / 256),
         HAL.UInt8 (Value.Z mod 256)];
   begin
      Write (Device, Data_X, Success);

      if Success then
         Write (Device, Data_Y, Success);
      end if;

      if Success then
         Write (Device, Data_Z, Success);
      end if;
   end Set_Accelerometer_Offset;

   ----------------------
   -- Read_Measurement --
   ----------------------

   --  procedure Read_Measurement
   --    (Device  : Device_Context;
   --     GFSR    : Gyroscope_Full_Scale_Range;
   --     AFSR    : Accelerometer_Full_Scale_Range;
   --     Gyro    : out Angular_Speed_Vector;
   --     Accel   : out Acceleration_Vector;
   --     Success : out Boolean)
   --  is
   --     subtype Int is Integer range -2**15 .. 2**15 - 1;
   --     Raw : Raw_Vector;
   --  begin
   --     Read_Raw_Measurement
   --       (Device, Value => Raw, Success => Success);
   --
   --     if Success then
   --        case GFSR is
   --           when 250 =>
   --              Gyro :=
   --                (X => Int (Raw_G.X) * Scaled_Angular_Speed'Small,
   --                 Y => Int (Raw_G.Y) * Scaled_Angular_Speed'Small,
   --                 Z => Int (Raw_G.Z) * Scaled_Angular_Speed'Small);
   --           when 500  =>
   --              Gyro :=
   --                (X => 2 * Int (Raw_G.X) * Scaled_Angular_Speed'Small,
   --                 Y => 2 * Int (Raw_G.Y) * Scaled_Angular_Speed'Small,
   --                 Z => 2 * Int (Raw_G.Z) * Scaled_Angular_Speed'Small);
   --           when 1000  =>
   --              Gyro :=
   --                (X => 4 * Int (Raw_G.X) * Scaled_Angular_Speed'Small,
   --                 Y => 4 * Int (Raw_G.Y) * Scaled_Angular_Speed'Small,
   --                 Z => 4 * Int (Raw_G.Z) * Scaled_Angular_Speed'Small);
   --           when 2000 =>
   --              Gyro :=
   --                (X => 8 * Int (Raw_G.X) * Scaled_Angular_Speed'Small,
   --                 Y => 8 * Int (Raw_G.Y) * Scaled_Angular_Speed'Small,
   --                 Z => 8 * Int (Raw_G.Z) * Scaled_Angular_Speed'Small);
   --        end case;
   --     else
   --        Gyro := (others => 0.0);
   --        Accel := (others => 0.0);
   --     end if;
   --  end Read_Measurement;

   ----------------------
   -- Read_Measurement --
   ----------------------

   procedure Read_Raw_Measurement
     (Device  : Device_Context;
      Value   : out Raw_Vector;
      Success : out Boolean)
   is
      use Interfaces;

      function Cast is new Ada.Unchecked_Conversion
        (Unsigned_16, Integer_16);

      function Decode (Data : HAL.UInt8_Array) return Integer_16 is
         (Cast (Shift_Left (Unsigned_16 (Data (Data'First)), 8)
            + Unsigned_16 (Data (Data'Last))));

      Data : HAL.UInt8_Array (3 .. 8);
   begin
      Read (Device, Data, Success);

      if Success then
         Value.X := Decode (Data (3 .. 4));
         Value.Y := Decode (Data (5 .. 6));
         Value.Z := Decode (Data (7 .. 8));
      end if;
   end Read_Raw_Measurement;

end HMC5883.Internal;
