--  SPDX-FileCopyrightText: 2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Interfaces;

package HMC5883 is
   pragma Preelaborate;
   pragma Discard_Names;

   type Average_Count is range 1 .. 8
     with Static_Predicate => Average_Count in 1 | 2 | 4 | 8;

   type Output_Data_Rate is delta 0.25 range 0.75 .. 75.0
     with Static_Predicate =>
       Output_Data_Rate in 0.75 | 1.5 | 3.0 | 7.5 | 15.0 | 30.0 | 75.0;
   --
   --  Typical Data Output Rate (Hz)

   type Sensor_Gain is range 230 .. 1370
     with Static_Predicate =>
       Sensor_Gain in 230 | 330 | 390 | 440 | 660 | 820 | 1090 | 1370;
   --
   --  Sensitivity, LSB (Least-signed-bit) per one Gauss.
   --  Use this to convert raw counts to Gauss.
   --
   --  The new gain setting is effective from the second measurement and on.

   type Self_Test_Bias is (None, Positive, Negative);
   --  Extra bias to self-test and temperature compensation.
   --  When the extra bias applied the value 1.1 Gauss should be reported.

   type Sensor_Configuration is record
      Average : Average_Count := 1;
      ODR     : Output_Data_Rate := 15.0;
      Gain    : Sensor_Gain := 1090;
      Bias    : Self_Test_Bias := None;
   end record;

   type Operating_Mode is
     (Continuous_Measurement,
      Single_Measurement,
      Idle);
   --  The Operating Mode
   --
   --  * @value Continuous_Measurement - Continuous-Measurement Mode.
   --
   --  In continuous-measurement mode, the device continuously performs
   --  measurements and places the result in the data register. RDY goes high
   --  when new data is placed in all three registers. After a power-on or a
   --  write to the mode or configuration register, the first measurement set
   --  is available from all three data output registers after a period of
   --  2/fODR and subsequent measurements are available at a frequency of
   --  fODR, where fODR is the frequency of data output.
   --
   --  * @value Single_Measurement - Single-Measurement Mode.
   --
   --  Single-Measurement Mode (Default).
   --
   --  When single-measurement mode is selected, device performs a single
   --  measurement, sets RDY high and returned to idle mode. Mode register
   --  returns to idle mode bit values. The measurement remains in the data
   --  output register and RDY remains high until the data output register
   --  is read or another measurement is performed.
   --
   --  * @value Idle - Idle Mode.
   --
   --  Device is placed in idle mode.
   --

   type Magnetic_Field is delta 1.0 / 2.0 ** 11 range -10.0 .. 10.0;
   --  Magnetic flux density in Gauss

   type Optional_Magnetic_Field (Is_Overflow : Boolean := True) is record
      case Is_Overflow is
         when False =>
            Value : Magnetic_Field;
         when True =>
            null;
      end case;
   end record;

   type Magnetic_Field_Vector is record
      X, Y, Z : Optional_Magnetic_Field;
   end record;

   Overflow : constant := -4096;
   --  In the event the ADC reading overflows or underflows for the given
   --  channel, or if there is a math overflow during the bias measurement,
   --  this data register will contain the value -4096.

   Min_Valid_Raw_Value : constant := -2048;
   Max_Valid_Raw_Value : constant := 2047;

   subtype Valid_Raw_Value is Interfaces.Integer_16
     range Min_Valid_Raw_Value .. Max_Valid_Raw_Value;

   type Raw_Vector is record
      X, Y, Z : Interfaces.Integer_16 range Overflow .. 2047;
   end record;
   --  A value read from the sensor in raw format. Normal value has range
   --  -2048 .. 2047, while -4096 means overflow.

   subtype Byte is Interfaces.Unsigned_8;  --  Register value

   subtype Register_Address is Natural range 16#00# .. 16#FF#;
   --  Sensor's register address

   type Byte_Array is array (Register_Address'Base range <>) of Byte;
   --  Bytes to be exchanged with registers. Index is a register address, while
   --  elements are corresponding register values.

   Chip_Id : constant Byte_Array (1 .. 3) := (16#48#, 16#34#, 16#33#);

   type Full_Scale_Range is delta 1.0 / 2.0 ** 23 range 0.0 .. 0.005;
   --  Gauss per LSB

   function To_Scale (Gain : Sensor_Gain) return Full_Scale_Range;
   --  Get Gauss per LSB for given gain setting

   pragma Warnings
     (Off, "static fixed-point value is not a multiple of Small");

   function To_Scale (Gain : Sensor_Gain) return Full_Scale_Range is
     (case Gain is
      when 230  => 1.0 / 230.0,
      when 330  => 1.0 / 330.0,
      when 390  => 1.0 / 390.0,
      when 440  => 1.0 / 440.0,
      when 660  => 1.0 / 660.0,
      when 820  => 1.0 / 820.0,
      when 1090 => 1.0 / 1090.0,
      when 1370 => 1.0 / 1370.0);
   --  Convert gain/sensitivity to scale

   function To_Magnetic_Field
     (V : Valid_Raw_Value; Scale : Full_Scale_Range) return Magnetic_Field;
   --  Convert raw sensor data to magnetic field with given scale

   function To_Magnetic_Field
     (V : Valid_Raw_Value; Gain : Sensor_Gain) return Magnetic_Field;
   --  Convert raw sensor data to magnetic field with given gain/sensitivity

   function To_Raw_Value
     (V : Magnetic_Field; Gain : Sensor_Gain) return Valid_Raw_Value;
   --  Convert magnetic field to a raw sensor value with given gain/sensitivity

   I2C_Address : constant := 16#1E#;
   --  Defaulr I2C device address

private

   Scale_Map : constant array (0 .. 7) of Full_Scale_Range :=
     (0 => 1.0 / 1370.0,
      1 => 1.0 / 1090.0,
      2 => 1.0 / 820.0,
      3 => 1.0 / 660.0,
      4 => 1.0 / 440.0,
      5 => 1.0 / 390.0,
      6 => 1.0 / 330.0,
      7 => 1.0 / 230.0);

   pragma Warnings
     (On, "static fixed-point value is not a multiple of Small");

   type Int is delta 1.0 range -2048.0 .. 2047.0;

   function To_Magnetic_Field
     (V : Valid_Raw_Value; Scale : Full_Scale_Range) return Magnetic_Field is
       (Scale * Int (V));

   function To_Magnetic_Field
     (V : Valid_Raw_Value; Gain : Sensor_Gain) return Magnetic_Field is
       (To_Scale (Gain) * Int (V));

   function To_Raw_Value
     (V : Magnetic_Field; Gain : Sensor_Gain) return Valid_Raw_Value is
       (Valid_Raw_Value (Int'(Int (Gain) * V)));

end HMC5883;
