--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with System;

package Text_Line_Buffers is
   pragma Pure;

   type Line_Buffer (Priority : System.Priority) is limited private;
   --  This buffer keeps characters grouped into lines separated by CR, LF.

   procedure Write_Character
     (Self    : in out Line_Buffer;
      Item    : Character;
      Is_Full : out Boolean);

   procedure Read_Line
     (Self : in out Line_Buffer;
      Text : out String;
      Last : out Natural)
         with Pre => Text'Length <= 80;

private

   subtype Line_String is String (1 .. 81);

   type Text_Line is record
      Text : Line_String;
      Last : Natural;
   end record;

   type Text_Line_Array is array (1 .. 2) of Text_Line;
   --  Buffer for two lines

   protected type Line_Buffer (Priority : System.Priority) is
      procedure Write
        (Item    : Character;
         Is_Full : out Boolean);

      entry Read
        (Text : out String;
         Last : out Natural)
           with Pre => Text'Length <= 80;

   private
      pragma Priority (Priority);

      Data     : Text_Line_Array := [1 .. 2 => (Text => <>, Last => 0)];
      Active   : Positive := 1;  --  Index in Data to write characters
      Has_Text : Boolean := False;
      --  If Has_Text then Data(not Active) has a complete line
   end Line_Buffer;

end Text_Line_Buffers;
