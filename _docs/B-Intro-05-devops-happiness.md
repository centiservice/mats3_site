---
title: "Happy Developers"
permalink: /docs/devops-happiness/
excerpt: "Mats makes developers happy!"
created_at: 2022-12-07T23:40:55
last_modified_at: 2022-12-13T23:17:00
classes: wide
---

Mats aims to please both developers, and folks that need to handle the system when it runs in production - which may
or may not be the same developers, or dedicated operations personnel.

Wrt. development, Mats has multiple features for making it a pleasure to communicate between services in a messaging
fashion, providing a simple API.

Wrt. operations, the features mainly revolves about robustness, traceability, metrics, introspection, and handling of dead letters.

### Transactional processing

Initation, and each stage, is executed within a transaction, spanning both the message broker and DB. This means that
for a stage, the reception of a message, processing of the message including db changes, and sending of an outgoing
message, are all done, or none of it is done. This means that the system is extremely robust: Once you've managed to get
an initation onto the Mats Fabric, it will go through _or_ end up on a dead letter queue. In no way it is possible to
lose the Mats Flow without trace.

Rebooting machines, deploying new versions, scaling up and down, and crashes, are handled without any issue.

There's more about the transactionality of Mats [here](https://github.com/centiservice/mats3/blob/main/docs/developing/TransactionsAndRedeliveries.md).

### Pragmatic and natural API with lots of functionality for many situations

* Flow message types - what outgoing function you can do in a stage:
  * `request` and `reply`: demonstrated a few chapters ago.
  * `next`: Jump to the next stage. This is used to construct "if-else" solutions within Mats Flows: You might in some
    instance of this process need to communicate with a collaborating service, while in others, you can just go directly
    to the next stage.
  * `nextDirect`: A faster variant of next, where the next stage is directly invoked without swinging by the message
    broker.
  * `goTo`: For some scenarios it would be nice to keep the call stack and go directly to another endpoint. When the
    goto'ed endpoint replies, it will reply to the caller of this endpoint. Useful in a dispatcher situation, and also
    in a tail call situation.
* Initiate new flows within a stage processing. These flows are started within the same transactional demarcation as the
  stage they're running. Can both be used for orchestration, and for sending off a "side flow" for notification to a
  different system.
* "Sideload" larger binary and text data, to e.g. carry a PDF document (but, do mind your message sizes!)
* "TraceProperties", acting like a ThreadLocal - basically a "FlowLocal": These props are present on the Mats Flow, i.e.
  available for all downstream stages, from when they are set, which can be both at initiation and any stage.
* `stash` and `unstash` a Mats Flow: For some processes, you might need to invoke another asynchronous service with
  possibly very varying response times. To not hold up the stage processor, you can stash the flow. This gives you a
  byte array which you need to store, typically in a database. The Mats Flow is now "frozen". When you eventually get
  the response from the outside service, you can unstash the Mats Flow and provide the result. This can also be used to
  park a flow while a human is evaluating some details, e.g. identification - but it is not meant for long term storage.
* On the stage context, you can add metric measurements and timings, e.g. how long a db query takes. These are available
  for the Interceptor API, and can be output in logging and metrics - see next chapter.
* `MatsFuturizer`-utility for sync-async bridge - see [own article](/docs/sync-async-bridge/)

### TraceId - following a Mats Flow from start to finish

When initiating a Mats Flow, you are required to provide a 'traceId'. This identifier follows all the stage processing
through the Mats fabric, and - if you use a centralized logging system (well, of course you do) - you can use this id to
follow the flow from message reception, processing, and message send, for each stage. This is put on the MDC of SLF4J,
so that any output log lines within a processing will also be tagged.

In addition, it is highly suggested to use meaningful and information-rich traceIds, so that you can read out quite a
bit of information from the id alone.

Such a logic is obviously mandatory for every multi-service solution, but you'll often have to jump through hoops and
code quite a bit to get this to follow through. With Mats, you get this for free - and if you give some thought to how
you cook up that id, you gain even more.

There's also a concept of `initiatorId`, as well as the `appName` and `appVersion`. All these follow the Mats flow from
start to finish, and give you many angles to understand both individual flows, and also aggregates.

There's a document about traceIds and initatorIds 
[here](https://github.com/centiservice/mats3/blob/main/docs/developing/TraceIdsAndInitiatorIds.md).

### Logging and Metrics

There are two standard plugins to Mats, implemented over the Interceptor API, which provide a very rich logging
experience (using SLF4J), and metrics for e.g. Prometheus (using Micrometer). See [own article](/docs/interception/).

### Embeddable HTML MatsFactory introspection - `MatsLocalInspect`

If you have a "developer monitor" for each of your services - which I suggest that you do! - then you can employ a nice
feature of Mats: You can make a page in the dev monitor which shows the MatsLocalInspect embeddable MatsFactory
introspection pane.

It shows all details of the MatsFactory, and all MatsInitiators, all MatsEndpoints and all Stages - and if you install
the Interceptor, you even get rudimentary statistics about number of calls and timings for each stage and endpoint.

### MatsBrokerMonitor - for monitoring of the backing message broker

see [own article](/docs/matsbrokermonitor/)

