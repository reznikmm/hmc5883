--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Ada.Text_IO;

with Ravenscar_Time;

with STM32.Board;
with STM32.Device;
with STM32.GPIO;
with STM32.Setup;
with STM32.User_Button;

with HAL.Bitmap;
with HAL.Framebuffer;
with HAL.I2C;

with Display_ILI9341;
with Bitmapped_Drawing;
with BMP_Fonts;

with HMC5883.Sensors;

with GUI;

procedure Main is
   use all type GUI.Button_Kind;

   Sensor : HMC5883.Sensors.HMC5883_Sensor
     (I2C_Port => STM32.Device.I2C_1'Access);

   procedure Configure_Sensor;
   --  Restart sensor with new settings according to GUI state

   type Sensor_Data is record
      X, Y, Z : HMC5883.Magnetic_Field'Base;
   end record;

   function Read_Sensor return HMC5883.Optional_Magnetic_Field_Vector;

   function Min (Left, Right : Sensor_Data)
     return Sensor_Data is
       (X => HMC5883.Magnetic_Field'Min (Left.X, Right.X),
        Y => HMC5883.Magnetic_Field'Min (Left.Y, Right.Y),
        Z => HMC5883.Magnetic_Field'Min (Left.Z, Right.Z));

   function Max (Left, Right : Sensor_Data)
     return Sensor_Data is
       (X => HMC5883.Magnetic_Field'Max (Left.X, Right.X),
        Y => HMC5883.Magnetic_Field'Max (Left.Y, Right.Y),
        Z => HMC5883.Magnetic_Field'Max (Left.Z, Right.Z));

   use type HMC5883.Magnetic_Field;

   function "*" (Percent : Integer; Right : Sensor_Data)
     return Sensor_Data is
       (X => HMC5883.Magnetic_Field'Max
          (abs Right.X / 100, HMC5883.Magnetic_Field'Small) * Percent,
        Y => HMC5883.Magnetic_Field'Max
          (abs Right.Y / 100, HMC5883.Magnetic_Field'Small) * Percent,
        Z => HMC5883.Magnetic_Field'Max
          (abs Right.Z / 100, HMC5883.Magnetic_Field'Small) * Percent);

   function "+" (Left, Right : Sensor_Data)
     return Sensor_Data is
       (X => Left.X + Right.X,
        Y => Left.Y + Right.Y,
        Z => Left.Z + Right.Z);

   function To_Data
     (V : HMC5883.Optional_Magnetic_Field_Vector) return Sensor_Data is
     (if HMC5883.Has_Overflow (V) then (0.0, 0.0, 0.0)
      else
        (HMC5883.To_Magnetic_Field_Vector (V).X,
         HMC5883.To_Magnetic_Field_Vector (V).Y,
         HMC5883.To_Magnetic_Field_Vector (V).Z));

   type Sensor_Limits is record
      Min : Sensor_Data;
      Max : Sensor_Data;
   end record;

   procedure Make_Wider (Limits : in out Sensor_Limits);
   --  Make limits a bit wider

   procedure Print
     (LCD    : not null HAL.Bitmap.Any_Bitmap_Buffer;
      Data   : HMC5883.Optional_Magnetic_Field_Vector);

   procedure Plot
     (LCD    : not null HAL.Bitmap.Any_Bitmap_Buffer;
      X      : Natural;
      Data   : in out Sensor_Data;
      Limits : Sensor_Limits);

   ----------------------
   -- Configure_Sensor --
   ----------------------

   procedure Configure_Sensor is
      use type HMC5883.Average_Count;

      Ok   : Boolean;
      Avg  : HMC5883.Average_Count := 1;
      Gain : HMC5883.Sensor_Gain;

      Bias : constant HMC5883.Self_Test_Bias :=
        (if GUI.State (+BN) then HMC5883.Negative
         elsif GUI.State (+BP) then HMC5883.Positive
         else HMC5883.None);

      Map  : constant array (G0 .. G7) of HMC5883.Sensor_Gain :=
        (230, 330, 390, 440, 660, 820, 1090, 1370);
   begin
      for V of GUI.State (+A1 .. +A8) loop
         exit when V;
         Avg := Avg * 2;
      end loop;

      for R in G0 .. G7 loop
         if GUI.State (+R) then
            Gain := Map (R);
            exit;
         end if;
      end loop;

      Sensor.Configure
        ((Average => Avg,
          ODR     => 15.0,
          Gain    => Gain,
          Bias    => Bias),
         Ok);
      pragma Assert (Ok);
   end Configure_Sensor;

   ----------------
   -- Make_Wider --
   ----------------

      procedure Make_Wider (Limits : in out Sensor_Limits) is
   begin
      Limits.Min := Limits.Min + (-2) * Limits.Min;
      Limits.Max := Limits.Max + 2 * Limits.Max;
   end Make_Wider;

   -----------
   -- Print --
   -----------

   procedure Print
     (LCD    : not null HAL.Bitmap.Any_Bitmap_Buffer;
      Data   : HMC5883.Optional_Magnetic_Field_Vector)
   is
      Overflow : constant Boolean := HMC5883.Has_Overflow (Data);
      V        : constant HMC5883.Magnetic_Field_Vector :=
        (if Overflow then  (0.0, 0.0, 0.0)
         else HMC5883.To_Magnetic_Field_Vector (Data));

      TX : constant String :=
        (if Overflow then "Over" else HMC5883.Magnetic_Field'Image (V.X));
      TY : constant String :=
        (if Overflow then "Over" else HMC5883.Magnetic_Field'Image (V.Y));
      TZ : constant String :=
        (if Overflow then "Over" else HMC5883.Magnetic_Field'Image (V.Z));
   begin
      if GUI.State (+Fx) then
         Bitmapped_Drawing.Draw_String
           (LCD.all,
            Start      => (0, 30),
            Msg        => TX,
            Font       => BMP_Fonts.Font8x8,
            Foreground => GUI.Buttons (+Fx).Color,
            Background => HAL.Bitmap.Black);
      end if;

      if GUI.State (+Fy) then
         Bitmapped_Drawing.Draw_String
           (LCD.all,
            Start      => (0, 40),
            Msg        => TY,
            Font       => BMP_Fonts.Font8x8,
            Foreground => GUI.Buttons (+Fy).Color,
            Background => HAL.Bitmap.Black);
      end if;

      if GUI.State (+Fz) then
         Bitmapped_Drawing.Draw_String
           (LCD.all,
            Start      => (0, 50),
            Msg        => TZ,
            Font       => BMP_Fonts.Font8x8,
            Foreground => GUI.Buttons (+Fz).Color,
            Background => HAL.Bitmap.Black);
      end if;
   end Print;

   ----------
   -- Plot --
   ----------

   procedure Plot
     (LCD    : not null HAL.Bitmap.Any_Bitmap_Buffer;
      X      : Natural;
      Data   : in out Sensor_Data;
      Limits : Sensor_Limits)
   is
      type Int is delta 1.0 range -1000.0 .. 1000.0;
      Height : constant Int := Int (LCD.Height);
      Value  : HMC5883.Magnetic_Field;
      Y      : Natural;
   begin
      Data := Min (Data, Limits.Max);
      Data := Max (Data, Limits.Min);

      if GUI.State (+Fx) then
         Value := (Data.X - Limits.Min.X) / (Limits.Max.X - Limits.Min.X);
         Y := Natural (Value * Height);
         Y := LCD.Height - Y;
         LCD.Set_Pixel ((X, Y), GUI.Buttons (+Fx).Color);
      end if;

      if GUI.State (+Fy) then
         Value := (Data.Y - Limits.Min.Y) / (Limits.Max.Y - Limits.Min.Y);
         Y := Natural (Value * Height);
         Y := LCD.Height - Y;
         LCD.Set_Pixel ((X, Y), GUI.Buttons (+Fy).Color);
      end if;

      if GUI.State (+Fz) then
         Value := (Data.Z - Limits.Min.Z) / (Limits.Max.Z - Limits.Min.Z);
         Y := Natural (Value * Height);
         Y := LCD.Height - Y;
         LCD.Set_Pixel ((X, Y), GUI.Buttons (+Fz).Color);
      end if;
   end Plot;

   -----------------
   -- Read_Sensor --
   -----------------

   function Read_Sensor return HMC5883.Optional_Magnetic_Field_Vector is
      Ok     : Boolean;
      Result : HMC5883.Optional_Magnetic_Field_Vector;
   begin
      while Sensor.Is_Writing loop
         Ravenscar_Time.Delays.Delay_Microseconds (50);
      end loop;

      Sensor.Read_Measurement (Result, Ok);
      pragma Assert (Ok);

      Sensor.Set_Mode (HMC5883.Single_Measurement, Ok);
      pragma Assert (Ok);

      return Result;
   end Read_Sensor;

   LCD : constant not null HAL.Bitmap.Any_Bitmap_Buffer :=
     STM32.Board.TFT_Bitmap'Access;

   Next_Limits : Sensor_Limits;
begin
   STM32.Board.Initialize_LEDs;
   STM32.User_Button.Initialize;
   STM32.Board.Display.Initialize;
   STM32.Board.Display.Set_Orientation (HAL.Framebuffer.Landscape);
   STM32.Board.Touch_Panel.Initialize;
   STM32.Board.Touch_Panel.Set_Orientation (HAL.Framebuffer.Landscape);

   --  Initialize touch panel IRQ pin
   STM32.Board.TFT_RS.Configure_IO
     ((STM32.GPIO.Mode_In, Resistors => STM32.GPIO.Floating));

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
      --  Workaround for STM32 I2C driver bug
      STM32.Device.I2C_1.Master_Transmit
        (Addr    => 16#3C#,
         Data    => (1 => 16#0A#),  --  Chip ID for HMC5883L
         Status  => Status);
   end;

   --  Look for HMC5883 chip
   if not Sensor.Check_Chip_Id then
      Ada.Text_IO.Put_Line ("HMC5883 not found.");
      raise Program_Error;
   end if;

   Configure_Sensor;

   declare
      Vector : HMC5883.Optional_Magnetic_Field_Vector;
   begin
      loop
         Vector := Read_Sensor;

         exit when not HMC5883.Has_Overflow (Vector);
      end loop;

      Next_Limits.Min := To_Data (Vector);
   end;

   --  Predict boundaries from the first sensor measurement
   Next_Limits.Max := Next_Limits.Min;
   Make_Wider (Next_Limits);

   loop
      declare
         Vector : HMC5883.Optional_Magnetic_Field_Vector;
         Data   : Sensor_Data;
         Update : Boolean := False;  --  GUI state updated
      begin
         GUI.Draw (LCD.all, Clear => True);  --  draw all buttons

         for X in 0 .. LCD.Width - 1 loop
            STM32.Board.Toggle (STM32.Board.D1_LED);

            Vector := Read_Sensor;

            if not STM32.Board.TFT_RS.Set then  --  Touch IRQ Pin is active
               GUI.Check_Touch (STM32.Board.Touch_Panel, Update);
            end if;

            GUI.Draw (LCD.all);

            if HMC5883.Has_Overflow (Vector) then
               Print (LCD, Vector);
            else
               Data := To_Data (Vector);
               Next_Limits :=
                 (Min => Min (Data, Next_Limits.Min),
                  Max => Max (Data, Next_Limits.Max));

               Print (LCD, Vector);
               Plot (LCD, X, Data, Next_Limits);
            end if;

            if Update then
               Configure_Sensor;
               Update := False;
            elsif STM32.User_Button.Has_Been_Pressed then
               GUI.Dump_Screen (LCD.all);
            end if;
         end loop;
      end;
   end loop;
end Main;
