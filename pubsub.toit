// Derived from:  https://gist.github.com/kasperl/93aa561cf24f6430d0440ea01bd3e5c2

import system.services
import monitor

interface Subscription:
  listen [block] -> none

// ------------------------------------------------------------------

interface PubsubService:
  static UUID/string ::= "b18a72c7-b3e5-4172-8987-375868d06d37"
  static MAJOR/int   ::= 1
  static MINOR/int   ::= 0

  subscribe topic/string -> int
  static SUBSCRIBE_INDEX ::= 0

  publish topic/string payload/string -> none
  static PUBLISH_INDEX ::= 1

// ------------------------------------------------------------------

class PubsubServiceClient extends services.ServiceClient implements PubsubService:
  constructor --open/bool=true:
    super --open=open

  open -> PubsubServiceClient?:
    return (open_ PubsubService.UUID PubsubService.MAJOR PubsubService.MINOR) and this

  subscribe topic/string -> PubsubSubscription:
    handle := invoke_ PubsubService.SUBSCRIBE_INDEX topic
    return PubsubSubscription topic this handle

  publish topic/string payload/string -> none:
    invoke_ PubsubService.PUBLISH_INDEX [topic, payload]

class PubsubSubscription extends services.ServiceResourceProxy
    implements Subscription:
  topic_/string
  channel_/monitor.Channel ::= monitor.Channel 16

  constructor .topic_ client/PubsubServiceClient handle/int:
    super client handle

  listen [block] -> none:
    while true:
      block.call channel_.receive

  on_notified_ payload/string -> none:
    channel_.send payload

// ------------------------------------------------------------------

class PubsubServiceDefinition extends services.ServiceDefinition implements PubsubService:
  subscriptions_/Map := {:}

  constructor:
    super "pubsub" --major=1 --minor=0
    provides PubsubService.UUID PubsubService.MAJOR PubsubService.MINOR

  handle pid/int client/int index/int arguments/any -> any:
    if index == PubsubService.SUBSCRIBE_INDEX:
      return subscribe arguments client
    if index == PubsubService.PUBLISH_INDEX:
      return publish arguments[0] arguments[1]
    unreachable

  subscribe topic/string -> int:
    unreachable

  subscribe topic/string client/int -> PubsubSubscriptionResource:
    subscription := PubsubSubscriptionResource topic this client
    subscriptions := subscriptions_.get topic --init=: []
    subscriptions.add subscription
    return subscription

  publish topic/string payload/string -> none:
    subscriptions := subscriptions_.get topic
    if not subscriptions: return
    subscriptions.do: | subscription/PubsubSubscriptionResource |
      subscription.publish payload

class PubsubSubscriptionResource extends services.ServiceResource:
  topic_/string
  service_/PubsubServiceDefinition

  constructor .topic_ .service_ client/int:
    super service_ client --notifiable

  publish payload/string -> none:
    notify_ payload

  on_closed -> none:
    subscriptions := service_.subscriptions_.get topic_
    if subscriptions: subscriptions.remove this