interface Module:
  id -> string
  inputs -> List
  input_names -> List
  outputs -> List
  output_names -> List
  tick -> none

interface Model:
  addDependant dep/any -> none
  changed -> none

class Scheme:
  modules /List := []
  dT /int := 200

  constructor --.dT:

  add module/Module -> none:
    modules.add module

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
      modules.do:
        it.tick
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
  last := 50
  
  constructor --.id --.sim:

  stringify -> string:
    return "SimInput $(id) $(inputs[0])"

  input -> float:
    val := inputs[0].value
    return val==null ? 50.0 : val

  tick -> none:
    outputs[0] = sim.call last input
    last = outputs[0]

class SimOutput implements Module:
  id /string
  inputs := List 1
  input_names := ["co"]
  outputs := [50.0]
  output_names := ["out"]
  
  constructor --.id:

  stringify -> string:
    return "SimOutput $(id)"

  input -> float:
    return inputs[0].value

  tick -> none:
    outputs[0] = input

class PID implements Module:
  id /string
  inputs := List 4
  input_names := ["pv", "sp", "auto", "op_out"]
  outputs := List 1
  output_names := ["out"]

  ks /int := 1
  kp /float := 0.0
  kp2 /float := 1.0

  out_min := 0.0
  out_max := 100.0
  dT /int? // in ms

  deviation_last /float := 0.0
  out_last /float := 0.0

  constructor --.id --.dT/int:

// ----------------------------------------------------------------------------
// Inputs
  pv -> float:
    return inputs[0].value

  sp -> float:
    return inputs[1].value
  
  auto -> bool:
    return inputs[2].value

  manual_out -> float:
    return inputs[3].value

// Module interface ----------------------------------------------------------
  tick -> none:
    deviation := pv-sp
  //  integral := (ks*kp2*deviation*dT)/Ti 
    proportional := (deviation - deviation_last)*ks*kp
    print "deviation $(%.1f deviation) auto $(auto)"
    if auto:
      setco_ (proportional + out_last) //  setco_ (integral + proportional + out_last)
      print "PID $(id) prop: $(proportional) ks=$(ks) kp=$(kp) out_last=$(out_last)"
    else:
      setco_ manual_out
    deviation_last = deviation
// ----------------------------------------------------------------------------
  stringify -> string:
    return "PID $(id)"

  setco_ val/float -> none:
    outputs[0] = min (max out_min val) out_max
    out_last = outputs[0]

  tune --.ks/int --.kp/float --ki=float -> none:
    kp2 = ki

class Barchart implements Model Module:
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

  // Only update the display a fraction of the loop cycle time.
  tick -> none:
    n += 1
    if n == every_ticks:
      n = 0
      changed

  // Model interface -----------------------------------------------------------
  addDependant dep/any -> none:
    dependants.add dep

  changed -> none:
    dependants.do:
      it.update
  // ---------------------------------------------------------------------------

class Faceplate implements Model Module:
  id /string
  dependants /List := []
  inputs := List 2  // from the control scheme to the operator
  input_names := ["pv", "a_out"]
  outputs := [60.0, true] // from the operator to the control scheme
  output_names := ["sp", "auto"]
  every_ticks /int := 4
  n := 0

  constructor --.id --dT/int:
    every_ticks = max 1000/dT 5

  stringify -> string:
    return "Faceplate $(id)"

  pv -> float:
    return inputs[0].value

  output -> float:
    return inputs[1].value

  sp= val/float -> none:
    outputs[0] = val

  auto= val/bool -> none:
    outputs[1] = val

  // Only update the display a fraction of the loop cycle time.
  tick -> none:
    n += 1
    if n > every_ticks:
      n = 0
      changed

// Model interface -----------------------------------------------------------
  addDependant dep/any -> none:
    dependants.add dep

  changed -> none:
    dependants.do:
      it.update

