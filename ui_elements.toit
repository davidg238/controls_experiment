// Copyright 2022 Ekorau LLC

import font show *
import font_x11_adobe.typewriter_08 as typ_08
import font_x11_adobe.typewriter_10 as typ_10
import pixel_display show *
import pixel_display.texture show TEXT_TEXTURE_ALIGN_RIGHT TEXT_TEXTURE_ALIGN_CENTER TEXT_TEXTURE_ALIGN_LEFT
import pixel_display.true_color show WHITE BLACK get_rgb IndexedPixmapTexture

import .pubsub show *
import encoding.json

import .events show *

TYP_08 ::= Font [typ_08.ASCII]
TYP_10 ::= Font [typ_10.ASCII]
IMAGE ::= #[
    0, 0, 0, 2, 2, 2, 2, 2,
    0, 0, 2, 2, 2, 2, 2, 2,
    0, 2, 2, 2, 2, 2, 2, 2,
    2, 2, 2, 2, 2, 2, 2, 2,
    2, 2, 2, 2, 2, 2, 2, 2,
    0, 2, 2, 2, 2, 2, 2, 2,
    0, 0, 2, 2, 2, 2, 2, 2,
    0, 0, 0, 2, 2, 2, 2, 2]

PALETTE ::= #[
    0, 0, 0,
    255, 0, 0,
    230, 30, 50,
    0, 0, 255]


CYAN ::= get_rgb 0x00 0xFF 0xFF
RED ::= get_rgb 0xFF 0x00 0x00
GREEN ::= get_rgb 0x00 0xFF 0x00

class UI_Barchart:

class UI_Faceplate:
  /*
  These are the values to be displayed and updated over pubsub.
  They must be initialized.
  */
  pv_ := 50.0
  sp_ := 50.0
  a_out_ := 50.0
  auto_ := true
  // These are the textures to be displayed and updated.
  pv_d := null
  sp_d := null
  output_d := null
  auto_d := null
  // Key coordinates for the display.
  pv_d_x := 40 
  pv_d_ymin := 110
  tlx := 5
  tly := 2
  brx := 55
  bry := 124

  pubsub_/PubsubServiceClient
  subscription/Subscription? := null
  listener/Task? := null

  display_/TrueColorPixelDisplay
  io := []
  txt_context_ := ?
  output_context_ := ?

  constructor --display/TrueColorPixelDisplay --pubsub/PubsubServiceClient:
    display_ = display
    pubsub_ = pubsub

    txt_context_ = display_.context --landscape --color=WHITE --font=TYP_08 --alignment=TEXT_TEXTURE_ALIGN_RIGHT
    output_context_ = display_.context --landscape --color=GREEN

  pv -> int:
  //  print pv_.round
    return pv_.round

  sp -> int:
    return sp_.round

  a_out -> int:
    return a_out_.round

  auto -> bool:
    return auto_

  draw -> none:
    init
    draw_outline
    draw_scale
    draw_ticks
    draw_auto_manual
    draw_pv
    draw_sp
    draw_a_out

    display_.draw

  init -> none:
    subscription = pubsub_.subscribe "fp01/vals"
    listener = task::
      subscription.listen:
        update_vals it
        update

  draw_pv -> none:
    pv_d = display_.filled_rectangle (txt_context_.with --color=CYAN) pv_d_x pv_d_ymin 4 -pv

  draw_sp -> none:
    create_sp
    move_sp

  move_sp -> none:
    sp_d.move_to (pv_d_x + 5) (pv_d_ymin - (sp+5))

  create_sp -> none:
    sp_d = IndexedPixmapTexture 46 101 8 8 txt_context_.transform IMAGE PALETTE
    display_.add sp_d

  draw_a_out -> none:
    output_d = display_.line (txt_context_.with --color=GREEN) (tlx) (bry-8) (tlx+(a_out/2.0).round) (bry-8)

  draw_auto_manual -> none:
    auto_d = auto?
      display_.text (txt_context_.with --font=TYP_10 --color=GREEN --alignment=TEXT_TEXTURE_ALIGN_LEFT) tlx+5 pv_d_ymin "A":
      display_.text (txt_context_.with --font=TYP_10 --color=RED   --alignment=TEXT_TEXTURE_ALIGN_LEFT) tlx+5 pv_d_ymin "M"

  draw_outline -> none:
    display_.line txt_context_ tlx tly brx tly 
    display_.line txt_context_ tlx tly tlx 124 
    display_.line txt_context_ brx tly brx 124 
    display_.line txt_context_ 5 124 55 124 

  draw_scale -> none:
    display_.text txt_context_ (pv_d_x-10) (pv_d_ymin-95) "100"
    display_.text txt_context_ (pv_d_x-15) (pv_d_ymin-45) "50"
    display_.text txt_context_ (pv_d_x-10) pv_d_ymin "0"

  draw_ticks -> none:
    display_.line txt_context_ (pv_d_x-7) pv_d_ymin (pv_d_x-2) pv_d_ymin 
    display_.line txt_context_ (pv_d_x-7) (pv_d_ymin-25) (pv_d_x-2) (pv_d_ymin-25) 
    display_.line txt_context_ (pv_d_x-12) (pv_d_ymin-50) (pv_d_x-2) (pv_d_ymin-50) 
    display_.line txt_context_ (pv_d_x-7) (pv_d_ymin-75) (pv_d_x-2) (pv_d_ymin-75) 
    display_.line txt_context_ (pv_d_x-7) (pv_d_ymin-100) (pv_d_x-2) (pv_d_ymin-100) 

    display_.line txt_context_ (tlx+12) (bry) (tlx+12) (bry-4) 
    display_.line txt_context_ (tlx+25) (bry) (tlx+25) (bry-6) 
    display_.line txt_context_ (tlx+37) (bry) (tlx+37) (bry-4) 

  update_vals vals/string -> none:
    list := json.parse vals
    pv_ = list[0]
    sp_ = list[1]
    a_out_ = list[2]
    auto_ = list[3]

  update -> none:
    display_.remove pv_d
    draw_pv

    move_sp

    display_.remove output_d
    draw_a_out

    display_.remove auto_d
    draw_auto_manual
     
    display_.draw