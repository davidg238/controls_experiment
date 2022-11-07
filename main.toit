// Copyright 2021 Ekorau LLC

import encoding.json
import gpio


import .ui_tftfactory show TFT_factory
import .ui_uimanager show UIManager
import .jog show Jog5WaySwitch
import .events show WeatherEvent RangeEvent MotionEvent

import .control_scheme show *

import spi
import monitor show *

events := Channel 10

display := TFT_factory.adafruit_128x128

fp/Faceplate? := null
bar/Barchart? := null

uiManager := UIManager
                --display = display
                --events = events
                --fp = fp   // hack, since UI drawings not implemented yet
                --bar = bar // hack, ditto

motion := gpio.Pin 32 --input
led := gpio.Pin 15 --output

main:

  task:: jog_task
  // task:: motion_task
  // task:: bump_sp
  task:: run_control
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

motion_task:
  led.set 0
  while true:
    motion.wait_for 1
    led.set 1
    sleep --ms=2000
    // eventscheme.send MotionEvent
    led.set 0


display_task:
  //For reference, Nokia 2330 128x160
  print "start task, display"
  uiManager.run


  /* Assume have 100gal irrigation buffer tank, filled via a valve that can deliver 0-20gpm.
    Outlet varies randomly between 5-15gpm.
    Run loop every 6 sec.
  */
/*  
bump_sp -> none:
  while true:
    sp = random 15 85
    sleep --ms=180000
*/
run_control -> none:

  scheme := Scheme --dT=200
  a_sim := :: | in out|
    /* 
    simulated tank level (out), 0-100 gallons
    loss is in gpm
    fill valve (in)(0-100%) results in 0-20gpm inflow
     */
    loss := random 4 22  
    out = out + (in/5 - loss)*(scheme.dT/60_000)
    min (max 0.0 out) 100.0  // clamp to 0-100

  scheme.add (SimInput --sim=a_sim)     //0
  scheme.add (PID --dT=scheme.dT)       //1
  scheme.add SimOutput                  //2
  fp = (Faceplate --dT=scheme.dT)       
  scheme.add fp                         //3 
  bar = (Barchart --dT=scheme.dT)
  scheme.add bar                        //4
  
  scheme.connect --from=0 --out=0 --to=1 --in=0
  scheme.connect --from=1 --out=0 --to=2 --in=0
  scheme.connect --from=2 --out=0 --to=0 --in=0
  scheme.connect --from=3 --out=0 --to=1 --in=1
  scheme.connect --from=3 --out=1 --to=1 --in=2
  scheme.connect --from=0 --out=0 --to=4 --in=0

  (scheme.modules[1] as PID).tune --ks=1 --kp=10.0 --ki=0.0
  
  scheme.run