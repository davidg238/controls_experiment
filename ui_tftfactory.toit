// Copyright 2021, 2022 Ekorau LLC

import spi
import gpio
import color_tft show *
import pixel_display show *

class TFT_factory:

    static m5_stack_16bit_landscape -> TrueColorPixelDisplay:
        return define_ --hz= 40 --x=320 --y=240 --xoff=0 --yoff=0 --sda=23 --clock=18 --cs=14 --dc=27 --reset=33 --backlight=32 --invert=false --flags=COLOR_TFT_16_BIT_MODE

    static wrover_16bit_landscape -> TrueColorPixelDisplay:
        return define_ --hz= 40 --x=320 --y=240 --xoff=0 --yoff=0 --sda=23 --clock=19 --cs=22 --dc=21 --reset=18 --backlight=-5 --invert=false --flags=COLOR_TFT_16_BIT_MODE | COLOR_TFT_FLIP_XY

    static lilygo_16bit_landscape -> TrueColorPixelDisplay:
        return define_ --hz= 20 --x=80 --y=160 --xoff=26 --yoff=1 --sda=19 --clock=18 --cs=5 --dc=23 --reset=26 --backlight=27 --invert=true --flags=COLOR_TFT_16_BIT_MODE

    static adafruit_128x128 -> TrueColorPixelDisplay:
        return define_ --hz= 20 --x=128 --y=128 --xoff=2 --yoff=1 --sda=25 --clock=19 --cs=22 --dc=21 --reset=18 --backlight=5 --invert=false --flags=COLOR_TFT_16_BIT_MODE

    static define_ --hz --x --y --xoff --yoff --sda --clock --cs --dc --reset --backlight --invert --flags -> TrueColorPixelDisplay:
        bus := spi.Bus
            --mosi= gpio.Pin sda
            --clock= gpio.Pin clock

        device := bus.device
            --cs= gpio.Pin cs
            --dc= gpio.Pin dc
            --frequency= 1_000_000 * hz

        driver := ColorTft device x y
            --reset= gpio.Pin reset
            --backlight= backlight>=0 ? gpio.Pin backlight : null
            --x_offset= xoff
            --y_offset= yoff
            --flags= flags
            --invert_colors= invert

        tft := TrueColorPixelDisplay driver
        return tft

/*
// Original code https://github.com/toitware/toit-color-tft/blob/main/examples/tft_demo.toit

// Copyright (C) 2020 Toitware ApS. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

get_display -> TrueColorPixelDisplay:
                                         // MHz x    y    xoff yoff sda clock cs  dc  reset backlight invert
  M5_STACK_16_BIT_LANDSCAPE_SETTINGS ::= [  40, 320, 240, 0,   0,   23, 18,   14, 27, 33,   32,       false, COLOR_TFT_16_BIT_MODE ]
  WROVER_16_BIT_LANDSCAPE_SETTINGS   ::= [  40, 320, 240, 0,   0,   23, 19,   22, 21, 18,   -5,       false, COLOR_TFT_16_BIT_MODE | COLOR_TFT_FLIP_XY ]
  LILYGO_16_BIT_LANDSCAPE_SETTINGS   ::= [  20, 80,  160, 26,  1,   19, 18,   5 , 23, 26,   27,       true,  COLOR_TFT_16_BIT_MODE ]

  // Pick one of the above.
  s := WROVER_16_BIT_LANDSCAPE_SETTINGS

  hz            := 1_000_000 * s[0]
  width         := s[1]
  height        := s[2]
  x_offset      := s[3]
  y_offset      := s[4]
  mosi          := gpio.Pin s[5]
  clock         := gpio.Pin s[6]
  cs            := gpio.Pin s[7]
  dc            := gpio.Pin s[8]
  reset         := gpio.Pin s[9]
  backlight     := s[10] >= 0 ? gpio.Pin s[10] : null
  invert_colors := s[11]
  flags         := s[12]

  bus := spi.Bus
    --mosi=mosi
    --clock=clock

  device := bus.device
    --cs=cs
    --dc=dc
    --frequency=hz

  driver := ColorTft device width height
    --reset=reset
    --backlight=backlight
    --x_offset=x_offset
    --y_offset=y_offset
    --flags=flags
    --invert_colors=invert_colors

  tft := TrueColorPixelDisplay driver

  return tft
*/