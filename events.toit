class MotionEvent:

class WeatherEvent:
  map/Map

  constructor.changed .map/Map:

class RangeEvent:
  map/Map

  constructor.changed .map/Map:

class JogEvent:
  l  := false
  r  := false
  u  := false
  d  := false
  s  := false

  constructor.left:
    l = true
  constructor.right:
    r = true
  constructor.up:
    u = true
  constructor.down:
    d = true
  constructor.select:
    s = true

  bstr in/bool -> string:
    return if in: "1" else: "0"

  stringify -> string:
    return "jog: $(bstr l)$(bstr r)$(bstr u)$(bstr d)$(bstr s)"