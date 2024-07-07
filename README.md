# NMEA-0183

[![Build binaries](https://github.com/reznikmm/nmea-0183/actions/workflows/main.yml/badge.svg)](https://github.com/reznikmm/nmea-0183/actions/workflows/main.yml)
[![Alire](https://img.shields.io/endpoint?url=https://alire.ada.dev/badges/nmea_0183.json)](https://alire.ada.dev/crates/nmea_0183.html)
[![REUSE status](https://api.reuse.software/badge/github.com/reznikmm/nmea-0183)](https://api.reuse.software/info/github.com/reznikmm/nmea-0183)

> NMEA 0183 GNSS message decoder


This library provides functionality to decode GPS NMEA sentences in Ada.
It supports various message types and includes features for checksum
validation and optional decoding of unused messages to optimize program
size. The library operates without raising exceptions.

## Features

- **Decoding GPS NMEA Sentences:**
  - GPS Fixed Data
  - Geographic Position
  - Active Satellites
  - Satellites In View
  - GPS Data (Variant C)
  - Ground Speed
- **Checksum Validation**
- **Optional Decoding:**
  - Ability to disable decoding of unnecessary messages to reduce program
    size.
- **Exception-Free Operation:**
  - Designed to work without raising exceptions.

## Installation

To install the library using the Alire package manager, run the following
command:

```sh
alr with nmea_0183 --use=https://github.com/reznikmm/nmea-0183.git
```

## Usage

Here is an example of how to use the library:

```ada
declare
   Text : constant String :=
     "$GNGLL,4404.14012,N,12118.85993,W,001037.00,A,A*67";

   Result : NMEA_0183.NMEA_Message;
   Status : NMEA_0183.Parse_Status;
begin
   NMEA_0183.Parse_Message (Text, Result, Status);
   Ada.Text_IO.Put_Line ("Latitude:" & Result.Latitude.Degree'Image);
end;
```

In this example, the library parses a NMEA sentence and outputs the latitude.

## Maintainer

[@Max Reznik](https://github.com/reznikmm).

## Contribute

Feel free to [open an issue](https://github.com/reznikmm/nmea-0183/issues/new) or submit PRs.

## License

[Apache 2](LICENSES/Apache-2.0.txt) with [LLVM exception](LICENSES/LLVM-exception.txt) © Max Reznik
