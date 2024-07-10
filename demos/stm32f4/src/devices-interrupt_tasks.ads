--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with System;

private
package Devices.Interrupt_Tasks is

   task Interrupt_Task
     with
       Storage_Size => 4096,
       Secondary_Stack_Size => 1024,
       Priority => System.Priority'Last;

end Devices.Interrupt_Tasks;
