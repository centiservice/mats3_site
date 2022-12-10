---
title: "Sync-Async bridge"
permalink: /docs/sync-async-bridge/
excerpt: "MatsFuturizer provides a tool for invoking a Mats Endpoint from a synchronous context"
created_date: 2022-12-07T23:41:35
last_modified_at: 2022-12-10T12:46:58
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

It would be tedious to code up all this each time you need it, taking into account timeouts, collection garbage from
never-returning replies (flows that have DLQed), and a few other tidbits, so there's a tool for it: The `MatsFuturizer`.

It's pretty simple to use: You provide the parameters for an initiation, and then get a `Future` in return. This Future
will be completed once the invoked Mats Endpoint replies.

Here's an example:

```java
public class Test_MatsFuturizer_Basics {
    @ClassRule
    public static final Rule_Mats MATS = Rule_Mats.create();

    @BeforeClass
    public static void setupEndpoint() {
        MATS.getMatsFactory().single("Test.endpoint", TestReply.class, TestRequest.class,
                (context, msg) -> new TestReply(msg.number * 2, msg.string + ":FromService"));
    }

    @Test
    public void futurizeTest() {
        // Get the futurizer - the Rule_Mats already have one created for us:
        MatsFuturizer futurizer = MATS.getMatsFuturizer();

        TestRequestDto request = new TestRequestDto(42, "TheAnswer");

        // Futurization!
        CompletableFuture<Reply<TestReplyDto>> future = futurizer.futurizeNonessential(
                "traceId", "initiatorId", "Test.endpoint", TestReplyDto.class, dto);

        // Immediately wait for result:
        Reply<TestReplyDto> result = future.get(30, TimeUnit.SECONDS);
       
        Assert.assertEquals(new TestReplyDto(dto.number * 2, dto.string + ":FromService"), result.reply);
    }
}
```
_Unit test [here](https://github.com/centiservice/mats3/blob/main/mats-util/src/test/java/io/mats3/util/futurizer/Test_MatsFuturizer_Basics.java)._

Top notch. But you're in a Spring setting, and using programmatic Java to configure Mats Endpoints feels a bit last
century. Annotations rocks! [next chapter](/docs/springconfig/)