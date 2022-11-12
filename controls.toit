// Copyright 2022 Ekorau LLC

import .pubsub show *
import encoding.json


interface Module:
  id -> string
  init client/PubsubServiceClient -> none
  inputs -> List
  input_names -> List
  outputs -> List
  output_names -> List
  tick -> none

class Scheme:
  pubsub /PubsubServiceClient
  modules /List := []
  dT /int := 200

  constructor --.pubsub --.dT:

  add module/Module -> none:
    modules.add module
    module.init pubsub

  connect --from/string --out/string --to/string --in/string -> none:
    modf := module_for --id=from
    out_idx := modf.output_names.index_of out
    modt := module_for --id=to
    in_idx := modt.input_names.index_of in
    modt.inputs[in_idx] = Wire modf out_idx

  module_for --id/string -> Module?:
    modules.do:
      if it.id == id:
        return it
    return null

  run -> none:
    while true:
      modules.do: it.tick
      sleep --ms=dT

class Wire:
  module/Module?
  out/int?

  constructor .module .out:

  value -> any:
    return module.outputs[out]

  stringify -> string:
    return "Wire from $(module)/$(out)"

class SimInput implements Module:
  id /string
  inputs := List 1
  input_names := ["sim_in"]
  outputs := List 1
  output_names := ["out"]
  sim /Lambda?
  input_1 := 50
  
  constructor --.id --.sim:

  init client/PubsubServiceClient -> none:

  stringify -> string:
    return "SimInput $(id) $(inputs[0])"

  input -> float:
    return inputs[0].value

  tick -> none:
    outputs[0] = sim.call input_1 input
    input_1 = outputs[0]

class SimOutput implements Module:
  id /string
  inputs := List 1
  input_names := ["co"]
  outputs := List 1
  output_names := ["sim_out"]
  
  constructor --.id:

  init client/PubsubServiceClient -> none:
  // The output[] must be initialized, as SimInput as first block to execute in the scheme references it.
  // TODO - do we want this in every case? How do we cleanly declare in ioctl.toit?
    outputs[0] = 50.0

  stringify -> string:
    return "SimOutput $(id)"

  input -> float:
    return inputs[0].value

  tick -> none:
    outputs[0] = input

class PID implements Module:
  id /string
  inputs := List 4
  input_names := ["pv", "sp", "auto", "op_co"]
  outputs := List 1
  output_names := ["out"]

  ks /int := -1 // direct acting 1, reverse acting -1
  kp /float := 1.0
  kp2 /float := 0.0
  spio /bool := true // integral only on setpoint change
  ti_ /float := 1.0
  dT /int := 250

  out_min := 0.0
  out_max := 100.0

  pv_last /float := 0.0
  dev_last /float := 0.0
  out_last /float := 0.0
  pubsub_client /PubsubServiceClient? := null
  subscription /Subscription? := null
  n := 0

  constructor --.id --.ks=-1 --.dT/int:

  init client/PubsubServiceClient -> none:

// ----------------------------------------------------------------------------
// Inputs
  pv -> float:
    return inputs[0].value

  sp -> float:
    return auto? inputs[1].value: pv
  
  auto -> bool:
    return inputs[2].value

  op_co -> float:
    return inputs[3].value

// Module interface ----------------------------------------------------------
  tick -> none:
    dev := pv-sp
    p1 := dev - dev_last
    dev_last = dev
    p2 := pv - pv_last
    p3 := spio? p2: p1
    proportional := p3*ks*kp
    integral := dev*ks*kp2*(dT/1000.0)/ti_ //since dT is in milli-sec
    a_o := proportional + integral + out_last
    temp := setco_ (auto? a_o: op_co)
    // report p1 p2 p3 proportional integral a_o  // must be called in the tick method, 'cause it ticks
    out_last = temp // because of the report call
// ----------------------------------------------------------------------------
  setco_ val/float -> float:
    return outputs[0] = min (max out_min val) out_max

  tune --.kp=1.0 --ti/int --.ks/int --.spio=true -> none:
    kp2 = kp==0.0? 1.0: kp
    ti_ = ti * 1.0

  stringify -> string:
    return "PID $(id)"

  report p1 p2 p3 proportional integral a_o-> none:
    n += 1
    if n % 10 == 0:
      print "pv $(%.1f pv) sp $(%.1f sp) p1 $(%.3f p1) p2 $(%.1f p2) p3 $(%.1f p3) P $(%.1f proportional) I $(%.3f integral) o $(%.1f a_o) o-1 $(%.1f out_last)" //  a/m $(auto) op_co $(op_co)

class Barchart implements Module:
  id /string
  dependants /List := []
  inputs := List 2
  input_names := ["in0", "in1"]
  outputs := List
  output_names := []
  every_ticks /int := 4
  n := 0

  constructor --.id --dT/int:
    every_ticks = 1000/dT

  stringify -> string:  
    return "Barchart $(id)"

  in0 -> float:
    return inputs[0].value

  in1 -> float:
    return inputs[1].value

  init client/PubsubServiceClient -> none:

  // Only update the display a fraction of the loop cycle time.
  tick -> none:
    n += 1
    if n == every_ticks:
      n = 0
      changed

  changed -> none:
  // ---------------------------------------------------------------------------
/*
A Faceplate has two sets of inputs and outputs.
Those with the other modules of the control scheme and those via pubsub.
No assumptions should be made about the number or type of pubsub clients.
*/
class Faceplate implements Module:
  id /string
  dependants /List := []
  inputs := List 2  // from the control scheme to the operator
  input_names := ["pv", "a_out"]
  outputs := [50.0, true, 50.0] // from the operator to the control scheme
  output_names := ["sp", "auto", "op_co"]
  every_ticks /int := 4
  n := 0
  pubsub_client /PubsubServiceClient? := null
  subscription /Subscription? := null
  listener/Task? := null

  constructor --.id --dT/int:
    every_ticks = max 1000/dT 5

  init client/PubsubServiceClient -> none:
    pubsub_client = client
    subscription = client.subscribe "$(id)/cmds"
    listener = task::
      subscription.listen:
        execute_commands it

  stringify -> string:
    return "$(id)"

  pv -> float:
    return inputs[0].value

  a_out -> float:
    return inputs[1].value

  sp -> float:
    return outputs[0]

  auto -> bool:
    return outputs[1]

  op_co -> float:
    return outputs[2]

  execute_commands cmd/string -> none:
      if      cmd == "spi":
        inc_sp 
        return
      else if cmd == "spd":
        dec_sp
        return
      else if cmd == "coi":
        inc_op_co
        return
      else if cmd == "cod":
        dec_op_co
        return
      else if cmd == "!a":
        toggle_auto
        return
      else:
        // TODO
        print "Unknown command $(cmd)"

  inc_sp -> none:
    outputs[0] = min (max 0.0 (outputs[0] + 5)) 100.0
    changed

  dec_sp -> none:
    outputs[0] = min (max 0.0 (outputs[0] - 5)) 100.0
    changed


  toggle_auto -> none:
    outputs[1] = not outputs[1]
    changed

  inc_op_co -> none:
    outputs[2] = min (max 0.0 (outputs[2] + 5.0)) 100.0
    changed

  dec_op_co -> none:
    outputs[2] = min (max 0.0 (outputs[2] - 5.0)) 100.0
    changed

  // Only update the display a fraction of the loop cycle time.
  tick -> none:
    if auto:
      outputs[2] = a_out
    n += 1
    if n > every_ticks:
      n = 0
      changed

  changed -> none:
    vals := [pv, sp, a_out, auto]
    pubsub_client.publish "$(id)/vals" (json.stringify vals)

    

