--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

private
package Devices.Interrupt_Handler is

   type Event_Kind is (USART_Input);

   type Event (Kind : Event_Kind := Event_Kind'First) is record
      case Kind is
         when USART_Input =>
            USART_Input : Character;
      end case;
   end record;

   procedure Wait_Event (Value : out Event);

end Devices.Interrupt_Handler;
