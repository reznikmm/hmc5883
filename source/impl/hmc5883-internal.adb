--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

pragma Ada_2022;

with Ada.Unchecked_Conversion;

package body HMC5883.Internal is

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
      Gain    : out Raw_Gain;
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
         GN       : Natural range 0 .. 7;
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

      MS : constant Natural := Self_Test_Bias'Pos (Value.Bias);

      GN : constant Raw_Gain :=
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
        [00 => Cast_CRA ((MS => MS, DOR => DOR, MA => MA, Reserved => 0)),
         01 => Cast_CRB ((GN => GN, Reserved => 0))];
   begin
      Write (Device, Data, Success);
      Gain := GN;
   end Configure;

   -------------
   -- Is_Idle --
   -------------

   function Is_Idle (Device  : Device_Context) return Boolean is
      use type HAL.UInt8;

      Ok   : Boolean;
      Data : HAL.UInt8_Array (02 .. 02);
   begin
      Read (Device, Data, Ok);

      return Ok and (Data (Data'First) and 2) /= 0;
   end Is_Idle;

   ----------------
   -- Is_Writing --
   ----------------

   function Is_Writing (Device : Device_Context) return Boolean is
      use type HAL.UInt8;

      Ok   : Boolean;
      Data : HAL.UInt8_Array (09 .. 09);
   begin
      Read (Device, Data, Ok);

      --  0 bit - Ready Bit. Set when data is written to all six data
      --  registers. Cleared when device initiates a write to the data output
      --  registers and after one or more of the data output registers are
      --  written to. When RDY bit is clear it shall remain cleared for a
      --  250 us

      return Ok and (Data (Data'First) and 1) = 0;
   end Is_Writing;

   ----------------------
   -- Read_Measurement --
   ----------------------

   procedure Read_Measurement
     (Device  : Device_Context;
      Gain    : Raw_Gain;
      Value   : out Optional_Magnetic_Field_Vector;
      Success : out Boolean)
   is
      subtype Valid is Valid_Raw_Value;

      type Int is delta 1.0 range -2048.0 .. 2047.0;

      Scale : constant Full_Scale_Range := Scale_Map (Gain);
      Raw   : Raw_Vector;
   begin
      Read_Raw_Measurement (Device, Raw, Success);

      if Success then
         Value :=
           (X => (if Raw.X in Valid then Scale * Int (Raw.X) else 0.0),
            Y => (if Raw.Y in Valid then Scale * Int (Raw.Y) else 0.0),
            Z => (if Raw.Z in Valid then Scale * Int (Raw.Z) else 0.0),
            Overflow => not
              (Raw.X in Valid and Raw.Y in Valid and Raw.Z in Valid));
      else
         Value := (X | Y | Z => 0.0, Overflow => True);
      end if;
   end Read_Measurement;

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

   --------------
   -- Set_Mode --
   --------------

   procedure Set_Mode
     (Device  : Device_Context;
      Mode    : Operating_Mode;
      Success : out Boolean) is
   begin
      Write (Device, [02 => Operating_Mode'Pos (Mode)], Success);
   end Set_Mode;

end HMC5883.Internal;
