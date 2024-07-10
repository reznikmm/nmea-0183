--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Ada.Interrupts.Names;

with HAL;

with STM32.Device;
with STM32.GPIO;
with STM32.USARTs;

package body Devices.Interrupt_Handler is

   USART : STM32.USARTs.USART renames STM32.Device.USART_1;

   procedure Initialize;

   -----------------------
   -- Interrupt_Handler --
   -----------------------

   protected Interrupt_Handler is

      entry Wait_Event (Value : out Event);

   private

      Ready : Boolean := False;
      USART_Input : Character;

      procedure USART1_Interrupt;

      pragma Attach_Handler
        (USART1_Interrupt, Ada.Interrupts.Names.USART1_Interrupt);

      pragma Interrupt_Priority;
   end Interrupt_Handler;

   -----------------------
   -- Interrupt_Handler --
   -----------------------

   protected body Interrupt_Handler is

      ----------------
      -- Wait_Event --
      ----------------

      entry Wait_Event (Value : out Event) when Ready is
      begin
         Value := (Devices.Interrupt_Handler.USART_Input, USART_Input);
         Ready := False;
      end Wait_Event;

      ----------------------
      -- USART1_Interrupt --
      ----------------------

      procedure USART1_Interrupt is
         Raw  : HAL.UInt9;
      begin
         if USART.Status (STM32.USARTs.Read_Data_Register_Not_Empty) then

            USART.Clear_Status (STM32.USARTs.Read_Data_Register_Not_Empty);
            USART.Receive (Raw);

            Ready := True;
            USART_Input := Character'Val (Raw);

         end if;

         if USART.Status (STM32.USARTs.Transmit_Data_Register_Empty)
           and USART.Interrupt_Enabled
             (STM32.USARTs.Transmit_Data_Register_Empty)
         then

            USART.Clear_Status (STM32.USARTs.Transmit_Data_Register_Empty);
            --  USART.Transmit (HAL.UInt9 (<Value>));

            USART.Disable_Interrupts
              (STM32.USARTs.Transmit_Data_Register_Empty);

            --  Ada.Synchronous_Task_Control.Set_True (Output_Flag);
            --  Allow next write

         end if;
      end USART1_Interrupt;

   end Interrupt_Handler;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
      TX_Pin : STM32.GPIO.GPIO_Point renames STM32.Device.PA9;
      RX_Pin : STM32.GPIO.GPIO_Point renames STM32.Device.PA10;

      Pins : constant STM32.GPIO.GPIO_Points := [RX_Pin, TX_Pin];
   begin
      STM32.Device.Enable_Clock (Pins);
      STM32.Device.Enable_Clock (USART);

      STM32.GPIO.Configure_IO
        (Pins,
         (Mode           => STM32.GPIO.Mode_AF,
          Resistors      => STM32.GPIO.Pull_Up,
          AF_Output_Type => STM32.GPIO.Push_Pull,
          AF_Speed       => STM32.GPIO.Speed_50MHz,
          AF             => STM32.Device.GPIO_AF_USART1_7));

      USART.Disable;
      USART.Set_Mode (STM32.USARTs.Tx_Rx_Mode);
      USART.Set_Flow_Control (STM32.USARTs.No_Flow_Control);
      USART.Set_Baud_Rate (460800);
      USART.Set_Word_Length (STM32.USARTs.Word_Length_8);
      USART.Set_Stop_Bits (STM32.USARTs.Stopbits_1);
      USART.Set_Parity (STM32.USARTs.No_Parity);

      USART.Enable_Interrupts (STM32.USARTs.Received_Data_Not_Empty);
      USART.Enable;
   end Initialize;

   ----------------
   -- Wait_Event --
   ----------------

   procedure Wait_Event (Value : out Event) is
   begin
      Interrupt_Handler.Wait_Event (Value);
   end Wait_Event;

begin
   Initialize;
end Devices.Interrupt_Handler;
