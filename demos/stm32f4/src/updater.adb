--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Devices;
with GUI;
with NMEA_0183;

package body Updater is

   -----------------
   -- GPS_Updater --
   -----------------

   task body GPS_Updater is
      Message : NMEA_0183.NMEA_Message;
   begin
      loop
         Devices.Wait_Message (Message);
         GUI.Show (Message);
      end loop;
   end GPS_Updater;

end Updater;
