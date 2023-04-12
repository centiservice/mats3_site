---
title: "TraceId and InitiatorId"
permalink: /using-mats/traceid-and-initiatorid/
excerpt: ""
created_at: 2022-02-19T12:00
last_modified_at: 2023-02-12T12:30
classes: wide
---

Mats has several concepts for aiding debugging, introspection, logging and tracing, and metrics gathering.

These concepts are:

1. A MatsFactory must be instantiated with an ApplicationName and ApplicationVersion. This is meant to be name of the
   containing service. E.g. if you have an "OrderService" of version "2022-02-18-build4321-e7084be" containing a
   MatsFactory, then that would be the `appName` and `appVersion`.
2. Every Mats initiation, which initiates a _Mats Flow_, must state its `InitiatorId`, which should be unique as to
   _where in the code_ the initiation happens - **but not unique per initiation**.
3. and finally, every initiation must create a unique `TraceId` which follows the Mats Flow till it ends - this is
   unique for each initiation, i.e. unique for each initiated _Mats Flow_. It is used to follow the flow, using your
   centralized logging system.

All Stages in a Mats flow, from its initiation to its end which is when a stage doesn't create an outbound flow message,
will have these common elements present (and this holds no matter which host it passes through).

1. InitiatingTimestamp
2. InitiatingAppName, InitiatingAppVersion
3. InitiatorId
4. TraceId

(Each individual Stage also knows who the current message came from, i.e. the FromApplicationName|Version, and
FromStageId. Note that a MatsFactory also has a `name`, which is relevant if a service has multiple MatsFactories, e.g.
connecting to multiple backing message brokers - the name should then reflect which broker it is connected to.)

Understand that Mats itself will work just fine even if you set all these to the empty string - this is _purely_ for
human consumption, to aid in reasoning about bugs and performance. But the fact that these elements follow along with
the Mats flow, no matter which server is processing it currently, is simply amazingly useful, and you will very much
regret not having set a good InitiatorId and TraceId once you sit with 200 random messages on a DLQ, or wonder why
_some_ of these extremely similar Mats Flows take an age to complete, while most other run fast.

There is a clear granularity level:

1. InitiatingAppName: Common for all flows originating _from a specific service_.
2. InitiatorId: Common for all flows originating _from one specific place_ within a service.
3. TraceId: Unique per Mats Flow, with lots of context for "human parsing".

The two first are used when you want to aggregate multiple flows, while the latter is used when you want to look up and
follow one specific Mats Flow, typically through the system-wide logging system.

To utilize these features to their fullest, here's some guidelines:

## ApplicationName

The ApplicationName is set in the construction of the MatsFactory, and is as such common for any flow that originates
from that MatsFactory, and thus typically for all flows originating in that codebase (the typical setup is a singleton
MatsFactory per service). If there are multiple instances of the service, they shall all have the same ApplicationName.
(Inside the Flow, the "nodename" (hostname) is automatically added to distinguish between different instances.)

## InitiatorId

The InitiatorId is a free-form String, which should be pretty short. It is set upon initiation of a flow; it is
the `init.from(initiatorId)` parameter. It is important to understand that this _must not_ induce "cardinality
explosions" wrt. metrics gathering: It _shall not_ include e.g. any customer-specific element like the customerId. It
shall instead refer, effectively, to the _location in the code_ where the flow originates.

Together, the ApplicationName and InitiatorId should reflect _from where_ an initiation happens: The InitiatingAppName
combined with the InitiatorId should immediately convey which service initiated this Mats Flow, and from _where within
that service_ the flow was initiated.

For example, if the flow is initiated from a "/api/userDetails" REST endpoint, the initiatorId could well be
"http:api/userDetails". If the flow is initiated within a batch process fulfilling orders, it could be
'OrderFulfillmentScheduledTask' or something relevant. The point is to immediately understand from which particular part
of the total codebase these flows are started from - and if you do not already know that service, you go to the service
named in the InitiatingAppName, and search for the InitiatorId, and should then immediately find the location.

If multiple flows are started from the same place, and this is obvious when you enter the code, and it makes logical
sense, they should share a common prefix. This gives the added benefit of being able to collate such flows in logging
and metrics. For example, if the "/api/userDetails" REST endpoint fires off multiple MatsFuturizer requests (thus
parallelizing them), it makes good sense that they all share the "http:api/userDetails", while adding a "sub id", e.g.
"http:api/userDetails:latestOrders", "http:api/userDetails:credit" and "http:api/userDetails:benefits".

For the Stage directly receiving an initiation, the `ProcessContext.getFromStageId()` == the InitiatorId - and this is
also a way to look at it: It is the identifier of the fictive Mats Stage representing the "0th call" in the Mats Flow.

## TraceId

A TraceId is a free-form String, which should be short but still include good context. It is set upon the initiation of
a flow; it is the `init.traceId(traceId)` parameter. As opposed to the initiatorId, each TraceId should uniquely
identify a single initiation, and both _may_ and _should_ include relevant contextual information, like for example the
relevant customerId.

