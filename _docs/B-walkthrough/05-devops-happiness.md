---
title: "Happy Devs and Ops"
permalink: /docs/devops-happiness/
excerpt: "Mats makes developers happy!"
created_at: 2022-12-07T23:40:55
last_modified_at: 15.12.2022T20:39
classes: wide
---

Mats aims to please both the developers making a distributed system, and the folks that need to handle the system when
it runs in production - which may or may not be the same developers, or dedicated operations personnel.

Wrt. development, Mats has multiple features for making it a pleasure to communicate between services in a messaging
fashion, providing a simple API.

Wrt. operations, the features mainly revolves about robustness, traceability, metrics, introspection, and handling of
dead letters.

### Transactional processing

Initiations, and each stage processing, is executed within a transaction, spanning both the message broker and DB. This
means that for a stage, the reception of a message, processing of the message including db changes, and sending of an
outgoing message, are all done, or none of it is done. This means that the system is extremely robust: Once you've
managed to initiate a Mats Flow onto the Mats Fabric, i.e. sent the first message, it will go through and finish on the
Terminator, _or_ end up on a dead letter queue. In no way it is possible to lose the Mats Flow without trace.

Rebooting machines, deploying new versions, scaling up and down, and crashes, are handled without any issue.

There's more about the transactionality of Mats [here](https://github.com/centiservice/mats3/blob/main/docs/developing/TransactionsAndRedeliveries.md).

### Pragmatic and natural API with lots of functionality for many situations

* Flow message types - what outgoing functions you can do in a stage:
  * `request` and `reply`: demonstrated a few chapters ago.
  * `next`: Jump to the next stage. This is used to construct "if-else" constructs within Mats Flows: You might in some
    instance of this process need to communicate with a collaborating service, while in others, you can just go directly
    to the next stage.
  * `nextDirect`: A faster variant of next, where the next stage is directly invoked without swinging by the message
    broker and also eliding the transactional demarcation between the two stages.
  * `goTo`: For some scenarios it would be nice to keep the call stack and go directly to another endpoint. When the
    goto'ed endpoint replies, it will reply to the caller of this endpoint. Useful in a dispatcher situation, and also
    in a tail call situation.
* Initiate new flows within a stage processing. These flows are started within the same transactional demarcation as the
  stage they're running. Can both be used for orchestration, and for sending off a "side flow" for notification to a
  different system. They automatically inherit the current Flow's traceId, but you can append to it.
* Use pub/sub messaging, i.e. _topic_-semantics instead of queues, by use of `subscriptionTerminator`-type Endpoint,
  and `publish` instead of `send`. You may also target the reply in an initiation to go to a subscriptionTerminator by
  using `replyToSubscription(...)`. You may think of this as a "broadcast"-functionality, compared to the single-fibre
  Mats Flows. Useful in cache population and -invalidation, as well as updating state & GUIs no matter which node a user
  is connected to.
* "Sideload" larger binary and text data, to e.g. carry a PDF document (but, do mind your message sizes!)
* "TraceProperties", acting like a ThreadLocal - basically a "FlowLocal": These props are present on the Mats Flow, i.e.
  available for all downstream stages, from when they are set, which can be both at initiation and any stage.
