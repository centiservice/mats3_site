---
title: "Happy Developers"
permalink: /docs/devops-happiness/
excerpt: "Mats makes developers happy!"
created_date: 2022-12-07T23:40:55
last_modified_at: 2022-12-10T12:46:33
classes: wide
---

Developer features:

* Pragmatic and natural API with lots of functionality for many situations
  * Flow message types: request, reply, next, nextDirect, goTo
  * Initiate new flows from within a flow
  * "Sideload" larger binary data
  * "TraceProperties", acting like a ThreadLocal - basically a "FlowLocal"
  * "Stash" and "Unstash" a flow
  * Add metric measurements, timings
* MatsFuturizer for sync-async bridge - see [own article](/docs/sync-async-bridge/)

Transactional stage processing. (see article on github)

Spanning dev and prod/ops
* TraceId, InitiatorId
* Logging & Metrics - see [own article](/docs/interception/)
* MatsLocalInspect - an embeddable HTML pane for introspection of the service's MatsFactory(s).

Prod/ops
* MatsBrokerMonitor - see [own article](/docs/matsbrokermonitor/)