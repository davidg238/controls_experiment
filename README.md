This is simple demonstration of Toit implementing a tank level simulation, level control and display.

The system is a 100 gal water tank, filled from a valve with a 0-20 gpm (gallons/minute) range, with a random outflow from the tank of 4-12gpm.  The tank level is to be controlled.

The control scheme to maintain the level is shown in the block diagram [Tank Level Simulation](https://github.com/davidg238/controls_experiment/blob/master/tank_level_controls.pdf).  Engineers typically design and program modern controllers using control blocks rather than code.  In main.toit you can see a textual representation of this, as below:
```
run_control -> none:

  scheme = Scheme --dT=250

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
```
The scheme elements are declared (input, PID controller and output) and then connected.  In older control systems interconnections were declared with block numbers and input/output numbers, both tedious and error prone.  Textual references are used above for clarity.  The scheme is an object model which is executed, rather than a compiled artifact. To eliminate runtime overhead in looking up block input/output references, a technique from HotDraw is used.  When a connection is made from **tank_lvl/out** to **pid01/pv**, a connection object (of type Wire) is put in the **pid01** input list.  Then a method is declared in the PID class
```
  pv -> float:
    return inputs[0].value
```
the Wire class is defined as
```
class Wire:
  module/Module?
  out/int?
...
  value -> any:
    return module.outputs[out]
```
so the pv value for pid01 is resolved at runtime via a series of message sends, rather than any lookup via Maps.
The process scheme just iterates over the modules, sending `tick` to each, where they update their outputs based on their inputs.

A very crude user interface comprising a single Faceplate, is defined for the 128x128 TFT display.  To communicate with the user interface, a Faceplate (an engineering term) module is defined in the control scheme, to allow variables to be displayed and user input gathered.  <s>An observer pattern is used, between the Faceplate and UI_Faceplate.</s><small>(0.6.0)</small>  In [ui_elements.toit](https://github.com/davidg238/controls_experiment/blob/master/ui_elements.toit) the class UI_Faceplate is responsible for drawing the Faceplate on the display and responding to update messages.  The display and jog shuttle events are handled in [ui_manager.toit](https://github.com/davidg238/controls_experiment/blob/master/ui_uimanager.toit).

The PID algorithm used to control the tank level is shown schematically in [pid_block.pdf](https://github.com/davidg238/controls_experiment/blob/master/pid_block.pdf), implemented in the PID class in [control_scheme.toit](https://github.com/davidg238/controls_experiment/blob/master/control_scheme.toit).  It provides for auto/manual control transitions, options on SP tracking and does not suffer from "integral windup".

In v0.6.0, the application was refactored to use containers.  The containers comprise:  
  - pubsub broker, for message pub/sub between containers
  - controls, where the the I/O and controls execute
  - UI, shown as a small TFT PID faceplate

This necessitated changing the observer pattern previously used between the UI `UI_Faceplate` to control scheme `Faceplate`, to communications via pubsub.  
The control scheme executes in the controls containers, subscribing to commands from and publishing value changes to, the UI container.  
Looking at the code, it would be straightforward to introduce an alternate (and/or concurrent) UI, via say a webpage or CLI, with no change to the controls container.

For ease of use, on Linux you can run the dev_install.sh script to install and run the application.  
Uninstall the monitor container, `jag container uninstall monitor`, if you do not want the prints on the console.