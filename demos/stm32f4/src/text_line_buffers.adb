--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

package body Text_Line_Buffers is

   LF : constant Character := Character'Val (10);
   CR : constant Character := Character'Val (13);

   -----------------
   -- Line_Buffer --
   -----------------

   protected body Line_Buffer is

      -----------
      -- Write --
      -----------

      procedure Write
        (Item    : Character;
         Is_Full : out Boolean)
      is
         Index : constant Positive := Data (Active).Last + 1;
      begin
         if Item = LF then

            --  Check if we have CR before LF and drop it
            if Index - 1 in Line_String'Range
              and then Data (Active).Text (Index - 1) = CR
            then
               Data (Active).Last := Index - 2;
            end if;

            Is_Full := Has_Text;
            Active := 3 - Active;  --  Swap active line in Data
            Data (Active).Last := 0;
            Has_Text := True;

         else
            Is_Full := False;
            Data (Active).Last := Index;

            if Index in Line_String'Range then
               Data (Active).Text (Index) := Item;
            end if;
         end if;
      end Write;

      ----------
      -- Read --
      ----------

      entry Read
        (Text : out String;
         Last : out Natural) when Has_Text
      is
         Inactive : constant Positive range Text_Line_Array'Range :=
           3 - Active;
      begin
         Last := Natural'Min (Text'Length, Data (Inactive).Last);
         Text (Text'First .. Text'First + Last - 1) :=
           Data (Inactive).Text (1 .. Last);
         Has_Text := False;
      end Read;

   end Line_Buffer;

   ---------------
   -- Read_Line --
   ---------------

   procedure Read_Line
     (Self : in out Line_Buffer;
      Text : out String;
      Last : out Natural) is
   begin
      Self.Read (Text, Last);
   end Read_Line;

   ---------------------
   -- Write_Character --
   ---------------------

   procedure Write_Character
     (Self    : in out Line_Buffer;
      Item    : Character;
      Is_Full : out Boolean) is
   begin
      Self.Write (Item, Is_Full);
   end Write_Character;

end Text_Line_Buffers;
