--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

pragma Ada_2022;

with Interfaces;

package body NMEA_0183 is

   function Valid_Checksum (Message : String) return Boolean;

   procedure Process_GGA
     (Fields : String;
      Result : in out NMEA_Message;
      Status : in out Parse_Status);

   function Count
     (Message : String;
      Char    : Character) return Natural;

   function Till
     (Message : String;
      From    : Positive;
      Char    : Character) return Natural;

   procedure Skip_Comma
     (Fields : String;
      From   : in out Positive;
      Empty  : out Boolean;
      Ok     : in out Boolean);

   procedure Parse_Natural
     (Fields : String;
      First  : in out Natural;
      Length : Integer;
      Value  : in out Natural;
      Ok     : in out Boolean);

   procedure Parse_Duration
     (Fields : String;
      First  : in out Natural;
      Value  : in out Duration;
      Ok     : in out Boolean);

   procedure Parse_Minute
     (Fields : String;
      First  : in out Natural;
      Value  : in out Minute;
      Ok     : in out Boolean);

   procedure Parse_Char
     (Fields  : String;
      First   : in out Natural;
      Choices : String;
      Value   : in out Character;
      Ok      : in out Boolean);

   --  Decoding field of some type includes skipping comma

   procedure Decode_Time
     (Fields : String;
      First  : in out Natural;
      Value  : in out Time;
      Ok     : in out Boolean);

   procedure Decode_Natural
     (Fields : String;
      First  : in out Natural;
      Value  : in out Natural;
      Ok     : in out Boolean);

   procedure Decode_Duration
     (Fields : String;
      First  : in out Natural;
      Value  : in out Duration;
      Ok     : in out Boolean);

   procedure Decode_DOP
     (Fields : String;
      First  : in out Natural;
      Value  : in out Dilution_Of_Precision;
      Ok     : in out Boolean);

   procedure Decode_Altitude
     (Fields : String;
      First  : in out Natural;
      Value  : in out Altitude;
      Ok     : in out Boolean);

   procedure Decode_Latitude
     (Fields : String;
      First  : in out Natural;
      Value  : in out Latitude;
      Ok     : in out Boolean);

   procedure Decode_Longitude
     (Fields : String;
      First  : in out Natural;
      Value  : in out Longitude;
      Ok     : in out Boolean);

   procedure Decode_Char
     (Fields  : String;
      First   : in out Natural;
      Choices : String;
      Value   : in out Character;
      Ok      : in out Boolean);

   -----------
   -- Count --
   -----------

   function Count
     (Message : String;
      Char    : Character) return Natural
   is
      Result : Natural := 0;
   begin
      for C of Message when C = Char loop
         Result := Result + 1;
      end loop;

      return Result;
   end Count;

   ---------------------
   -- Decode_Altitude --
   ---------------------

   procedure Decode_Altitude
     (Fields : String;
      First  : in out Natural;
      Value  : in out Altitude;
      Ok     : in out Boolean)
   is
      Last   : Natural;
      Ignore : Character := 'M';
      Empty  : Boolean;
   begin
      Skip_Comma (Fields, First, Empty, Ok);

      if Empty then
         Value := 0.0;
      elsif Ok then
         Last := Till (Fields, First, ',');

         if (for some Char of Fields (First .. Last) =>
               Char not in '0' .. '9' | '.')
           or else Count (Fields (First .. Last), '.') /= 1
           or else Last <= First
         then
            Ok := False;
         else
            Value := Altitude'Value (Fields (First .. Last));
            First := Last + 1;

            Decode_Char (Fields, First, "M", Ignore, Ok);
         end if;
      end if;
   end Decode_Altitude;

   -----------------
   -- Decode_Char --
   -----------------

   procedure Decode_Char
     (Fields  : String;
      First   : in out Natural;
      Choices : String;
      Value   : in out Character;
      Ok      : in out Boolean)
   is
      Empty : Boolean;
   begin
      Skip_Comma (Fields, First, Empty, Ok);

      if not Empty then
         Parse_Char (Fields, First, Choices, Value, Ok);
      end if;
   end Decode_Char;

   ----------------
   -- Decode_DOP --
   ----------------

   procedure Decode_DOP
     (Fields : String;
      First  : in out Natural;
      Value  : in out Dilution_Of_Precision;
      Ok     : in out Boolean)
   is
      Last : constant Natural := Till (Fields, First, ',');
      Empty : Boolean;
   begin
      Skip_Comma (Fields, First, Empty, Ok);

      if Empty then
         Value := 0.0;
      elsif Ok then
         if (for some Char of Fields (First .. Last) =>
               Char not in '0' .. '9' | '.')
           or else Count (Fields (First .. Last), '.') /= 1
           or else Last <= First
         then
            Ok := False;
         else
            Value := Dilution_Of_Precision'Value (Fields (First .. Last));
            First := Last + 1;
         end if;
      end if;
   end Decode_DOP;

   ---------------------
   -- Decode_Duration --
   ---------------------

   procedure Decode_Duration
     (Fields : String;
      First  : in out Natural;
      Value  : in out Duration;
      Ok     : in out Boolean)
   is
      Empty  : Boolean;
   begin
      Skip_Comma (Fields, First, Empty, Ok);

      if not Ok or Empty then
         Value := 0.0;
      else
         Parse_Duration (Fields, First, Value, Ok);
      end if;
   end Decode_Duration;

   ---------------------
   -- Decode_Latitude --
   ---------------------

   procedure Decode_Latitude
     (Fields : String;
      First  : in out Natural;
      Value  : in out Latitude;
      Ok     : in out Boolean)
   is
      Empty  : Boolean;
      Dot    : Natural;
      Degree : Natural := 0;
      Side   : Character := 'N';
   begin
      Skip_Comma (Fields, First, Empty, Ok);

      if not Ok or Empty then
         Value := No_Latitude;
      else
         Dot := Till (Fields, First, '.');
         Parse_Natural (Fields, First, Dot - First - 1, Degree, Ok);

         if Degree in 0 .. 90 then
            Value.Degree := Degree;
         else
            Ok := False;
         end if;

         Parse_Minute (Fields, First, Value.Minute, Ok);
         Decode_Char (Fields, First, "NS", Side, Ok);

         Value.Side := (if Ok and Side = 'S' then South else North);
      end if;
   end Decode_Latitude;

   ----------------------
   -- Decode_Longitude --
   ----------------------

   procedure Decode_Longitude
     (Fields : String;
      First  : in out Natural;
      Value  : in out Longitude;
      Ok     : in out Boolean)
   is
      Empty  : Boolean;
      Dot    : Natural;
      Degree : Natural := 0;
      Side   : Character := 'E';
   begin
      Skip_Comma (Fields, First, Empty, Ok);

      if not Ok or Empty then
         Value := No_Longitude;
      else
         Dot := Till (Fields, First, '.');
         Parse_Natural (Fields, First, Dot - First - 1, Degree, Ok);

         if Degree in 0 .. 180 then
            Value.Degree := Degree;
         else
            Ok := False;
         end if;

         Parse_Minute (Fields, First, Value.Minute, Ok);
         Decode_Char (Fields, First, "EW", Side, Ok);

         Value.Side := (if Ok and Side = 'W' then West else East);
      end if;
   end Decode_Longitude;

   --------------------
   -- Decode_Natural --
   --------------------

   procedure Decode_Natural
     (Fields : String;
      First  : in out Natural;
      Value  : in out Natural;
      Ok     : in out Boolean)
   is
      Empty  : Boolean;
      Length : Natural;
   begin
      Skip_Comma (Fields, First, Empty, Ok);

      if not Ok or Empty then
         Value := 0;
      else
         Length := Till (Fields, First, ',') - First + 1;
         Parse_Natural (Fields, First, Length, Value, Ok);
      end if;
   end Decode_Natural;

   -----------------
   -- Decode_Time --
   -----------------

   procedure Decode_Time
     (Fields : String;
      First  : in out Natural;
      Value  : in out Time;
      Ok     : in out Boolean)
   is
      Second : Duration := 0.0;
      Empty  : Boolean;
   begin
      Skip_Comma (Fields, First, Empty, Ok);

      if not Ok or Empty then
         Value := No_Time;
      else
         Parse_Natural (Fields, First, 2, Value.Hour, Ok);
         Parse_Natural (Fields, First, 2, Value.Minute, Ok);
         Parse_Duration (Fields, First, Second, Ok);

         if Ok and then Second in 0.0 .. 60.0 then
            Value.Second := Second;
         else
            Value := No_Time;
            Ok := False;
         end if;
      end if;
   end Decode_Time;

   ---------------------------
   -- Generic_Parse_Message --
   ---------------------------

   procedure Generic_Parse_Message
     (Message : String;
      Result  : out NMEA_Message;
      Status  : out Parse_Status)
   is

      procedure Decode_GGA
        (Message : String;
         Last    : Positive;
         Result  : out NMEA_Message;
         Status  : in out Parse_Status);

      ----------------
      -- Decode_GGA --
      ----------------

      procedure Decode_GGA
        (Message : String;
         Last    : Positive;
         Result  : out NMEA_Message;
         Status  : in out Parse_Status) is
      begin
         if Parse_GGA then
            Process_GGA (Message (Message'First + 6 .. Last), Result, Status);
         else
            Status := Invalid;
         end if;
      end Decode_GGA;

      Last : Positive := Message'Last;

   begin
      if Message'Length < 6 or else Message (Message'First) /= '$' then
         Status := Invalid;
         return;
      elsif Message (Message'Last - 2) /= '*' then
         Status := No_Checksum;
      elsif Valid_Checksum (Message) then
         Last := Message'Last - 3;
         Status := Success;
      else
         Status := Bad_Checksum;
         return;
      end if;

      declare
         Id   : String renames
           Message (Message'First + 1 .. Message'First + 2);
         --  talker identifier
         Code : String renames
           Message (Message'First + 3 .. Message'First + 5);
         --  sentence identifier
      begin
         if Id (Id'First) /= 'P' and then Code = "GGA" then
            Decode_GGA (Message, Last, Result, Status);
         else
            Status := Invalid;
         end if;
      end;
   end Generic_Parse_Message;

   ----------------
   -- Parse_Char --
   ----------------

   procedure Parse_Char
     (Fields  : String;
      First   : in out Natural;
      Choices : String;
      Value   : in out Character;
      Ok      : in out Boolean) is
   begin
      if Ok then
         if First <= Fields'Last then
            for Char of Choices loop
               if Fields (First) = Char then
                  First := First + 1;
                  Value := Char;
                  return;
               end if;
            end loop;
         end if;

         Ok := False;
      end if;
   end Parse_Char;

   --------------------
   -- Parse_Duration --
   --------------------

   procedure Parse_Duration
     (Fields : String;
      First  : in out Natural;
      Value  : in out Duration;
      Ok     : in out Boolean)
   is
      Last : constant Natural := Till (Fields, First, ',');
   begin
      if Ok then
         if (for some Char of Fields (First .. Last) =>
               Char not in '0' .. '9' | '.')
           or else Count (Fields (First .. Last), '.') /= 1
           or else Last <= First
         then
            Ok := False;
         else
            Value := Duration'Value (Fields (First .. Last));
            First := Last + 1;
         end if;
      end if;
   end Parse_Duration;

   ------------------
   -- Parse_Minute --
   ------------------

   procedure Parse_Minute
     (Fields : String;
      First  : in out Natural;
      Value  : in out Minute;
      Ok     : in out Boolean)
   is
      Last : constant Natural := Till (Fields, First, ',');
      Raw  : Minute'Base;
   begin
      if Ok then
         if (for some Char of Fields (First .. Last) =>
               Char not in '0' .. '9' | '.')
           or else Count (Fields (First .. Last), '.') /= 1
           or else Last <= First
         then
            Ok := False;
         else
            Raw := Minute'Value (Fields (First .. Last));
            First := Last + 1;

            if Raw in Minute then
               Value := Raw;
            else
               Ok := False;
            end if;
         end if;
      end if;
   end Parse_Minute;

   -------------------
   -- Parse_Natural --
   -------------------

   procedure Parse_Natural
     (Fields : String;
      First  : in out Natural;
      Length : Integer;
      Value  : in out Natural;
      Ok     : in out Boolean)
   is
      Last : constant Positive := First + Length - 1;
   begin
      if Length <= 0 then
         Ok := False;
      elsif Ok then
         if Last > Fields'Last or else
           (for some Char of Fields (First .. Last) => Char not in '0' .. '9')
         then
            Ok := False;
         else
            Value := Natural'Value (Fields (First .. Last));
            First := First + Length;
         end if;
      end if;
   end Parse_Natural;

   -----------------
   -- Process_GGA --
   -----------------

   procedure Process_GGA
     (Fields : String;
      Result : in out NMEA_Message;
      Status : in out Parse_Status)
   is

      procedure Decode_Fix_Valid
        (Fields : String;
         First  : in out Natural;
         Value  : in out Boolean;
         Ok     : in out Boolean);

      ----------------------
      -- Decode_Fix_Valid --
      ----------------------

      procedure Decode_Fix_Valid
        (Fields : String;
         First  : in out Natural;
         Value  : in out Boolean;
         Ok     : in out Boolean)
      is
         Empty  : Boolean;
         Result : Character := '0';
      begin
         Skip_Comma (Fields, First, Empty, Ok);

         if not Ok or Empty then
            Value := False;
         else
            Parse_Char (Fields, First, "0123456", Result, Ok);
            Value := Ok and then Result in '1' | '2' | '6';
         end if;
      end Decode_Fix_Valid;


      First      : Natural := 7;
      Ok         : Boolean := True;
      Satelites  : Natural := 0;
      Fixed_Data : NMEA_0183.Fixed_Data :=
        (Time                    => No_Time,
         Latitude                => No_Latitude,
         Longitude               => No_Longitude,
         Fix_Valid               => False,
         Satellites              => 0,
         Horizontal_DOP          => 0.0,
         Altitude                => 0.0,
         Geoid_Separation        => 0.0,
         Age_Of_Differential     => 0.0,
         Differential_Station_Id => 0);
   begin
      Decode_Time (Fields, First, Fixed_Data.Time, Ok);
      Decode_Latitude (Fields, First, Fixed_Data.Latitude, Ok);
      Decode_Longitude (Fields, First, Fixed_Data.Longitude, Ok);
      Decode_Fix_Valid (Fields, First, Fixed_Data.Fix_Valid, Ok);
      Decode_Natural (Fields, First, Satelites, Ok);

      if Satelites in 0 .. 12 then
         Fixed_Data.Satellites := Satelites;
      else
         Ok := False;
      end if;

      Decode_DOP (Fields, First, Fixed_Data.Horizontal_DOP, Ok);
      Decode_Altitude (Fields, First, Fixed_Data.Altitude, Ok);
      Decode_Altitude (Fields, First, Fixed_Data.Geoid_Separation, Ok);
      Decode_Duration (Fields, First, Fixed_Data.Age_Of_Differential, Ok);
      Decode_Natural (Fields, First, Fixed_Data.Differential_Station_Id, Ok);

      if Ok then
         Result := (GPS_Fixed_Data, Fixed_Data);
      else
         Status := Invalid;
      end if;
   end Process_GGA;

   ----------------
   -- Skip_Comma --
   ----------------

   procedure Skip_Comma
     (Fields : String;
      From   : in out Positive;
      Empty  : out Boolean;
      Ok     : in out Boolean) is
   begin
      Empty := True;

      if Ok then
         if From <= Fields'Last and then Fields (From) = ',' then
            From := From + 1;
            Empty := From > Fields'Last or else Fields (From) = ',';
         else
            Ok := False;
         end if;
      end if;
   end Skip_Comma;

   ----------
   -- Till --
   ----------

   function Till
     (Message : String;
      From    : Positive;
      Char    : Character) return Natural is
   begin
      for J in From .. Message'Last loop
         if Message (J) = Char then
            return J - 1;
         end if;
      end loop;

      return Message'Last;
   end Till;

   --------------------
   -- Valid_Checksum --
   --------------------

   function Valid_Checksum (Message : String) return Boolean is
      use type Interfaces.Unsigned_8;

      Tail : constant String (1 .. 2) :=
        Message (Message'Last - 1 .. Message'Last);

      function Plus
        (Left, Right : Interfaces.Unsigned_8) return Interfaces.Unsigned_8
          renames "xor";

      Result   : constant Interfaces.Unsigned_8 :=
        [for Char of Message (Message'First + 1 .. Message'Last - 3)
           => Character'Pos (Char)]'Reduce (Plus, 0);

      Checksum : Interfaces.Unsigned_8;

   begin
      if (for some Char of Message (Message'Last - 1 .. Message'Last) =>
            Char not in '0' .. '9' | 'A' .. 'F')
      then
         return False;
      end if;

      Checksum := Interfaces.Unsigned_8'Value ("16#" & Tail & "#");

      return Result = Checksum;
   end Valid_Checksum;

end NMEA_0183;
