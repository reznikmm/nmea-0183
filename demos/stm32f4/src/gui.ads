--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with HAL.Bitmap;

with NMEA_0183;

package GUI is

   procedure Show (Value : NMEA_0183.NMEA_Message);

   procedure Draw
     (LCD   : in out HAL.Bitmap.Bitmap_Buffer'Class;
      Clear : Boolean := False);

end GUI;
