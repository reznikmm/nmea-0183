--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with NMEA_0183.Parse_Message;

with Devices.Interrupt_Tasks;
pragma Unreferenced (Devices.Interrupt_Tasks);

package body Devices is

   ------------------
   -- Wait_Message --
   ------------------

   procedure Wait_Message (Value : out NMEA_0183.NMEA_Message) is
      use all type NMEA_0183.Parse_Status;

      Text   : String (1 .. 80);
      Last   : Natural;
      Status : NMEA_0183.Parse_Status;
   begin
      loop
         Text_Line_Buffers.Read_Line (GPS_Input, Text, Last);
         NMEA_0183.Parse_Message (Text (1 .. Last), Value, Status);

         exit when Status in Success | No_Checksum;
      end loop;
   end Wait_Message;

end Devices;
