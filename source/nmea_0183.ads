--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Ada.Calendar;

package NMEA_0183 is

   type NMEA_Message_Kind is
     (GPS_Fixed_Data,
      GPS_Active_Satellites,
      GPS_Data_Variant_C);

   function GGA return NMEA_Message_Kind renames GPS_Fixed_Data;
   --  Shortcut for Global Positioning System Fixed Data

   function GSA return NMEA_Message_Kind renames GPS_Active_Satellites;
   --  Shortcut for GPS DOP and Active Satellites

   function RMC return NMEA_Message_Kind renames GPS_Data_Variant_C;
   --  Shortcut for Recommended Minimum Navigation Information variant C

   type Time is record
      Hour   : Natural range 0 .. 23;
      Minute : Natural range 0 .. 59;
      Second : Duration range 0.0 .. 60.0;
   end record;

   type Date is record
      Year  : Ada.Calendar.Year_Number;
      Month : Ada.Calendar.Month_Number;
      Day   : Ada.Calendar.Day_Number;
   end record;

   type Minute is delta 0.0001 digits 6 range 0.0 .. 59.9999;
   type Degree is delta 0.01 digits 5 range 0.0 .. 359.99;

   type Latitude_Side is (North, South);
   type Longitude_Side is (East, West);

   type Latitude is record
      Degree : Natural range 0 .. 90;
      Minute : NMEA_0183.Minute;
      Side   : Latitude_Side;
   end record;

   type Longitude is record
      Degree : Natural range 0 .. 180;
      Minute : NMEA_0183.Minute;
      Side   : Longitude_Side;
   end record;

   type Dilution_Of_Precision is delta 0.1 digits 3 range 0.0 .. 10.0;

   type Altitude is delta 0.1 digits 6 range -9_9999.9 .. 9_9999.9;
   --  Altitude in meters

   type Fixed_Data is record
      Time : NMEA_0183.Time; --  Message time (UTC)
      Latitude : NMEA_0183.Latitude;
      Longitude : NMEA_0183.Longitude;
      Fix_Valid : Boolean;
      Satellites : Natural range 0 .. 12;
      --  Number of satellites in view
      Horizontal_DOP : Dilution_Of_Precision;
      --  Horizontal Dilution of precision
      Altitude : NMEA_0183.Altitude;
      --  Altitude above/below mean-sea-level (geoid)
      Geoid_Separation : NMEA_0183.Altitude;
      --  The difference between the WGS-84 earth ellipsoid and
      --  mean-sea-level (geoid), "-" means mean-sea-level below
      --  ellipsoid
      Age_Of_Differential : Duration;
      --  Age of differential GPS data, time in seconds since last SC104
      --  type 1 or 9 update, 0.0 when DGPS is not used
      Differential_Station_Id : Natural range 0 .. 1023;
      --  Differential reference station ID
   end record;

   type Fix_Mode is (No_Fix, Fix_2D, Fix_3D);

   type Satelite_Id is range 0 .. 99;
   type Satelite_Id_Array is array (Positive range <>) of Satelite_Id;

   subtype Id_List_Length is Natural range 0 .. 12;

   type Satelite_Id_List (Length : Id_List_Length := 0) is record
      List : Satelite_Id_Array (1 .. Length);
   end record;

   type Active_Satellites is record
      Is_Manual : Boolean;  --  Forced to operate in 2D or 3D mode
      Fix_Mode : NMEA_0183.Fix_Mode;
      Satelites : Satelite_Id_List;
      Position_DOP : Dilution_Of_Precision;
      Horizontal_DOP : Dilution_Of_Precision;
      Vertical_DOP : Dilution_Of_Precision;
   end record;

   type Knots is delta 0.01 digits 5;

   type Data_Variant_C is record
      Time : NMEA_0183.Time; --  Message time (UTC)
      Is_Valid : Boolean;  --  Data is valid
      Latitude : NMEA_0183.Latitude;
      Longitude : NMEA_0183.Longitude;
      Speed : NMEA_0183.Knots;
      Course : NMEA_0183.Degree;
      Date : NMEA_0183.Date;
      Magnetic_Declination : NMEA_0183.Degree;
      Magnetic_Declination_Side : Longitude_Side;
      --  Mode ?
   end record;

   type NMEA_Message (Kind : NMEA_Message_Kind := GPS_Fixed_Data) is record
      case Kind is
         when GPS_Fixed_Data =>
            Fixed_Data : NMEA_0183.Fixed_Data;
         when GPS_Active_Satellites =>
            Active_Satellites : NMEA_0183.Active_Satellites;
         when GPS_Data_Variant_C =>
            Data_Variant_C : NMEA_0183.Data_Variant_C;
      end case;
   end record;

   type Parse_Status is (Invalid, Bad_Checksum, No_Checksum, Success);

   generic
      Parse_GGA : Boolean := True;
      Parse_GSA : Boolean := True;
   procedure Generic_Parse_Message
     (Message : String;
      Result  : out NMEA_Message;
      Status  : out Parse_Status);

   --  Values to return on empty fields
   No_Time : constant Time := (0, 0, 0.0);
   No_Date : constant Date := (Ada.Calendar.Year_Number'First, 1, 1);
   No_Latitude : constant Latitude := (0, 0.0, North);
   No_Longitude : constant Longitude := (0, 0.0, East);

end NMEA_0183;
