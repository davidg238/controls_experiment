// Copyright 2022 Ekorau LLC

import encoding.json
import gpio


import .ui_tftfactory show TFT_factory
import .ui_uimanager show UIManager
import .jog show Jog5WaySwitch
import .pubsub

import spi
import monitor show *

events := Channel 10

display := TFT_factory.adafruit_128x128
pubsub :=  PubsubServiceClient
uiManager := UIManager
                --display = display
                --events = events
                --pubsub = pubsub

main:
  task:: jog_task
  task:: display_task

jog_task:
  print "start task, scanning the 5 way jog switch"
  jog := Jog5WaySwitch
          --left   = 14 // Pin IO14
          --right  = 27
          --up     = 26
          --down   = 12
          --select = 33
  jog.eventTo events  // there is a loop here

display_task:
  //For reference, Nokia 2330 128x160
  print "start task, display"
  uiManager.run