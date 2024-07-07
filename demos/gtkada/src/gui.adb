--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Ada.Numerics.Elementary_Functions;

with Bitmapped_Drawing;
with BMP_Fonts;

package body GUI is

   type GUI_State is record
      Satelites : NMEA_0183.Satellite_In_View_Array (1 .. 30);
      Last_Sat  : Natural := 0;
      Next_Sat  : Natural := 0;

      Has_Fix   : Boolean := False;
      Sat_Count : Natural := 0;

      Latitude  : NMEA_0183.Latitude;
      Longitude : NMEA_0183.Longitude;
      Altitude  : NMEA_0183.Altitude;

      Timestamp : Natural := 0;
   end record;

   Timestamp : Natural := 0;

   State : GUI_State;

   procedure Draw_Satelite
     (LCD : in out HAL.Bitmap.Bitmap_Buffer'Class;
      Sat : NMEA_0183.Satellite_In_View);

   -------------------
   -- Draw_Satelite --
   -------------------

   procedure Draw_Satelite
     (LCD : in out HAL.Bitmap.Bitmap_Buffer'Class;
      Sat : NMEA_0183.Satellite_In_View)
   is
      use Ada.Numerics.Elementary_Functions;

      function Radian (Degree : Natural) return Float is
         (Float (Degree) * Ada.Numerics.Pi / 180.0);

      Bold   : constant Positive := Positive'Max (1, Sat.SNR / 10);

      Max    : constant Positive :=
        Natural'Min (LCD.Width, LCD.Height) / 2 - Bold;

      Radius : constant Float := Float (Max) * Cos (Radian (Sat.Elevation));
      X      : constant Float := Radius * Sin (Radian (Sat.Azimuth) + 90.0);
      Y      : constant Float := Radius * Cos (Radian (Sat.Azimuth) + 90.0);
   begin
      LCD.Set_Source (HAL.Bitmap.Green);

      LCD.Fill_Circle
        (Center =>
           (X => LCD.Width / 2 + Integer (X),
            Y => LCD.Height / 2 + Integer (Y)),
          Radius => Bold);
   end Draw_Satelite;

   procedure Draw
     (LCD   : in out HAL.Bitmap.Bitmap_Buffer'Class;
      Clear : Boolean := False)
   is
      procedure Put_Line
        (Text   : String;
         Font   : BMP_Fonts.BMP_Font;
         Line   : Positive := 1;
         Left   : Boolean := True;
         Top    : Boolean := True;
         Color  : HAL.Bitmap.Bitmap_Color := HAL.Bitmap.White;
         Ground : HAL.Bitmap.Bitmap_Color := HAL.Bitmap.Black);

      procedure Put_Line
        (Text   : String;
         Font   : BMP_Fonts.BMP_Font;
         Line   : Positive := 1;
         Left   : Boolean := True;
         Top    : Boolean := True;
         Color  : HAL.Bitmap.Bitmap_Color := HAL.Bitmap.White;
         Ground : HAL.Bitmap.Bitmap_Color := HAL.Bitmap.Black)
      is
         Image : String renames
           Text
             ((if Text'Length > 0 and then Text (Text'First) = ' '
               then Text'First + 1 else Text'First)
              .. Text'Last);

         Char_Height : constant Positive := BMP_Fonts.Char_Height (Font) + 3;

         X : constant Natural :=
           (if Left then 1
            else LCD.Width - BMP_Fonts.Char_Width (Font) * Image'Length);

         Y : constant Natural :=
           (if Top then Char_Height * (Line - 1)
            else LCD.Height - Char_Height * Line - 1);
      begin
         Bitmapped_Drawing.Draw_String
           (Buffer     => LCD,
            Start      => (X, Y),
            Msg        => Image,
            Font       => Font,
            Foreground => Color,
            Background => Ground);
      end Put_Line;

   begin
      if Clear then
         LCD.Set_Source (HAL.Bitmap.Black);
         LCD.Fill;
         LCD.Set_Source (HAL.Bitmap.Dark_Green);
         LCD.Draw_Circle
           (Center => (LCD.Width / 2, LCD.Height / 2),
            Radius => Natural'Min (LCD.Width, LCD.Height) / 2 - 1);
         Timestamp := State.Timestamp + 1;
      end if;

      if State.Timestamp /= Timestamp then
         for S of State.Satelites (1 .. State.Last_Sat) loop
            Draw_Satelite (LCD, S);
         end loop;

         Put_Line
           ("Sat:" & State.Sat_Count'Image,
            BMP_Fonts.Font16x24,
            Left   => False,
            Top    => False,
            Ground => (if State.Has_Fix then HAL.Bitmap.Green
                       else HAL.Bitmap.Dark_Red));

         if State.Has_Fix then
            --  Latitude
            Put_Line
              (Text => State.Latitude.Degree'Image &
                          State.Latitude.Minute'Image,
               Font => BMP_Fonts.Font8x8,
               Line => 1);

            --  Longitude
            Put_Line
              (Text => State.Longitude.Degree'Image &
                          State.Longitude.Minute'Image,
               Font => BMP_Fonts.Font8x8,
               Line => 2);

            --  Altitude
            Put_Line
              (Text => "Alt:" & State.Altitude'Image,
               Font => BMP_Fonts.Font8x8,
               Left => False);
         end if;

         Timestamp := State.Timestamp;
      end if;
   end Draw;

   ----------
   -- Show --
   ----------

   procedure Show (Value : NMEA_0183.NMEA_Message) is
      use all type NMEA_0183.NMEA_Message_Kind;

      procedure Satellites_In_View (Value : NMEA_0183.Satellites_In_View);
      procedure Fixed_Data (Value : NMEA_0183.Fixed_Data);

      Timestamp : constant Natural := State.Timestamp;

      procedure Fixed_Data (Value : NMEA_0183.Fixed_Data) is
         use type NMEA_0183.Altitude;
         use type NMEA_0183.Latitude;
         use type NMEA_0183.Longitude;
      begin
         if State.Has_Fix /= Value.Fix_Valid then
            State.Has_Fix := Value.Fix_Valid;
            State.Timestamp := Timestamp + 1;
         end if;

         if State.Sat_Count /= Value.Satellites then
            State.Sat_Count := Value.Satellites;
            State.Timestamp := Timestamp + 1;
         end if;

         if State.Latitude /= Value.Latitude then
            State.Latitude := Value.Latitude;
            State.Timestamp := Timestamp + 1;
         end if;

         if State.Longitude /= Value.Longitude then
            State.Longitude := Value.Longitude;
            State.Timestamp := Timestamp + 1;
         end if;

         if State.Altitude /= Value.Altitude then
            State.Altitude := Value.Altitude;
            State.Timestamp := Timestamp + 1;
         end if;
      end Fixed_Data;

      ------------------------
      -- Satellites_In_View --
      ------------------------

      procedure Satellites_In_View (Value : NMEA_0183.Satellites_In_View) is
         use all type NMEA_0183.Satellite_In_View;
      begin
         if Value.Message_Index = 1 then
            State.Next_Sat := 0;
         end if;

         for S of Value.List.List loop
            State.Next_Sat := State.Next_Sat + 1;

            if State.Satelites (State.Next_Sat) /= S then
               State.Satelites (State.Next_Sat) := S;
               State.Timestamp := Timestamp + 1;
            end if;
         end loop;

         if Value.Message_Index = Value.Total_Messages then
            State.Last_Sat := State.Next_Sat;
         end if;
      end Satellites_In_View;

   begin
      case Value.Kind is
         when GPS_Satellites_In_View =>
            Satellites_In_View (Value.Satellites_In_View);
         when GPS_Fixed_Data =>
            Fixed_Data (Value.Fixed_Data);
         when others =>
            null;
      end case;
   end Show;
end GUI;
