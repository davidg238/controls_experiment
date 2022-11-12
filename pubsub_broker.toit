// Derived from:  https://gist.github.com/kasperl/93aa561cf24f6430d0440ea01bd3e5c2

import system.services
import monitor
import .pubsub

client_ ::= PubsubServiceClient

main:
  spawn::
    service := PubsubServiceDefinition
    service.install
    service.uninstall --wait

subscribe topic/string -> Subscription:
  return client_.subscribe topic

publish topic/string payload/string -> none:
  client_.publish topic payload
