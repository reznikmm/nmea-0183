--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Ada.Streams;

with GNAT.Serial_Communications;

package body Serial_IO is

   Port : GNAT.Serial_Communications.Serial_Port;
   Data : Ada.Streams.Stream_Element_Array (1 .. 82);
   To   : Ada.Streams.Stream_Element_Count := 0;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize
     (Port_Name : String;
      Speed     : Positive)
   is
      Image : constant String := Speed'Image;
   begin
      GNAT.Serial_Communications.Open
        (Port,
         GNAT.Serial_Communications.Port_Name (Port_Name));

      GNAT.Serial_Communications.Set
        (Port,
         Rate      => GNAT.Serial_Communications.Data_Rate'Value
           ("B" & Image (2 .. Image'Last)),
         Bits      => GNAT.Serial_Communications.CS8,
         Stop_Bits => GNAT.Serial_Communications.One,
         Parity    => GNAT.Serial_Communications.None,
         Block     => False,
         Local     => True,
         Flow      => GNAT.Serial_Communications.None,
         Timeout   => 0.0);
   end Initialize;

   -------------------
   -- Read_Sentence --
   -------------------

   procedure Read_Sentence
     (Text : out String;
      Last : out Natural)
   is
      use type Ada.Streams.Stream_Element_Array;
      use type Ada.Streams.Stream_Element_Count;

      Value : String (1 .. Data'Length)
        with Import, Address => Data'Address;

      Next : Ada.Streams.Stream_Element_Count;
   begin
      Last := Text'First - 1;
      GNAT.Serial_Communications.Read
        (Port, Data (To + 1 .. Data'Last), Next);

      --  Look for CR/LF
      for J in 1 .. Next - 1 loop
         if Data (J .. J + 1) = [16#0D#, 16#0A#] then
            Last := Natural (J - 1);

            Text (Text'First .. Text'First + Last - 1) := Value (1 .. Last);

            To := Next - J - 1;

            if To > 0 then
               Data (1 .. To) := Data (J + 2 .. Next);
            end if;

            return;
         end if;
      end loop;

      To := Next;
   end Read_Sentence;

end Serial_IO;
