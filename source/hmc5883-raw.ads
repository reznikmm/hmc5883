--  SPDX-FileCopyrightText: 2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

--  This package provides a low-level interface for interacting with the
--  sensor. Communication with the sensor is done by reading/writing one
--  or more bytes to predefined registers. The interface allows the user to
--  implement the read/write operations in the way they prefer but handles
--  encoding/decoding register values into user-friendly formats.
--
--  For each request to the sensor, the interface defines a subtype-array
--  where the index of the array element represents the register number to
--  read/write, and the value of the element represents the corresponding
--  register value.
--
--  Functions starting with `Set_` prepare values to be written to the
--  registers. Conversely, functions starting with `Get_` decode register
--  values. Functions starting with `Is_` are a special case for boolean
--  values.
--
--  The user is responsible for reading and writing register values!

package HMC5883.Raw is

   use type Byte;

   subtype Chip_Id_Data is Byte_Array (10 .. 12);
   --  The identification registers A, B, C is used to identify the device.

   function Get_Chip_Id (Raw : Byte_Array) return Byte_Array is
     (Raw (Chip_Id_Data'Range))
       with Pre => Chip_Id_Data'First in Raw'Range;
   --  Read the chip ID. Raw data should contain Chip_Id_Data'Range items.

   subtype Configuration_Data is Byte_Array (0 .. 1);

   function Set_Configuration
     (Value : Sensor_Configuration) return Configuration_Data;
   --  Write A and B Configuration Registers (00, 01)

   subtype Operating_Mode_Data is Byte_Array (2 .. 2);
   --  This register is used to select the operating mode of the device.

   function Set_Mode (Mode : Operating_Mode) return Operating_Mode_Data is
     (02 => Operating_Mode'Pos (Mode));
   --  Write Mode Register (02)

   function Is_Idle (Raw : Byte_Array) return Boolean is
     ((Raw (Operating_Mode_Data'First) and 2) /= 0)
        with Pre => Operating_Mode_Data'First in Raw'Range;
   --
   --  Check if device is placed in idle mode.

   subtype Status_Data is Byte_Array (9 .. 9);

   function Is_Ready (Raw : Byte_Array) return Boolean is
      ((Raw (Status_Data'First) and 1) = 1)
        with Pre => Status_Data'First in Raw'Range;
   --
   --  Get Ready Bit. Set when data is written to all six data
   --  registers. Cleared when device initiates a write to the data output
   --  registers and after one or more of the data output registers are
   --  written to. When RDY bit is clear it shall remain cleared for a
   --  250 us.

   function Is_Locked (Raw : Byte_Array) return Boolean is
      ((Raw (Status_Data'First) and 2) = 1)
        with Pre => Status_Data'First in Raw'Range;
   --
   --  Data output register lock. This bit is set when:
   --
   --  1. some but not all for of the six data output registers have been read,
   --  2. Mode register has been read.
   --
   --  When this bit is set, the six data output registers are locked and
   --  any new data will not be placed in these register until one of these
   --  conditions are met:
   --
   --  1. all six bytes have been read,
   --  2. the mode register is changed,
   --  3. the measurement configuration (CRA) is changed,
   --  4. power is reset.

   subtype Measurement_Data is Byte_Array (3 .. 8);
   --  Magnetic field data registers

   function Get_Raw_Measurement (Raw : Byte_Array) return Raw_Vector
     with Pre => Measurement_Data'First in Raw'Range and then
       Measurement_Data'Last in Raw'Range;
   --
   --  Decode raw measurement. Raw data should contain Measurement_Data'Range
   --  items.

   function Get_Measurement
     (Raw   : Byte_Array;
      Scale : Full_Scale_Range) return Optional_Magnetic_Field_Vector
     with Pre => Measurement_Data'First in Raw'Range and then
       Measurement_Data'Last in Raw'Range;
   --
   --  Decode measurement. Raw data should contain Measurement_Data'Range items

   ------------------------------
   -- I2C Write/Read functions --
   ------------------------------

   function I2C_Write (X : Byte_Array) return Byte_Array is
     ((X'First - 1 => Byte (X'First)) & X);
   --  Prefix the byte array with the register address for the I2C write
   --  operation

   function I2C_Read (X : Byte_Array) return Byte_Array is
      ((X'First => Byte (X'First)) & X (X'First + 1 .. X'Last));
   --  Replace the byte of array with the register address for the I2C read
   --  operation

end HMC5883.Raw;
