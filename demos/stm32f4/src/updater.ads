--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

package Updater is

   task GPS_Updater
     with
       Storage_Size => 4096,
       Secondary_Stack_Size => 1024,
       Priority => 125;

end Updater;
