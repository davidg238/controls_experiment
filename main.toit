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

scheme := null
a_sim := null

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

  scheme = Scheme --dT=250

  /* 
  simulated tank level (out), 0-100 gallons
  loss is in gpm
  fill valve (in)(0-100%) results in 0-20gpm inflow
  */  
  a_sim = :: | last in|
    loss := random 4 12  
    out := last + (in/5 - loss)*(scheme.dT/60_000.0)
    min (max 0.0 out) 100.0  // clamp to 0-100

  scheme.add (SimInput --id="tank_lvl" --sim=a_sim)      //0
  scheme.add (PID --id="pid01" --dT=scheme.dT)          //1
  scheme.add (SimOutput --id="fill_vlv")                //2
  fp = (Faceplate --id="fp01" --dT=scheme.dT)
  scheme.add fp //3 
  bar = (Barchart --id="bc01" --dT=scheme.dT)
  scheme.add bar  //4
  
  scheme.connect --from="tank_lvl" --out="out" --to="pid01" --in="pv"
  scheme.connect --from="pid01" --out="out" --to="fill_vlv" --in="co"
  scheme.connect --from="fill_vlv" --out="sim_out" --to="tank_lvl" --in="sim_in"
  scheme.connect --from="fp01" --out="sp" --to="pid01" --in="sp"
  scheme.connect --from="fp01" --out="auto" --to="pid01" --in="auto"
  scheme.connect --from="fp01" --out="op_co" --to="pid01" --in="op_co"
  scheme.connect --from="tank_lvl" --out="out" --to="fp01" --in="pv"  
  scheme.connect --from="pid01" --out="out" --to="fp01" --in="a_out"  
  scheme.connect --from="tank_lvl" --out="out" --to="bc01" --in="in0"
  ((scheme.module_for --id="pid01") as PID).tune --ks=-1 --kp=1.0 --ki=0.0
  
  scheme.run