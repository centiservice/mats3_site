---
permalink: /about/
title: "About"
classes: wide
---

Mats<sup>3</sup> is a library that attempts to make message-oriented architectures mimic a synchronous, blocking way of
coding.

When you use HTTP as your inter-service communications layer in a multi-service architecture, you naturally get this
style, since HTTP itself is a blocking protocol: You open a TCP connection to a server, send your request, and block
while waiting for the response. You eventually get the response, at which point you can continue the process. If you had
some necessary variables present before the request, these are naturally still present after the response has come back,
so you can calculate your result based on the sum of information. You can then finish of the process, which might be to
return the response to whoever asked (and thus blocked on you).

In a messaging based, asynchronous, stateless architecture, you're in a different situation. You typically pick up a
message from an incoming queue, perform whatever action is needed, and finish off the process, which might entail
putting the result on an different outgoing queue. The executing thread then typically goes back to picking up a new
message from its incoming queue. To continue the process, you need to go to the code which listens to the previous
stage's outgoing queue. This might reside in a different codebase. If you have state outside the request that needs to
be present for downstream processing, this either needs to be put on some shared storage, or sent along with the
messages, complicating reasoning, understanding and reusability.

But, what if you could send a Request, and have the corresponding _Reply_ show up in a code block right below? And where
any state present in the first code block, is still present in the second code block? All while these codeblocks are
independent stateless consumers of message from independent message queues, where it doesn't matter if the second
codeblock is run on a different node than the first?

That is, something like this (<a href="https://github.com/centiservice/mats3/blob/main/mats-api-test/src/test/java/io/mats3/api_test/basics/Test_MultiLevelMultiStage.java">code</a>):

```java
class Example {
    public static void setupMainMultiStagedService(MatsFactory matsFactory) {
        // Create three-stage "Main" endpoint
        MatsEndpoint<DataTO, StateTO> ep = matsFactory
                .staged(ENDPOINT_MAIN, DataTO.class, StateTO.class);

        // Initial stage, receives incoming message to this "Main" service
        ep.stage(DataTO.class, (context, sto, dto) -> {
            // State object is "empty" at initial stage.
            Assert.assertEquals(0, sto.number1);
            Assert.assertEquals(0, sto.number2, 0);
            // Setting state some variables.
            sto.number1 = Integer.MAX_VALUE;
            sto.number2 = Math.E;
            // Perform request to "Mid" Service...
            context.request(ENDPOINT_MID, dto);
        });
        ep.stage(DataTO.class, (context, sto, dto) -> {
            // .. "continuing" after the "Mid" Service has replied.
            // Assert that state variables set in previous stage are still with us.
            Assert.assertEquals(Integer.MAX_VALUE, sto.number1);
            Assert.assertEquals(Math.E, sto.number2, 0);
            // Changing the state variables.
            sto.number1 = Integer.MIN_VALUE;
            sto.number2 = Math.E * 2;
            // Perform request to "Leaf" Service...
            context.request(ENDPOINT_LEAF, dto);
        });
        ep.lastStage(DataTO.class, (context, sto, dto) -> {
            // .. "continuing" after the "Leaf" Service has replied.
            // Assert that state variables changed in previous stage are still with us.
            Assert.assertEquals(Integer.MIN_VALUE, sto.number1);
            Assert.assertEquals(Math.E * 2, sto.number2, 0);
            // Returning Reply to caller
            return new DataTO(dto.number * 5, dto.string + ":FromMainService");
        });
    }
}
```

This is what Mats<sup>3</sup> enables.  
Mats<sup>3</sup> stands for _Message-oriented Asynchronous, Transactional, Staged, Stateless Services!_  
Mats is _Messaging with a call stack!_  
Mats is _Message-Oriented Asynchronous RPC!_