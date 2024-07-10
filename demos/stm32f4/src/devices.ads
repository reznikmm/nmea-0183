--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with System;
with NMEA_0183;

private with Text_Line_Buffers;

package Devices is

   procedure Wait_Message (Value : out NMEA_0183.NMEA_Message);

private

   GPS_Input : Text_Line_Buffers.Line_Buffer
     (Priority => System.Priority'Last);

end Devices;
