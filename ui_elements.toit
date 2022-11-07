import font show *
import font_x11_adobe.typewriter_08 as typ_08
import pixel_display show *
import pixel_display.texture show TEXT_TEXTURE_ALIGN_RIGHT TEXT_TEXTURE_ALIGN_CENTER
import pixel_display.true_color show WHITE BLACK get_rgb IndexedPixmapTexture


import .control_scheme show *
import .events show *

TYP_08 ::= Font [typ_08.ASCII]
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
GREEN ::= get_rgb 0x00 0xFF 0x00

class UI_Faceplate:
  // These are the variables the operator is to set.
  sp := 50      // Setpoint
  auto := true  // Auto/manual mode (in manual, the operator can set the output)

  // These are the textures to be displayed and updated.
  pv_d := null
  sp_d := null
  output_d := null

  pv_d_x := 40 
  pv_d_ymin := 110
  tlx := 5
  tly := 2
  brx := 55
  bry := 124

  fp_/Faceplate
  display_/TrueColorPixelDisplay
  txt_context_ := ?
  output_context_ := ?

  sp_d_transform := null
  new_transform := null

  constructor --display/TrueColorPixelDisplay --fp/Faceplate:
    display_ = display
    fp_ = fp
    txt_context_ = display_.context --landscape --color=WHITE --font=TYP_08 --alignment=TEXT_TEXTURE_ALIGN_RIGHT
    output_context_ = display_.context --landscape --color=GREEN
    fp_.addDependant this

  draw -> none:
    draw_outline
    draw_scale
    draw_ticks

    pv_d = display_.filled_rectangle (txt_context_.with --color=CYAN) pv_d_x pv_d_ymin 4 (-fp_.pv).round
    output_d = display_.line (txt_context_.with --color=GREEN) (tlx) (bry-8) (tlx+fp_.output/2) (bry-8)

    sp_d = IndexedPixmapTexture 46 101 8 8 txt_context_.transform IMAGE PALETTE
    sp_d_transform = sp_d.transform
    display_.add sp_d

    display_.draw

    while true:
      sleep --ms=1000

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


  update -> none:
    display_.remove pv_d
    pv_d = display_.filled_rectangle (txt_context_.with --color=CYAN) pv_d_x pv_d_ymin 4 (-fp_.pv).round

    new_transform = sp_d_transform.translate 0 -sp
    sp_d.set_transform new_transform

    display_.remove output_d
    output_d = display_.line (txt_context_.with --color=GREEN) (tlx) (bry-8) (tlx+fp_.output/2) (bry-8)

    display_.draw