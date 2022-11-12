// Copyright 2022 Ekorau LLC

import encoding.json
import gpio
import .pubsub
import .controls show *

import spi
import monitor show *


scheme := null
a_sim := null
client_ ::= PubsubServiceClient

main:

  scheme = Scheme --pubsub=client_ --dT=250
  /* 
  simulated tank level (out), 0-100 gallons
  loss is in gpm
  fill valve (in)(0-100%) results in 0-20gpm inflow
  */  
  a_sim = :: | last in|
    loss := random 4 12  
    out := last + (in/5 - loss)*(scheme.dT/60_000.0)
    min (max 0.0 out) 100.0  // clamp to 0-100

  scheme.add (SimInput --id="tank_lvl" --sim=a_sim)     
  scheme.add (PID --id="pid01" --dT=scheme.dT)          
  scheme.add (SimOutput --id="fill_vlv")                
  scheme.add (Faceplate --id="fp01" --dT=scheme.dT)
  scheme.add (Barchart --id="bc01" --dT=scheme.dT)
  
  scheme.connect --from="tank_lvl" --out="out" --to="pid01" --in="pv"
  scheme.connect --from="pid01" --out="out" --to="fill_vlv" --in="co"
  scheme.connect --from="fill_vlv" --out="sim_out" --to="tank_lvl" --in="sim_in"
  scheme.connect --from="fp01" --out="sp" --to="pid01" --in="sp"
  scheme.connect --from="fp01" --out="auto" --to="pid01" --in="auto"
  scheme.connect --from="fp01" --out="op_co" --to="pid01" --in="op_co"
  scheme.connect --from="tank_lvl" --out="out" --to="fp01" --in="pv"  
  scheme.connect --from="pid01" --out="out" --to="fp01" --in="a_out"  
  scheme.connect --from="tank_lvl" --out="out" --to="bc01" --in="in0"
  ((scheme.module_for --id="pid01") as PID).tune --kp=10.0 --ti=100 --ks=-1 --spio=false
  
  scheme.run