The first and foremost aspect is that it should be unique, to uniquely identify all the log lines of a particular Mats
Flow in the system-wide logging system. A UUID definitely fulfills this requirement - but it falls flat in every other
aspect a good TraceId could help with. _(Even for the unique-requirement, it fails. It is way too verbose; both is it
way too unique wrt. the "universe" it lives in, and it only utilizes 16 different code points, both aspects resulting in
the string being annoyingly long compared to the little information it holds.)_

Making a good TraceId is (evidently) an art! From the TraceId _alone_, one should ideally be able to discern as much
information as possible, while still keeping the string as short as possible!

A TraceId is only meant for human consumption, and it would be a grave mistake to parse it and use elements of it in
processing or even analysis/metrics. Their structure should be expected to change relatively often, as developers find
it interesting to modify or add pieces of information to it.

A good traceId should contain most of:

1. Some "from"-context.
    1. Quite possibly a short-form of the ApplicationName: "CustPortal", "Order", "Warehouse", "Auth".
    2. Possibly a short-form of the Initiator point: "userDetails", "orderReceived"
2. What it concerns: Possibly a short-form of the "to" aspect: "calculateShipping", "sendTrackingUpdate"
3. Which entity or entities the flow concerns: CustomerId, OrderId, SKU
4. IF (and only if!) this is part of a batch of messages, then include a "batchId", so that one can search for all Mats
   Flows originating from the same batch.
5. A piece of randomness, so that if for some reason two otherwise identical Mats Flows are produced, either on purpose
   or accident (the user managing to place an order twice), the Mats Flows can be distinguished anyway.

Points #1 and #2 are intersecting with the information in ApplicationName and InitiatorId, but experience has shown that
TraceIds having such information are more valuable than those that don't: In a debugging context, you typically end up
with the single piece of information that is the TraceId, i.e. "Could you check up on this flow? {TraceId}" - and as
such it gives very good value if it alone holds as much context as possible. _(On the other hand, in a metrics
situation, aggregating many Mats Flows, you do not have the TraceIds available, and thus you want the ApplicationNames
and InitiatorIds to alone give good context, i.e. "all these slow flows originate from the Account system in the
CalculateOutstanding part of the code - what burden is it that those flows adds?".)_

The TraceId should be established as close to the event triggering the Mats Flow as possible. If the action originates
from a user interface, it should preferably be started there. _(For information about automatic prepending of an
incoming HTTP-call's X-Request-ID header, check out the `FactoryConfig.setInitiateTraceIdModifier(function)`
functionality)_

When storing an order in the order table, it makes sense to also store the TraceId along. This both to correlate the
order with the logging, and since it has all these nice contextual elements in it, you may understand how that order
ended up in the table. Also, when this order moves along, e.g. gets fulfilled, then the resulting Mats Flows should be
initiated with a TraceId containing the Order-TraceId as a part. You may then gain a great effect in being able to
follow the flow of that order from when the user clicks "buy" to it being delivered on his door, by searching with a
single string.

There's two characters that could be considered (somewhat) reserved:

* "+": When a Mats Flow's TraceId is composed from multiple events, each having some id:
    * If the HTTP call includes a X-Request-ID header, this could be prepended to the resulting Mats Flow's TraceId with
      a "+".
    * If some process instruction is stored in a table via one Mats Flow, and then a specific event targets that, the
      resulting MatsFlow could be the "sum" of the original TraceId and the new event's (Trace)Id. (Note that if the
      event is of a type that may trigger multiple such process instructions, you should use the next special character
      instead!)
    * Think of it as a _string concatenation_ of TraceIds/EventIds.
* "\|": If a Mats Flow A (or an event) spawns multiple new Mats Flows B1 and B2, the resulting TraceIds should be
  "A\|B1" and "A\|B2".
    * It is employed automatically if you initiate messages within a Stage, i.e. `ProcessContext.initiate(..)`
    * If a new shipment of widgets comes in, this would result in a bunch of orders becoming eligible for fulfilment.
      The resulting bunch of new Mats Flows could have TraceIds of the form "{single incoming
      WidgetShipmentTraceId}|{original OrderTraceId}"
    * Think of it as a _fork_/_spawn_ of TraceIds.

There is no hard and fast rules here, other than the uniqueness requirement. It should just be as helpful as possible.
Here's some fictive examples, just to give a hint towards which type of information pieces that may be of use in a
TraceId:

* `Web.Cart.shippingPage[cartid:32f93818a27b2]lo85cma+CustPortal.calculateShipping[cid:12345631][oid:68372957]xhe71pj`
* `Web.Cart.placeOrder[cartid:32f93818a27b2]758aj4l2+CustPortal.placeOrder[cid:12345631][oid:68372957]8kfm39i`
* `Warehouse.fulfilOrders[batchId:uj2lqlcv]|fulfilOrder:Web.Cart.placeOrder[cartid:32f93818a27b2]758aj4l2+CustPortal.placeOrder[cid:12345631][oid:68372957]8kfm39i`

By searching for the "placeOrder" string, you'll also find the secondary fulfilling MatsFlow, and thus find the
fulfilling batchId. By searching for the fulfilOrders batch string, you'll also find all Mats Flows for the orders that
was fulfilled in that batch.

If you work with a debugging a problem, and find that for the next time around it would have been great if the TraceId
contained this particular piece of information, then obviously: Go add it! The next developer that gets a similar
situation will thank you - and it will of course often be you!