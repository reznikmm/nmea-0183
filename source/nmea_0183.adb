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

   procedure Process_GLL
     (Fields : String;
      Result : in out NMEA_Message;
      Status : in out Parse_Status);

   procedure Process_GSA
     (Fields : String;
      Result : in out NMEA_Message;
      Status : in out Parse_Status);

   procedure Process_GSV
     (Fields : String;
      Result : in out NMEA_Message;
      Status : in out Parse_Status);

   procedure Process_RMC
     (Fields : String;
      Result : in out NMEA_Message;
      Status : in out Parse_Status);

   procedure Process_VTG
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

   procedure Decode_Char
     (Fields  : String;
      First   : in out Natural;
      Choices : String;
      Value   : in out Character;
      Ok      : in out Boolean);

   generic
      type Number is private;
      Default : Number;
      with function To_Number (X : String) return Number;
      Suffix : String;
   procedure Decode_Number
     (Fields : String;
      First  : in out Natural;
      Value  : in out Number;
      Ok     : in out Boolean);

   -------------------
   -- Decode_Number --
   -------------------

   procedure Decode_Number
     (Fields : String;
      First  : in out Natural;
      Value  : in out Number;
      Ok     : in out Boolean)
   is
      Last   : Natural;
      Empty  : Boolean;
      Ignore : Character;
   begin
      Skip_Comma (Fields, First, Empty, Ok);

      if Empty then
         Value := Default;
      elsif Ok then
         Last := Till (Fields, First, ',');

         if (for some Char of Fields (First .. Last) =>
               Char not in '0' .. '9' | '.')
           or else Count (Fields (First .. Last), '.') /= 1
           or else Last <= First
         then
            Ok := False;
         else
            Value := To_Number (Fields (First .. Last));
            First := Last + 1;

            if Suffix /= "" then
               Decode_Char (Fields, First, "M", Ignore, Ok);
            end if;
         end if;
      end if;
   end Decode_Number;

   procedure Decode_Degree is new Decode_Number
     (Number    => Degree,
      Default   => 0.0,
      To_Number => Degree'Value,
      Suffix    => "");

   procedure Decode_Time
     (Fields : String;
      First  : in out Natural;
      Value  : in out Time;
      Ok     : in out Boolean);

   procedure Decode_Date
     (Fields : String;
      First  : in out Natural;
      Value  : in out Date;
      Ok     : in out Boolean);

   procedure Decode_Natural
     (Fields  : String;
      First   : in out Natural;
      Default : Natural;
      Value   : in out Natural;
      Ok      : in out Boolean);

   procedure Decode_Duration
     (Fields : String;
      First  : in out Natural;
      Value  : in out Duration;
      Ok     : in out Boolean);

   procedure Decode_DOP is new Decode_Number
     (Number    => Dilution_Of_Precision,
      Default   => 0.0,
      To_Number => Dilution_Of_Precision'Value,
      Suffix    => "");

   procedure Decode_Altitude
     (Fields : String;
      First  : in out Natural;
      Value  : in out Altitude;
      Ok     : in out Boolean);

   procedure Decode_Speed is new Decode_Number
     (Number    => Speed,
      Default   => 0.0,
      To_Number => Speed'Value,
      Suffix    => "");

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
         --  TBD: Skip '-'
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

   -----------------
   -- Decode_Date --
   -----------------

   procedure Decode_Date
     (Fields : String;
      First  : in out Natural;
      Value  : in out Date;
      Ok     : in out Boolean)
   is
      Empty : Boolean;
      Year  : Natural := 0;
   begin
      Skip_Comma (Fields, First, Empty, Ok);

      if not Ok or Empty then
         Value := No_Date;
      else
         Parse_Natural (Fields, First, 2, Value.Day, Ok);
         Parse_Natural (Fields, First, 2, Value.Month, Ok);
         Parse_Natural (Fields, First, 2, Year, Ok);
         Value.Year := 2000 + Year;

         if not Ok then
            Value := No_Date;
         end if;
      end if;
   end Decode_Date;

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
     (Fields  : String;
      First   : in out Natural;
      Default : Natural;
      Value   : in out Natural;
      Ok      : in out Boolean)
   is
      Empty  : Boolean;
      Length : Natural;
   begin
      Skip_Comma (Fields, First, Empty, Ok);

      if not Ok then
         null;
      elsif Empty then
         Value := Default;
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

      procedure Decode_GLL
        (Message : String;
         Last    : Positive;
         Result  : out NMEA_Message;
         Status  : in out Parse_Status);

      procedure Decode_GSA
        (Message : String;
         Last    : Positive;
         Result  : out NMEA_Message;
         Status  : in out Parse_Status);

      procedure Decode_GSV
        (Message : String;
         Last    : Positive;
         Result  : out NMEA_Message;
         Status  : in out Parse_Status);

      procedure Decode_RMC
        (Message : String;
         Last    : Positive;
         Result  : out NMEA_Message;
         Status  : in out Parse_Status);

      procedure Decode_VTG
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

      ----------------
      -- Decode_GLL --
      ----------------

      procedure Decode_GLL
        (Message : String;
         Last    : Positive;
         Result  : out NMEA_Message;
         Status  : in out Parse_Status) is
      begin
         if Parse_GLL then
            Process_GLL (Message (Message'First + 6 .. Last), Result, Status);
         else
            Status := Invalid;
         end if;
      end Decode_GLL;

      ----------------
      -- Decode_GSA --
      ----------------

      procedure Decode_GSA
        (Message : String;
         Last    : Positive;
         Result  : out NMEA_Message;
         Status  : in out Parse_Status) is
      begin
         if Parse_GSA then
            Process_GSA (Message (Message'First + 6 .. Last), Result, Status);
         else
            Status := Invalid;
         end if;
      end Decode_GSA;

      ----------------
      -- Decode_GSV --
      ----------------

      procedure Decode_GSV
        (Message : String;
         Last    : Positive;
         Result  : out NMEA_Message;
         Status  : in out Parse_Status) is
      begin
         if Parse_GSV then
            Process_GSV (Message (Message'First + 6 .. Last), Result, Status);
         else
            Status := Invalid;
         end if;
      end Decode_GSV;

      ----------------
      -- Decode_RMC --
      ----------------

      procedure Decode_RMC
        (Message : String;
         Last    : Positive;
         Result  : out NMEA_Message;
         Status  : in out Parse_Status) is
      begin
         if Parse_RMC then
            Process_RMC (Message (Message'First + 6 .. Last), Result, Status);
         else
            Status := Invalid;
         end if;
      end Decode_RMC;

      ----------------
      -- Decode_VTG --
      ----------------

      procedure Decode_VTG
        (Message : String;
         Last    : Positive;
         Result  : out NMEA_Message;
         Status  : in out Parse_Status) is
      begin
         if Parse_VTG then
            Process_VTG (Message (Message'First + 6 .. Last), Result, Status);
         else
            Status := Invalid;
         end if;
      end Decode_VTG;

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
         elsif Id (Id'First) /= 'P' and then Code = "GLL" then
            Decode_GLL (Message, Last, Result, Status);
         elsif Id (Id'First) /= 'P' and then Code = "GSA" then
            Decode_GSA (Message, Last, Result, Status);
         elsif Id (Id'First) /= 'P' and then Code = "GSV" then
            Decode_GSV (Message, Last, Result, Status);
         elsif Id (Id'First) /= 'P' and then Code = "RMC" then
            Decode_RMC (Message, Last, Result, Status);
         elsif Id (Id'First) /= 'P' and then Code = "VTG" then
            Decode_VTG (Message, Last, Result, Status);
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
      Raw  : Base_Minute'Base;
   begin
      if Ok then
         if (for some Char of Fields (First .. Last) =>
               Char not in '0' .. '9' | '.')
           or else Count (Fields (First .. Last), '.') /= 1
           or else Last <= First
         then
            Ok := False;
         else
            Raw := Base_Minute'Value (Fields (First .. Last));
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

      First      : Natural := Fields'First;
      Ok         : Boolean := True;
      Int_Value  : Natural := 0;
      Value : NMEA_0183.Fixed_Data :=
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
      Decode_Time (Fields, First, Value.Time, Ok);
      Decode_Latitude (Fields, First, Value.Latitude, Ok);
      Decode_Longitude (Fields, First, Value.Longitude, Ok);
      Decode_Fix_Valid (Fields, First, Value.Fix_Valid, Ok);
      Decode_Natural (Fields, First, 0, Int_Value, Ok);

      if Int_Value in 0 .. 12 then
         Value.Satellites := Int_Value;
      else
         Ok := False;
      end if;

      Decode_DOP (Fields, First, Value.Horizontal_DOP, Ok);
      Decode_Altitude (Fields, First, Value.Altitude, Ok);
      Decode_Altitude (Fields, First, Value.Geoid_Separation, Ok);
      Decode_Duration (Fields, First, Value.Age_Of_Differential, Ok);
      Decode_Natural (Fields, First, 0, Int_Value, Ok);

      if Int_Value in 0 .. 1023 then
         Value.Differential_Station_Id := Int_Value;
      else
         Ok := False;
      end if;

      if Ok then
         Result := (GPS_Fixed_Data, Value);
      else
         Status := Invalid;
      end if;
   end Process_GGA;

   -----------------
   -- Process_GLL --
   -----------------

   procedure Process_GLL
     (Fields : String;
      Result : in out NMEA_Message;
      Status : in out Parse_Status)
   is

      procedure Decode_Is_Valid
        (Fields : String;
         First  : in out Natural;
         Value  : in out Boolean;
         Ok     : in out Boolean);

      ---------------------
      -- Decode_Is_Valid --
      ---------------------

      procedure Decode_Is_Valid
        (Fields : String;
         First  : in out Natural;
         Value  : in out Boolean;
         Ok     : in out Boolean)
      is
         Empty  : Boolean;
         Result : Character := 'V';
      begin
         Skip_Comma (Fields, First, Empty, Ok);

         if not Ok or Empty then
            Value := False;
         else
            Parse_Char (Fields, First, "AV", Result, Ok);
            Value := Ok and then Result = 'A';
         end if;
      end Decode_Is_Valid;

      First : Natural := Fields'First;
      Ok    : Boolean := True;
      Value : NMEA_0183.Geographic_Position :=
        (Latitude  => No_Latitude,
         Longitude => No_Longitude,
         Time      => No_Time,
         Is_Valid  => False);
   begin
      Decode_Latitude (Fields, First, Value.Latitude, Ok);
      Decode_Longitude (Fields, First, Value.Longitude, Ok);
      Decode_Time (Fields, First, Value.Time, Ok);
      Decode_Is_Valid (Fields, First, Value.Is_Valid, Ok);

      if Ok then
         Result := (GPS_Geographic_Position, Value);
      else
         Status := Invalid;
      end if;
   end Process_GLL;

   -----------------
   -- Process_GSA --
   -----------------

   procedure Process_GSA
     (Fields : String;
      Result : in out NMEA_Message;
      Status : in out Parse_Status)
   is
      First : Natural := Fields'First;
      Ok    : Boolean := True;
      Char  : Character := 'M';
      List  : Satelite_Id_Array (1 .. 12);
      Last  : Natural := 0;

      Value : NMEA_0183.Active_Satellites :=
        (Is_Manual      => False,
         Fix_Mode       => NMEA_0183.No_Fix,
         Satelites      => (Length => 0, List => <>),
         Position_DOP   => 0.0,
         Horizontal_DOP => 0.0,
         Vertical_DOP   => 0.0);
   begin
      Decode_Char (Fields, First, "MA", Char, Ok);
      Value.Is_Manual := Char = 'M';

      Decode_Char (Fields, First, "123", Char, Ok);
      Value.Fix_Mode :=
        (case Char is
            when '3' => Fix_3D,
            when '2' => Fix_2D,
            when others => No_Fix);

      for J in List'Range loop
         declare
            Item : Natural := 0;
         begin
            Decode_Natural (Fields, First, Natural'Last, Item, Ok);

            if Item = Natural'Last then
               null;
            elsif Item in 0 .. 99 then
               Last := Last + 1;
               List (Last) := Satelite_Id (Item);
            else
               Ok := False;
            end if;
         end;
      end loop;

      Value.Satelites := (Last, List (1 .. Last));

      Decode_DOP (Fields, First, Value.Position_DOP, Ok);
      Decode_DOP (Fields, First, Value.Horizontal_DOP, Ok);
      Decode_DOP (Fields, First, Value.Vertical_DOP, Ok);

      if Ok then
         Result := (GPS_Active_Satellites, Value);
      else
         Status := Invalid;
      end if;
   end Process_GSA;

   -----------------
   -- Process_GSV --
   -----------------

   procedure Process_GSV
     (Fields : String;
      Result : in out NMEA_Message;
      Status : in out Parse_Status)
   is
      First : Natural := Fields'First;
      Ok    : Boolean := True;
      List  : Satellite_In_View_Array (1 .. 4);
      Last  : Satellite_In_View_Length := 0;
      Value : NMEA_0183.Satellites_In_View :=
        (Total_Messages => 1,
         Message_Index  => 1,
         Satellites     => 0,
         List           => <>);
   begin
      Decode_Natural (Fields, First, 0, Value.Total_Messages, Ok);
      Decode_Natural (Fields, First, 0, Value.Message_Index, Ok);
      Decode_Natural (Fields, First, 0, Value.Satellites, Ok);

      for J in List'Range loop
         declare
            Item : Satellite_In_View := (0, 0, 0, 0);
            Id   : Natural := 0;
         begin
            Decode_Natural (Fields, First, 0, Id, Ok);
            Decode_Natural (Fields, First, 0, Item.Elevation, Ok);
            Decode_Natural (Fields, First, 0, Item.Azimuth, Ok);
            Decode_Natural (Fields, First, 0, Item.SNR, Ok);

            if Id in 1 .. 99 then
               Item.Satelite_Id := Satelite_Id (Id);
               Last := Last + 1;
               List (Last) := Item;
            end if;
         end;
      end loop;

      Value.List := (Last, List (1 .. Last));

      if Ok then
         Result := (GPS_Satellites_In_View, Value);
      else
         Status := Invalid;
      end if;
   end Process_GSV;

   -----------------
   -- Process_RMC --
   -----------------

   procedure Process_RMC
     (Fields : String;
      Result : in out NMEA_Message;
      Status : in out Parse_Status)
   is
      First : Natural := Fields'First;
      Ok    : Boolean := True;
      Char  : Character := 'V';
      Value : NMEA_0183.Data_Variant_C :=
        (Time                      => No_Time,
         Is_Valid                  => False,
         Latitude                  => No_Latitude,
         Longitude                 => No_Longitude,
         Speed                     => 0.0,
         Course                    => 0.0,
         Date                      => No_Date,
         Magnetic_Declination      => 0.0,
         Magnetic_Declination_Side => East);
   begin
      Decode_Time (Fields, First, Value.Time, Ok);
      Decode_Char (Fields, First, "AV", Char, Ok);
      Value.Is_Valid := Char = 'A';
      Decode_Latitude (Fields, First, Value.Latitude, Ok);
      Decode_Longitude (Fields, First, Value.Longitude, Ok);
      Decode_Speed (Fields, First, Value.Speed, Ok);
      Decode_Degree (Fields, First, Value.Course, Ok);
      Decode_Date (Fields, First, Value.Date, Ok);
      Decode_Degree (Fields, First, Value.Magnetic_Declination, Ok);
      Decode_Char (Fields, First, "EW", Char, Ok);

      Value.Magnetic_Declination_Side :=
        (if Ok and Char = 'W' then West else East);

      if Ok then
         Result := (GPS_Data_Variant_C, Value);
      else
         Status := Invalid;
      end if;
   end Process_RMC;

   -----------------
   -- Process_VTG --
   -----------------

   procedure Process_VTG
     (Fields : String;
      Result : in out NMEA_Message;
      Status : in out Parse_Status)
   is
      First : Natural := Fields'First;
      Ok    : Boolean := True;
      Char  : Character := 'T';
      Value : NMEA_0183.Ground_Speed :=
        (True_Course     => 0.0,
         Magnetic_Course => 0.0,
         Speed_Knots     => 0.0,
         Speed_KM_H      => 0.0);
   begin
      Decode_Degree (Fields, First, Value.True_Course, Ok);
      Decode_Char (Fields, First, "T", Char, Ok);
      Decode_Degree (Fields, First, Value.Magnetic_Course, Ok);
      Decode_Char (Fields, First, "M", Char, Ok);
      Decode_Speed (Fields, First, Value.Speed_Knots, Ok);
      Decode_Char (Fields, First, "N", Char, Ok);
      Decode_Speed (Fields, First, Value.Speed_KM_H, Ok);
      Decode_Char (Fields, First, "K", Char, Ok);

      if Ok then
         Result := (GPS_Ground_Speed, Value);
      else
         Status := Invalid;
      end if;
   end Process_VTG;

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
