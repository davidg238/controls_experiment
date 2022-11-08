import font show *
import pixel_display show *
import pixel_display.true_color show WHITE BLACK

import monitor show Channel
import encoding.json
import .events show *
import .control_scheme show *
import .ui_elements show *



class UIManager:

  display_/TrueColorPixelDisplay
  events/Channel
  // The elements in the control scheme to be displayed
  fp/Faceplate  
  bar/Barchart

  event := null

  constructor --display/TrueColorPixelDisplay --.events/Channel --.fp/Faceplate --.bar/Barchart:
    display_ = display

  run -> none:
    display_.background = BLACK
    display_.remove_all
    display_.draw

    faceplate := UI_Faceplate --display=display_ --fp=fp
    faceplate.draw

  dispatchEvents -> none:
    event = events.receive
    if event is WeatherEvent:
  //      showWeather event.map
        return
    if event is JogEvent:
  //      showTxt event.stringify
        return
    if event is RangeEvent:
  //      showRange event.map
        return
    if event is MotionEvent:
  //      showTxt "m"
        return



  
