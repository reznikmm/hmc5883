--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Ada.Real_Time;
with Ada.Text_IO;

with HMC5883;
with Ravenscar_Time;

with STM32.Board;
with STM32.Device;
with STM32.Setup;

with HAL.I2C;

with HMC5883.Sensor;

procedure Main is
   use type Ada.Real_Time.Time;

   package HMC5883_I2C is new HMC5883.Sensor
     (I2C_Port => STM32.Device.I2C_1'Access);

   Ok     : Boolean := False;
   Vector : array (1 .. 16) of HMC5883.Optional_Magnetic_Field_Vector;
   Prev   : Ada.Real_Time.Time;
begin
   STM32.Board.Initialize_LEDs;
   STM32.Setup.Setup_I2C_Master
     (Port        => STM32.Device.I2C_1,
      SDA         => STM32.Device.PB7,
      SCL         => STM32.Device.PB8,
      SDA_AF      => STM32.Device.GPIO_AF_I2C1_4,
      SCL_AF      => STM32.Device.GPIO_AF_I2C1_4,
      Clock_Speed => 400_000);

   declare
      Status : HAL.I2C.I2C_Status;
   begin
      --  Workaround for STM32 I2C driver bug
      STM32.Device.I2C_1.Master_Transmit
        (Addr    => 16#3C#,
         Data    => (1 => 16#0A#),  --  Chip ID for HMC5883L
         Status  => Status);
   end;

   --  Look for HMC5883L chip
   if not HMC5883_I2C.Check_Chip_Id then
      Ada.Text_IO.Put_Line ("HMC5883L not found.");
      raise Program_Error;
   end if;

   --  Set HMC5883L up
   HMC5883_I2C.Configure
     ((Average => 1,     --  no average
       ODR     => 15.0,  --  doesn't matter in single measurement mode
       Gain    => 1090,  --  default gain
       Bias    => HMC5883.None),
      Ok);
   pragma Assert (Ok);

   loop
      Prev := Ada.Real_Time.Clock;
      STM32.Board.Toggle (STM32.Board.D1_LED);

      for J in Vector'Range loop

         --  trigger single measurement
         HMC5883_I2C.Set_Mode (HMC5883.Single_Measurement, Ok);
         pragma Assert (Ok);

         Ravenscar_Time.Delays.Delay_Milliseconds (1000/150);  --  150 Hz

         --  Read scaled values from the sensor
         HMC5883_I2C.Read_Measurement (Vector (J), Ok);
         pragma Assert (Ok);
      end loop;

      --  Printing...
      declare
         Now  : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
         Diff : constant Duration := Ada.Real_Time.To_Duration (Now - Prev);
      begin
         Ada.Text_IO.New_Line;
         Ada.Text_IO.New_Line;
         Ada.Text_IO.Put_Line ("Time=" & Diff'Image & "/16");

         for Value of Vector loop
            declare
               Overflow : constant Boolean := HMC5883.Has_Overflow (Value);

               V : constant HMC5883.Magnetic_Field_Vector :=
                 (if Overflow then (0.0, 0.0, 0.0)
                  else HMC5883.To_Magnetic_Field_Vector (Value));

               X : constant String :=
                 (if Overflow then "Overflow" else V.X'Image);

               Y : constant String :=
                 (if Overflow then "Overflow" else V.Y'Image);

               Z : constant String :=
                 (if Overflow then "Overflow" else V.Z'Image);
            begin
               Ada.Text_IO.Put_Line ("X=" & X & " Y=" & Y & " Z=" & Z);
            end;
         end loop;

         Ada.Text_IO.Put_Line ("Sleeping 2s...");
         Ravenscar_Time.Delays.Delay_Seconds (2);
      end;
   end loop;
end Main;
