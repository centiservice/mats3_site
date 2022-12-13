---
title: "Sync-Async bridge"
permalink: /docs/sync-async-bridge/
excerpt: "MatsFuturizer provides a tool for invoking a Mats Endpoint from a synchronous context"
created_at: 2022-12-07T23:41:35
last_modified_at: 2022-12-13T00:18:00
classes: wide
---

So, you're in a synchronous setting where you need to reply with something which a Mats Endpoint can provide. For
example in a Servlet, or a Spring `@RequestMapping`. If you use a `MatsInitiator` and perform a request, the reply
will come to the Terminator you specified. However, even if that Terminator resides in the same codebase, there is no
connection back to the thread you're in. Even worse, in a multi-node setup, where you've fired up a dozen replicas of
this service, the reply will most probably come to an instance of the Terminator residing on a different replica.

So, how can we employ the Mats fabric to provide information in a synchronous setting?

## MatsFuturizer

The answer is the `MatsFuturizer`. This is simply a tool on top of the Mats API - meaning that you could implement this
yourself using Mats only.

The solution is twofold:
1. Ensure that the reply comes back to _this_ replica. Simple: Use a replica-specific replyTo Terminator id.
2. Block the thread, waiting for the reply. Simple: Make a Map of outstanding requests, mapped on a correlation-id which
   you set as the state for the targeted Terminator, and when the Terminator receives a reply for a specific
   correlation-id, it wakes up the corresponding waiting thread, providing the result.

It would be tedious to code up all this each time you need it, taking timeouts into account, collection garbage from
never-returning replies (flows that have DLQed), and a few other tidbits, so there's a tool for it: The `MatsFuturizer`.

It's pretty simple to use: You provide the parameters for an initiation, and then get a `Future` in return. This Future
will be completed once the invoked Mats Endpoint replies.

Here's a futurization:

```java
// Futurization!
CompletableFuture<Reply<TestReplyDto>> future = futurizer.futurizeNonessential(
       "traceId", "initiatorId", "Target.endpoint", TestReplyDto.class,
        new TestRequestDto(100, "A hundred widgets"));

// Immediately wait for result:
Reply<TestReplyDto> result = future.get(10, TimeUnit.SECONDS);
```
_Unit test [here](https://github.com/centiservice/mats3/blob/main/mats-util/src/test/java/io/mats3/util/futurizer/Test_MatsFuturizer_Basics.java)._

`MatsFuturizer` JavaDoc [here](https://mats3.io/javadoc/mats3/0.19/modern/io/mats3/util/MatsFuturizer.html).

**Notice!! Please make sure that you never code a Mats Endpoint where a stage executes a MatsFuturization**: This breaks
the premise and guarantees of Mats pretty hard, in that you now have a Mats Stage waiting synchronously and statefully
on a nested Mats Flow. If the machine processing this stage goes down, it takes the future with it - resulting in a
redelivery on the "outer" flow. Also, invoking one Mast Endpoint from another is literally the entire point of the Mats
stack and the `request` method - "synchronous nesting" breaks the linearity of the Mats Flow in a very fundamental
way. **The MatsFuturizer should only be used on the very outer edges, where you have a synchronous call that needs to
bridge into the asynchronous Mats fabric.** There's a document going further into this
[here](https://github.com/centiservice/mats3/blob/main/docs/developing/MatsComposition.md).

Top notch. But you're in a Spring setting, and using programmatic Java to configure Mats Endpoints feels a bit last
century. Annotations rocks! [next chapter](/docs/springconfig/)