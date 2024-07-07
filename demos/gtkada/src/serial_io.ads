--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

package Serial_IO is

   procedure Initialize
     (Port_Name : String;
      Speed     : Positive);

   procedure Read_Sentence
     (Text : out String;
      Last : out Natural);

end Serial_IO;
