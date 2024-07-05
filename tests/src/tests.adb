with NMEA_0183;

procedure Tests is
   pragma Assertion_Policy (Check);

   use all type NMEA_0183.Parse_Status;

   procedure Parse is new NMEA_0183.Generic_Parse_Message;

   procedure Test_GGA;
   procedure Test_GLL;
   procedure Test_GSA;
   procedure Test_GSV;
   procedure Test_RMC;

   procedure Test_GGA is
      use type NMEA_0183.NMEA_Message;

      GGA : constant String :=
        "$GNGGA,001043.00,4404.14036,N,12118.85961,W" &
        ",1,12,0.98,1113.0,M,21.3,M,,*6A";

      Result   : NMEA_0183.NMEA_Message;
      Status   : NMEA_0183.Parse_Status;
      Expected : constant NMEA_0183.NMEA_Message :=
        (NMEA_0183.GPS_Fixed_Data,
         (Time                    => (00, 10, 43.0),
          Latitude                => (44, 04.14036, NMEA_0183.North),
          Longitude               => (121, 18.85961, NMEA_0183.West),
          Fix_Valid               => True,
          Satellites              => 12,
          Horizontal_DOP          => 0.98,
          Altitude                => 1113.0,
          Geoid_Separation        => 21.3,
          Age_Of_Differential     => 0.0,
          Differential_Station_Id => 0));
   begin
      Parse (GGA, Result, Status);
      pragma Assert (Result = Expected);
      pragma Assert (Status = Success);
   end Test_GGA;

   procedure Test_GLL is
      use type NMEA_0183.NMEA_Message;

      GLL : constant String :=
        "$GNGLL,4404.14012,N,12118.85993,W,001037.00,A,A*67";

      Result   : NMEA_0183.NMEA_Message;
      Status   : NMEA_0183.Parse_Status;
      Expected : constant NMEA_0183.NMEA_Message :=
        (NMEA_0183.GPS_Geographic_Position,
         (Latitude                => (44, 4.14012, NMEA_0183.North),
          Longitude               => (121, 18.85993, NMEA_0183.West),
          Time                    => (00, 10, 37.00),
          Is_Valid                => True));
   begin
      Parse (GLL, Result, Status);
      pragma Assert (Result = Expected);
      pragma Assert (Status = Success);
   end Test_GLL;

   procedure Test_GSA is
      use type NMEA_0183.NMEA_Message;

      GSA : constant String :=
        "$GNGSA,A,3,80,71,73,79,69,,,,,,,,1.83,1.09,1.47*17";

      Result   : NMEA_0183.NMEA_Message;
      Status   : NMEA_0183.Parse_Status;
      Expected : constant NMEA_0183.NMEA_Message :=
        (NMEA_0183.GPS_Active_Satellites,
         (Is_Manual      => False,
          Fix_Mode       => NMEA_0183.Fix_3D,
          Satelites      => (5, List => (80, 71, 73, 79, 69)),
          Position_DOP   => 1.83,
          Horizontal_DOP => 1.09,
          Vertical_DOP   => 1.47));

   begin
      Parse (GSA, Result, Status);
      pragma Assert (Result = Expected);
      pragma Assert (Status = Success);
   end Test_GSA;

   procedure Test_GSV is
      use type NMEA_0183.NMEA_Message;

      GSV : constant String :=
        "$GPGSV,3,2,11,10,37,197,45,26,33,219,31,36,33,195,41,15,26,072,18*7E";

      Result   : NMEA_0183.NMEA_Message;
      Status   : NMEA_0183.Parse_Status;
      Expected : constant NMEA_0183.NMEA_Message :=
        (NMEA_0183.GPS_Satellites_In_View,
         (Total_Messages => 3,
          Message_Index  => 2,
          Satellites     => 11,
          List           =>
            (4,
             ((10, 37, 197, 45),
              (26, 33, 219, 31),
              (36, 33, 195, 41),
              (15, 26, 072, 18)))));
   begin
      Parse (GSV, Result, Status);
      pragma Assert (Result = Expected);
      pragma Assert (Status = Success);
   end Test_GSV;

   procedure Test_RMC is
      use type NMEA_0183.NMEA_Message;

      RMC : constant String :=
        "$GNRMC,001031.00,A,4404.13993,N,12118.86023,W,0.146,,100117,,,A*7B";

      Result   : NMEA_0183.NMEA_Message;
      Status   : NMEA_0183.Parse_Status;
      Expected : constant NMEA_0183.NMEA_Message :=
        (NMEA_0183.GPS_Data_Variant_C,
         (Time                      => (0, 10, 31.00),
          Is_Valid                  => True,
          Latitude                  => (44, 4.13993, NMEA_0183.North),
          Longitude                 => (121, 18.86023, NMEA_0183.West),
          Speed                     => 0.146,
          Course                    => 0.0,
          Date                      => (2017, 01, 10),
          Magnetic_Declination      => 0.0,
          Magnetic_Declination_Side => NMEA_0183.East));
   begin
      Parse (RMC, Result, Status);
      pragma Assert (Result = Expected);
      pragma Assert (Status = Success);
   end Test_RMC;

begin
   Test_GGA;
   Test_GLL;
   Test_GSA;
   Test_GSV;
   Test_RMC;
end Tests;
