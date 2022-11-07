interface Module:
  out -> List
  tick -> none

interface Model:
  addDependant dep/any -> none
  changed -> none

class Scheme:
  modules /List := List 16
  dT /int := 200

  constructor --.dT:

  add module/Module -> none:
    modules.add module

  connect --from/int --out/int --to/int --in/int -> none:
    modules[to].in[in] = Wire modules[from] out

  run -> none:
    modules.do:
      it.tick
    sleep --ms=dT

class Wire:
  module/Module?
  out/int?

  constructor .module .out:

  value -> any:
    return module.out[out]

class SimInput implements Module:
  in := []
  out := []
  sim /Lambda?
  
  constructor --.sim:

  input -> float:
    return in[0].value

  tick -> none:
    out[0] = sim.call input

class SimOutput implements Module:
  in := []
  out := []
  
  input -> float:
    return in[0].value

  tick -> none:
    out[0] = input

class PID implements Module:
  /* 
  in[0] = pv
  in[1] = sp
  in[2] = auto
  in[3] = manual_out
   */
  in := []
  out := []

  ks /int := 1
  kp /float := 0.0
  kp2 /float := 1.0

  out_min := 0.0
  out_max := 100.0
  dT /int? // in ms

  deviation_last /float := 0.0
  out_last /float := 0.0

  constructor --.dT/int:

// ----------------------------------------------------------------------------
// Inputs
  pv -> float:
    return in[0].value

  sp -> float:
    return in[1].value
  
  auto -> bool:
    return in[2].value

  manual_out -> float:
    return in[3].value

// Module interface ----------------------------------------------------------
  tick -> none:
    deviation := pv-sp
  //  integral := (ks*kp2*deviation*dT)/Ti 
    proportional := (deviation - deviation_last)*ks*kp
    if auto:
      setco_ (proportional + out_last) //  setco_ (integral + proportional + out_last)
    else:
      setco_ manual_out
    deviation_last = deviation
// ----------------------------------------------------------------------------

  setco_ val/float -> none:
    out[0] = min (max out_min val) out_max
    out_last = out[0]

  tune --ks/int --kp/float --ki=float -> none:

class Barchart implements Model Module:
  dependants /List := []
  in := []
  out := []
  every_ticks /int := 4
  n := 0

  constructor --dT/int:
    every_ticks = 1000/dT

  in0 -> float:
    return in[0].value

  in1 -> float:
    return in[1].value

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
  dependants /List := []
  in := []  // from the control scheme to the operator
  out := [50.0, true] // from the operator to the control scheme
  every_ticks /int := 4
  n := 0

  constructor --dT/int:
    every_ticks = 1000/dT

  pv -> float:
    return in[0].value

  output -> float:
    return in[1].value

  sp= val/float -> none:
    out[0] = val

  auto= val/bool -> none:
    out[1] = val

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

