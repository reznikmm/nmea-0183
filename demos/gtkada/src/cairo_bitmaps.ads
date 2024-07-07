--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with HAL.Bitmap;
with Cairo;
with Soft_Drawing_Bitmap;

private with System;

package Cairo_Bitmaps is

   type Cairo_Bitmap is new HAL.Bitmap.Bitmap_Buffer with private;

   procedure Set_Context
     (Self    : in out Cairo_Bitmap'Class;
      Context : Cairo.Cairo_Context);

private
   type Cairo_Bitmap is
     new Soft_Drawing_Bitmap.Soft_Drawing_Bitmap_Buffer with record
      Context : Cairo.Cairo_Context;
      Source : HAL.UInt32;
   end record;

   overriding function Width (Self : Cairo_Bitmap) return Natural is (320);

   overriding function Height (Self : Cairo_Bitmap) return Natural is (240);
   overriding function Swapped (Self : Cairo_Bitmap) return Boolean is (False);
   overriding function Color_Mode
     (Self : Cairo_Bitmap) return HAL.Bitmap.Bitmap_Color_Mode
      is (HAL.Bitmap.RGB_888);

   overriding function Mapped_In_RAM (Self : Cairo_Bitmap) return Boolean is
     (False);

   overriding function Memory_Address
     (Self : Cairo_Bitmap) return System.Address is (System.Null_Address);

   overriding procedure Set_Source
     (Self : in out Cairo_Bitmap;
      Native : HAL.UInt32);

   overriding function Source (Self : Cairo_Bitmap) return HAL.UInt32 is
     (Self.Source);

   overriding procedure Set_Pixel
     (Self : in out Cairo_Bitmap;
      Pt   : HAL.Bitmap.Point);

   overriding procedure Set_Pixel_Blend
     (Self : in out Cairo_Bitmap;
      Pt   : HAL.Bitmap.Point) renames Set_Pixel;

   overriding function Pixel
     (Self : Cairo_Bitmap;
      Pt   : HAL.Bitmap.Point)
      return HAL.UInt32;

   overriding function Buffer_Size (Self : Cairo_Bitmap) return Natural is
     (320 * 240 * 24);

end Cairo_Bitmaps;
