--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Ada.Command_Line;

with Gdk.Event;

with Gtk.Box;         use Gtk.Box;
with Gtk.Widget;      use Gtk.Widget;
with Gtk.Main;
with Gtk.Window;      use Gtk.Window;

with Gtk.Drawing_Area;    use Gtk.Drawing_Area;
with Glib.Object; use Glib.Object;
with Cairo;         use Cairo;
with Glib; use Glib;
with Glib.Main;

with Cairo_Bitmaps;

with NMEA_0183;

with GUI;
with Serial_IO;

procedure Demo is
   Win   : Gtk_Window;
   Box   : Gtk_Vbox;
   Area  : Gtk_Drawing_Area;

   function Argument
     (Index   : Positive;
      Default : String) return String is
        (if Ada.Command_Line.Argument_Count < Index then Default
         else Ada.Command_Line.Argument (Index));

   function Delete_Event_Cb
     (Self  : access Gtk_Widget_Record'Class;
      Event : Gdk.Event.Gdk_Event)
      return Boolean;

   function On_Redraw
      (Demo : access GObject_Record'Class;
       Cr   : Cairo_Context) return Boolean;

   function On_Timeout return Boolean;

   procedure Parse_Message is new NMEA_0183.Generic_Parse_Message;

   ---------------
   -- On_Redraw --
   ---------------

   function On_Redraw
      (Demo : access GObject_Record'Class;
       Cr   : Cairo_Context) return Boolean
   is
      pragma Unreferenced (Demo);
      B : Cairo_Bitmaps.Cairo_Bitmap;
   begin
      B.Set_Context (Cr);

      Set_Source_Rgb (Cr, 0.0, 0.0, 0.0);
      Rectangle (Cr, 0.0, 0.0, 320.0, 240.0);
      Fill (Cr);
      GUI.Draw (B, True);

      return False;
   end On_Redraw;

   ---------------------
   -- Delete_Event_Cb --
   ---------------------

   function Delete_Event_Cb
     (Self  : access Gtk_Widget_Record'Class;
      Event : Gdk.Event.Gdk_Event)
      return Boolean
   is
      pragma Unreferenced (Self, Event);
   begin
      Gtk.Main.Main_Quit;
      return True;
   end Delete_Event_Cb;

   ----------------
   -- On_Timeout --
   ----------------

   function On_Timeout return Boolean is
      use all type NMEA_0183.Parse_Status;

      Text   : String (1 .. 80);
      Last   : Natural;
      Value  : NMEA_0183.NMEA_Message;
      Status : NMEA_0183.Parse_Status;
   begin
      Serial_IO.Read_Sentence (Text, Last);

      if Last > 0 then
         Parse_Message (Text (1 .. Last), Value, Status);

         if Status in No_Checksum | Success then
            GUI.Show (Value);
         end if;
      end if;

      Area.Queue_Draw;
      return True;
   end On_Timeout;

   Ignore : Glib.Main.G_Source_Id;
begin
   --  Initialize GtkAda.
   Gtk.Main.Init;
   --  Open COM port
   Serial_IO.Initialize
     (Port_Name => Argument (1, "/dev/ttyUSB0"),
      Speed     => Positive'Value (Argument (2, "115200")));

   --  Create a window with a size of 320x240
   Gtk_New (Win);
   Win.Set_Default_Size (320, 240);

   --  Create a box to organize vertically the contents of the window
   Gtk_New_Vbox (Box);
   Win.Add (Box);

   Gtk_New (Area);
   Box.Pack_Start (Area, Expand => True, Fill => True);
   Area.On_Draw (On_Redraw'Unrestricted_Access, Box);

   Ignore := Glib.Main.Timeout_Add (100, On_Timeout'Unrestricted_Access);

   --  Stop the Gtk process when closing the window
   Win.On_Delete_Event (Delete_Event_Cb'Unrestricted_Access);

   --  Show the window and present it
   Win.Show_All;
   Win.Present;

   --  Start the Gtk+ main loop
   Gtk.Main.Main;
end Demo;
