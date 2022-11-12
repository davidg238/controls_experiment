// Copyright 2022 Ekorau LLC

import font show *
import pixel_display show *
import pixel_display.true_color show WHITE BLACK

import monitor show Channel
import encoding.json
import .events show *
import .control_scheme show *
import .ui_elements show *
import .jog show *
import .pubsub show *



class UIManager:

  display_/TrueColorPixelDisplay
  events/Channel
  event := null
  cmd := ""
  pubsub_/PubsubServiceClient
  faceplate /UI_Faceplate? := null

  constructor --display/TrueColorPixelDisplay --.events/Channel --pubsub/PubsubServiceClient:
    display_ = display
    pubsub_ = pubsub

  run -> none:
    display_.background = BLACK
    display_.remove_all
    display_.draw

    faceplate = UI_Faceplate --display=display_ --pubsub=pubsub_
    faceplate.draw

    while true:
      dispatchEvents

  dispatchEvents -> none:
    event = events.receive
    if event is JogEvent:
      if event.u:
        cmd = "spi"
      else if event.d:
        cmd = "spd"
      else if event.l and not faceplate.auto:
        cmd = "cod"
      else if event.r and not faceplate.auto:
        cmd = "coi"
      else if event.s:
        cmd = "!a"
      else:
        cmd = "."
      //print "fp01/cmd $cmd"
      pubsub_.publish "fp01/cmds" cmd

  
