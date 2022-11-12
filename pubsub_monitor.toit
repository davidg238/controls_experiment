// Derived from:  https://gist.github.com/kasperl/93aa561cf24f6430d0440ea01bd3e5c2

import system.services
import monitor
import .pubsub

main:
  client := PubsubServiceClient
  cmd := client.subscribe "fp01/cmds"
  vals := client.subscribe "fp01/vals"

  x := task::
    cmd.listen:
      print "cmds $it"
  
  y := task::
    vals.listen:
      print "vals $it"