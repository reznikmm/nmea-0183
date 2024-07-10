--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Ada.Real_Time;
with Ada.Text_IO;
with HAL.Bitmap;
with HAL.Framebuffer;

with Display_ILI9341;

with STM32.Board;
with STM32.User_Button;

with GUI;

with Updater;
pragma Unreferenced (Updater);

procedure STM32F4.Run is
   use type Ada.Real_Time.Time;

   LCD : constant not null HAL.Bitmap.Any_Bitmap_Buffer :=
     STM32.Board.TFT_Bitmap'Access;

   Next : Ada.Real_Time.Time := Ada.Real_Time.Clock;
begin
   STM32.Board.Initialize_LEDs;
   STM32.User_Button.Initialize;
   STM32.Board.Display.Initialize;
   STM32.Board.Display.Set_Orientation (HAL.Framebuffer.Landscape);

   Ada.Text_IO.Put_Line ("Boot");
   GUI.Draw (LCD.all, Clear => True);

   loop
      Next := Next + Ada.Real_Time.Milliseconds (200);
      GUI.Draw (LCD.all, Clear => False);

      delay until Next;
   end loop;
end STM32F4.Run;
