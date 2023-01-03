---
title: "Message-Oriented RPC"
permalink: /docs/message-oriented-rpc/
excerpt: "Explanation of what Mats is"
created_at: 2022-12-07T23:40:24
last_modified_at: 2022-12-13T23:14:05
classes: wide
---

Mats<sup>3</sup> is a client side Java library that makes asynchronous message-oriented interservice communications
mimic a synchronous, blocking and linear/sequential way of coding. The Mats<sup>3</sup> API is currently implemented on
top of JMS talking via ActiveMQ or Artemis as message broker.

## ISC using HTTP

When you use HTTP as your inter-service communications layer in a multi-service architecture, you naturally get a linear
code style, since HTTP itself is a blocking protocol: You open a TCP connection to a server, send your request, and
block while waiting for the response. You eventually get the response, at which point your thread continues the process.

If you had some necessary variables present before the request, these are naturally still present after the response has
come back, so you can calculate your result based on the sum of information. You can then finish of the process, which
might be to return the response to whoever asked (and thus blocked on you).

## ISC using ordinary Messaging

In a messaging-based, asynchronous, stateless architecture, you're in a different situation. A receiver typically picks
up a message from an incoming queue, performs the necessary actions, and finishes its part of the job - which may
involve putting the result on a different outgoing queue. The executing thread then typically goes back to picking up a
new message from its incoming queue.

To follow the process, you'll need to find the receiver that listens to the previous stage's outgoing queue. This might
reside in a different codebase. If you have state outside the request that needs to be present for downstream
processing, this either needs to be put on some shared storage, or sent along with the messages for the downstream
stages. The distribution of code and logic complicates reasoning, system comprehension, and reusability.

## ISC using Mats<sup>3</sup>

But, what if you in an Endpoint could simply invoke a `request(..)`-method, and have the corresponding
_Reply_ message show up in a code block right below? And where any state present in the first code block, still is
present in the second code block? And you didn't have to think about JMS Consumers, Producers, Messages or other
intricacies of the messaging API? All while these codeblocks are independent stateless and transactional consumers of
message from independent message queues, where it doesn't matter if the second code block ends up executing on a
different node than the first?

That is, something like
this (<a href="https://github.com/centiservice/mats3/blob/main/mats-api-test/src/test/java/io/mats3/api_test/basics/Test_MultiLevelMultiStage.java">code</a>):

```java
class Example {
    void setupMainMultiStagedService(MatsFactory matsFactory) {
        // Create three-stage "Main" Endpoint
        var ep = matsFactory.staged(ENDPOINT_MAIN, MainRequestDto.class, State.class);

        // Initial Stage, receives incoming message to this Main service
        ep.stage(MainRequestDto.class, (context, state, dto) -> {
            // State object is empty at initial stage.
            Assert.assertEquals(0, state.number1);
            Assert.assertEquals(0, state.number2, 0);
            // Setting some state variables.
            state.number1 = Integer.MAX_VALUE;
            state.number2 = Math.E;
            // Perform request to "Mid" Endpoint...
            context.request(ENDPOINT_MID, new MidRequestDto(dto.number, dto.string));
        });
        ep.stage(MidReplyDto.class, (context, state, dto) -> {
            // .. continuing after the Mid Endpoint has replied.
            // Assert that state variables set in previous stage are still with us.
            Assert.assertEquals(Integer.MAX_VALUE, state.number1);
            Assert.assertEquals(Math.E, state.number2, 0);
            // Changing the state variables.
            state.number1 = Integer.MIN_VALUE;
            state.number2 = Math.E * 2;
            // Perform request to "Leaf" Endpoint...
            context.request(ENDPOINT_LEAF, new LeafRequestDto(dto.number, dto.string));
        });
        ep.lastStage(LeafReplyDto.class, (context, state, dto) -> {
            // .. continuing" after the Leaf Endpoint has replied.
            // Assert that state variables changed in previous stage are still with us.
            Assert.assertEquals(Integer.MIN_VALUE, state.number1);
            Assert.assertEquals(Math.E * 2, state.number2, 0);
            // Return result to caller
            return new MainReplyDto(dto.number * 5, dto.string + ":FromMainService");
        });
    }

    // State class
    static class State {
        int number1;
        double number2;
    }

    // DTOs omitted
}
```

Each of the three lambdas are independent message consumers, consuming from three different queues, but you can 
_mentally_ view them as a single Endpoint which executes linearly, and as part of the processing invokes two external
Endpoints.

This is what Mats<sup>3</sup> enables.

Mats<sup>3</sup> stands for _Message-oriented Asynchronous, Transactional, Staged, Stateless Services!_  
Mats<sup>3</sup> is _Messaging with a call stack!_  
Mats<sup>3</sup> is _Message-Oriented Asynchronous RPC!_

_There's a bit more about the rationale for Mats, and the benefits of messaging-based architectures
[here](https://github.com/centiservice/mats3/blob/main/docs/RationaleForMats.md), and some further
musings on what Mats is [here](https://github.com/centiservice/mats3/blob/main/docs/WhatIsMats.md)_ 

So, how to start Mats Flows? Go to the [next chapter](/docs/mats-flow-initiation)!