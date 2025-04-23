--  SPDX-FileCopyrightText: 2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Ada.Unchecked_Conversion;

package body HMC5883.Raw is

   ---------------------
   -- Get_Measurement --
   ---------------------

   function Get_Measurement
     (Raw   : Byte_Array;
      Scale : Full_Scale_Range) return Optional_Magnetic_Field_Vector
   is
      subtype Valid is Valid_Raw_Value;

      Vector : constant Raw_Vector := Get_Raw_Measurement (Raw);

   begin
      return
        (X => (if Vector.X in Valid then Scale * Int (Vector.X) else 0.0),
         Y => (if Vector.Y in Valid then Scale * Int (Vector.Y) else 0.0),
         Z => (if Vector.Z in Valid then Scale * Int (Vector.Z) else 0.0),
         Overflow => not
           (Vector.X in Valid and Vector.Y in Valid and Vector.Z in Valid));
   end Get_Measurement;

   -------------------------
   -- Get_Raw_Measurement --
   -------------------------

   function Get_Raw_Measurement (Raw : Byte_Array) return Raw_Vector is
      use Interfaces;

      function Cast is new Ada.Unchecked_Conversion
        (Unsigned_16, Integer_16);

      function Decode (Data : Byte_Array) return Integer_16 is
         (Cast (Shift_Left (Unsigned_16 (Data (Data'First)), 8)
            + Unsigned_16 (Data (Data'Last))));

   begin
      return
        (X => Decode (Raw (3 .. 4)),
         Y => Decode (Raw (5 .. 6)),
         Z => Decode (Raw (7 .. 8)));
   end Get_Raw_Measurement;

   -----------------------
   -- Set_Configuration --
   -----------------------

   function Set_Configuration
     (Value : Sensor_Configuration) return Configuration_Data
   is
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
        (CRA_Register, Byte);

      type CRB_Register is record
         Reserved : Natural range 0 .. 0 := 0;
         GN       : Natural range 0 .. 7;
      end record;

      for CRB_Register use record
         Reserved at 0 range 0 .. 4;
         GN       at 0 range 5 .. 7;
      end record;

      function Cast_CRB is new Ada.Unchecked_Conversion
        (CRB_Register, Byte);

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

      GN : constant Natural range 0 .. 7 :=
        (case Value.Gain is
            when 230  => 7,
            when 330  => 6,
            when 390  => 5,
            when 440  => 4,
            when 660  => 3,
            when 820  => 2,
            when 1090 => 1,
            when 1370 => 0);

      Data : constant Byte_Array (00 .. 01) :=
        (00 => Cast_CRA ((MS => MS, DOR => DOR, MA => MA, Reserved => 0)),
         01 => Cast_CRB ((GN => GN, Reserved => 0)));
   begin
      return Data;
   end Set_Configuration;

end HMC5883.Raw;
