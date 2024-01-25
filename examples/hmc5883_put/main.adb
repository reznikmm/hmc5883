--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

pragma Ada_2022;

with Ada.Real_Time;
with Ada.Text_IO;

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
   Vector : array (1 .. 16) of HMC5883.Magnetic_Field_Vector;
   Prev   : Ada.Real_Time.Time;

   Spinned : Natural;
begin
   STM32.Board.Initialize_LEDs;
   STM32.Setup.Setup_I2C_Master
     (Port        => STM32.Device.I2C_1,
      SDA         => STM32.Device.PB9,
      SCL         => STM32.Device.PB8,
      SDA_AF      => STM32.Device.GPIO_AF_I2C1_4,
      SCL_AF      => STM32.Device.GPIO_AF_I2C1_4,
      Clock_Speed => 400_000);

   declare
      Status : HAL.I2C.I2C_Status;
   begin
      STM32.Device.I2C_1.Master_Transmit
        (Addr    => 16#3C#,
         Data    => [16#0A#],  --  Chip ID for HMC5883L
         Status  => Status);
   end;

   --  Look for HMC5883L chip
   if not HMC5883_I2C.Check_Chip_Id then
      Ada.Text_IO.Put_Line ("HMC5883L not found.");
      raise Program_Error;
   end if;

   --  Set HMC5883L up
   HMC5883_I2C.Configure
     ((Average => 8,
       ODR     => 15.0,
       Gain    => 1090,
       Bias    => HMC5883.None),
      Ok);
   pragma Assert (Ok);

   loop
      Spinned := 0;
      Prev := Ada.Real_Time.Clock;
      STM32.Board.Toggle (STM32.Board.D1_LED);

      for J in Vector'Range loop

         --  trigger single measurement
         HMC5883_I2C.Set_Mode (HMC5883.Single_Measurement, Ok);
         pragma Assert (Ok);

         --  Wait operation mode to become idle
         while not HMC5883_I2C.Is_Idle loop
            Spinned := Spinned + 1;
         end loop;

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
         Ada.Text_IO.Put_Line
           ("Time=" & Diff'Image & "/16 Spinned=" & Spinned'Image);

         for Value of Vector loop
            if Value.X.Is_Overflow
              or Value.X.Is_Overflow
              or Value.X.Is_Overflow
            then
               Ada.Text_IO.Put_Line ("Overflow");
            else
               Ada.Text_IO.Put_Line
                 ("X=" & Value.X.Value'Image &
                    " Y=" & Value.Y.Value'Image &
                    " Z=" & Value.Z.Value'Image);
            end if;
         end loop;

         Ada.Text_IO.Put_Line ("Sleeping 2s...");
         Ravenscar_Time.Delays.Delay_Seconds (2);
      end;
   end loop;
end Main;
