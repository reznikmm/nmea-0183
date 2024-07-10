--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Devices.Interrupt_Handler;
with Text_Line_Buffers;

package body Devices.Interrupt_Tasks is

   --------------------
   -- Interrupt_Task --
   --------------------

   task body Interrupt_Task is
      Event : Devices.Interrupt_Handler.Event;
      Is_Full : Boolean;
   begin
      loop
         Devices.Interrupt_Handler.Wait_Event (Event);

         case Event.Kind is
            when Devices.Interrupt_Handler.USART_Input =>
               Text_Line_Buffers.Write_Character
                 (GPS_Input, Event.USART_Input, Is_Full);

         end case;
      end loop;
   end Interrupt_Task;

end Devices.Interrupt_Tasks;
