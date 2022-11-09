import font show *
import pixel_display show *
import pixel_display.true_color show WHITE BLACK

import monitor show Channel
import encoding.json
import .events show *
import .control_scheme show *
import .ui_elements show *
import .jog show *



class UIManager:

  display_/TrueColorPixelDisplay
  events/Channel
  // The elements in the control scheme to be displayed
  fp/Faceplate  
  bar/Barchart
  je := null
  event := null

  constructor --display/TrueColorPixelDisplay --.events/Channel --.fp/Faceplate --.bar/Barchart:
    display_ = display

  run -> none:
    display_.background = BLACK
    display_.remove_all
    display_.draw

    faceplate := UI_Faceplate --display=display_ --fp=fp
    faceplate.draw

    while true:
      dispatchEvents

  dispatchEvents -> none:
    event = events.receive
    if event is JogEvent:
      if event.u:
        fp.inc_sp
      else if event.d:
        fp.dec_sp
      else if event.l and not fp.auto:
        fp.dec_op_co
      else if event.r and not fp.auto:
        fp.inc_op_co
      else if event.s:
        fp.toggle_auto


  
