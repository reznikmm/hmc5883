--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Interfaces;

package HMC5883 is
   pragma Preelaborate;
   pragma Discard_Names;

   type Raw_Vector is record
      X, Y, Z : Interfaces.Integer_16;
   end record;
   --  A value read from the sensor in raw format

end HMC5883;
