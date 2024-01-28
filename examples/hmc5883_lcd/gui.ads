--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

pragma Ada_2022;

with GUI_Buttons;
with HAL.Bitmap;
with HAL.Touch_Panel;

package GUI is

   type Button_Kind is
     (Fx, Fy, Fz,                       --  Field components
      A1, A2, A4, A8,                   --  Average count
      BN, BZ, BP,                       --  Bias (negative, zero, positive)
      G0, G1, G2, G3, G4, G5, G6, G7);  --  Gain

   function "+" (X : Button_Kind) return Natural is (Button_Kind'Pos (X))
     with Static;

   Buttons : constant GUI_Buttons.Button_Info_Array :=
     [(Label  => "Fx",
       Center => (23 * 1, 20),
       Color  => HAL.Bitmap.Red),
      (Label  => "Fy",
       Center => (23 * 2, 20),
       Color  => HAL.Bitmap.Green),
      (Label  => "Fz",
       Center => (23 * 3, 20),
       Color  => HAL.Bitmap.Blue),
      (Label  => "A1",
       Center => (23 * 1 + 160, 20),
       Color  => HAL.Bitmap.Yellow_Green),
      (Label  => "A2",
       Center => (23 * 2 + 160, 20),
       Color  => HAL.Bitmap.Yellow_Green),
      (Label  => "A4",
       Center => (23 * 3 + 160, 20),
       Color  => HAL.Bitmap.Yellow_Green),
      (Label  => "A8",
       Center => (23 * 4 + 160, 20),
       Color  => HAL.Bitmap.Yellow_Green),
      (Label  => "B-",
       Center => (23 * 1 + 160, 220),
       Color  => HAL.Bitmap.Dim_Grey),
      (Label  => "B0",
       Center => (23 * 2 + 160, 220),
       Color  => HAL.Bitmap.Dim_Grey),
      (Label  => "B+",
       Center => (23 * 3 + 160, 220),
       Color  => HAL.Bitmap.Dim_Grey),
      (Label  => "G0",
       Center => (23, 60 + 1 * 15),
       Color  => HAL.Bitmap.Dark_Grey),
      (Label  => "G1",
       Center => (23, 60 + 2 * 15),
       Color  => HAL.Bitmap.Dark_Grey),
      (Label  => "G2",
       Center => (23, 60 + 3 * 15),
       Color  => HAL.Bitmap.Dark_Grey),
      (Label  => "G3",
       Center => (23, 60 + 4 * 15),
       Color  => HAL.Bitmap.Dark_Grey),
      (Label  => "G4",
       Center => (23, 60 + 5 * 15),
       Color  => HAL.Bitmap.Dark_Grey),
      (Label  => "G5",
       Center => (23, 60 + 6 * 15),
       Color  => HAL.Bitmap.Dark_Grey),
      (Label  => "G6",
       Center => (23, 60 + 7 * 15),
       Color  => HAL.Bitmap.Dark_Grey),
      (Label  => "G7",
       Center => (23, 60 + 8 * 15),
       Color  => HAL.Bitmap.Dark_Grey)];

   State : GUI_Buttons.Boolean_Array (Buttons'Range) :=
     [+Fx | +Fy | +Fz | +A1 | +BZ | +G1 => True, others => False];

   procedure Check_Touch
     (TP     : in out HAL.Touch_Panel.Touch_Panel_Device'Class;
      Update : out Boolean);
   --  Check buttons touched, update State, set Update = True if State changed

   procedure Draw
     (LCD   : in out HAL.Bitmap.Bitmap_Buffer'Class;
      Clear : Boolean := False);

   procedure Dump_Screen (LCD : in out HAL.Bitmap.Bitmap_Buffer'Class);

end GUI;