* `MatsFuturizer`-utility for sync-async bridge - see [own article](/docs/sync-async-bridge/). In GUI-settings, the
  sister project [MatsSocket](https://matssocket.io) should also be checked out.
* `interactive`-priority Mats Flows: If you mark an initiation as interactive, it gets a "cut the line" flag through the
  entire flow processing. This means that the same endpoints may be used for batch processing, racking up queues, but
  still be used for human-interactive GUI operations.
* `nonPersistent` Mats Flows: Marking an initiation as non-persistent results in the MQ broker not persisting the
  messages, thereby gaining a substantial speed advantage. It does mean that it is possible that the flow will be
  broken (if the broker crashes or is booted, as the messages are only stored in mem), but in GUI settings where the
  flow only concerns getters of information, this tradeoff is most probably worth it. The combination `interactive` +
  `nonPersistent` is common, and is what the `MatsFuturizer` sets when the `futurizeNonessential(..)`-method is
  employed.
* `stash` and `unstash` a Mats Flow: For some processes, you might need to invoke another asynchronous service with
  possibly very varying response times. To not hold up the stage processor, you can stash the flow. This gives you a
  byte array which you need to store, typically in a database. The Mats Flow is now "frozen". When you eventually get
  the response from the outside service, you can unstash the Mats Flow and provide the result, thus continuing the flow
  from there. This can also be used to park a flow while a human is evaluating some details, e.g. identification - but
  it is not meant for long term parking of flows, as that increases the chance of deserialization errors if you change
  state objects or DTOs active in the flow.
* Add own metrics: On the stage context, you can add metric measurements and timings, e.g. how long a db query takes.
  These are available for the Interceptor API, and can be output in logging and metrics - see next chapter.

### TraceId - following a Mats Flow from start to finish

When initiating a Mats Flow, you are required to provide a 'traceId'. This identifier follows all the processing
throughout the Mats fabric for this particular flow, and - if you use a centralized logging system (well, of course you
do) - you can use this Id to follow the flow from message reception, processing, and outgoing message, for each stage.
The traceId is put on the MDC of SLF4J during stage processing, so that any output log lines within a processing 
(i.e. loglines in your code) also are tagged.

In addition, it is highly suggested to use meaningful and information-rich traceIds, so that you can read out quite a
bit of information from the Id alone.

Such a tracing solution is obviously mandatory for every multi-service solution, but you'll often have to jump through
hoops and code quite a bit to get this to follow through. With Mats, you get this for free - and if you give some
thought to how you cook up that Id, you gain even more.

There's also a concept of `initiatorId`, as well as the `appName` and `appVersion`. All these follow the Mats flow from
start to finish, and give you many angles to understand both individual flows, and also aggregates.

There's a document about traceIds and initatorIds 
[here](https://github.com/centiservice/mats3/blob/main/docs/developing/TraceIdsAndInitiatorIds.md).

### Intercept API, Logging and Metrics

There's an additional API implemented by the JMS Mats implementation: The Mats Intercept API. This provides hooks to
all stages of a Mats flows, from initiation, message sending, message reception and processing.

There are two standard plugins to Mats, implemented over the Intercept API, which provide a very rich logging
experience (using SLF4J), and metrics for e.g. Prometheus (using Micrometer).

For more about interception, logging and metrics, read [own article](/docs/interception/).

### MatsTrace

The JMS implementation of Mats employs _MatsTrace_ as its wire protocol. This has additional debugging features whereby
it effectively keeps a trace of all stages of all endpoints that it has passed through. This is extremely nice when the
message ends up on a Dead Letter Queue of some stage: You immediately, without even accessing any logs, can see tons of
meta info about the initiation and the current call, and also which endpoints and stages it has so far passed through.

The level of "trace keeping" is configurable, between MINIMAL (just metadata + current call), COMPACT (metadata + log of
each stage processing), and FULL (metadata + every request, response and state change while going through every stage).
This must be set at initiation, and have a default on the MatsFactory. The default of that is COMPACT. The reason that
FULL is not default is because that can become pretty heavy if the Mats Flows are long, and/or if you use large state
objects and/or large requests and responses; All versions of state, and all requests and responses, are then kept in the
MatsTrace envelope.

A suggestion is to use `KeepTrace.FULL` while developing and stabilizing new Mats Endpoints and processes, and when they
have proven themselves to be close to error free over some time, reduce the level to `KeepTrace.COMPACT`. The latter is
a happy compromise between small and fast messages for the ~100% where things go OK, and still nice introspection
when some corner-case message inevitably ends up on a DLQ anyway. `KeepTrace.MINIMAL` should not really be needed - you
are probably using too high granularity if shaving off those few extra bytes makes a difference.

### Embeddable HTML MatsFactory introspection - `MatsLocalInspect`

If you have a "developer monitor" for each of your services - which I suggest that you do! - then you can employ a nice
feature of Mats: You can make a page in the dev monitor which shows the MatsLocalInspect HTML-embeddable MatsFactory
introspection pane.

It shows all details of the MatsFactory, and all MatsInitiators, all MatsEndpoints and all Stages - and if you install
its corresponding Interceptor, you even get rudimentary statistics about number of calls and timings for each stage and
endpoint.

### MatsBrokerMonitor - for monitoring of the backing message broker

When using Mats - or really any messaging based infrastructure - you gain a massive advantage by having many of the
errors in the total system "crop up" on the message broker. However, to catch these errors, you need to monitor it.

See [own article](/docs/matsbrokermonitor/)

Okay, so great tooling - but what is the Intercept API? Onwards to [next chapter](/docs/interception/)!
_(Or go to [explore](/explore/)!)_