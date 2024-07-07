--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Glib;
with Bitmap_Color_Conversion;

package body Cairo_Bitmaps is

   -----------
   -- Pixel --
   -----------

   overriding function Pixel
     (Self : Cairo_Bitmap; Pt : HAL.Bitmap.Point) return HAL.UInt32
   is
   begin
      return 0;
   end Pixel;

   -----------------
   -- Set_Context --
   -----------------

   procedure Set_Context
     (Self    : in out Cairo_Bitmap'Class;
      Context : Cairo.Cairo_Context) is
   begin
      Self.Context := Context;
   end Set_Context;

   ---------------
   -- Set_Pixel --
   ---------------

   overriding procedure Set_Pixel
     (Self : in out Cairo_Bitmap;
      Pt   : HAL.Bitmap.Point) is
   begin
      Cairo.Rectangle
        (Self.Context,
         X      => Glib.Gdouble (Pt.X),
         Y      => Glib.Gdouble (Pt.Y),
         Width  => 1.0,
         Height => 1.0);
      Cairo.Fill (Self.Context);
   end Set_Pixel;

   ----------------
   -- Set_Source --
   ----------------

   overriding procedure Set_Source
     (Self   : in out Cairo_Bitmap;
      Native : HAL.UInt32)
   is
      use type Glib.Gdouble;

      Color : constant HAL.Bitmap.Bitmap_Color :=
        Bitmap_Color_Conversion.Word_To_Bitmap_Color
          (HAL.Bitmap.RGB_888, Native);
   begin
      Self.Source := Native;

      Cairo.Set_Source_Rgb
        (Self.Context,
         Red    => Glib.Gdouble (Color.Red) / 256.0,
         Green  => Glib.Gdouble (Color.Green) / 256.0,
         Blue   => Glib.Gdouble (Color.Blue) / 256.0);
   end Set_Source;

end Cairo_Bitmaps;
