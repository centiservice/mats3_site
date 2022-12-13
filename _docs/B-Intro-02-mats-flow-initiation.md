---
title: "Initiation"
permalink: /docs/mats-flow-initiation/
excerpt: "How to initiate Mats Flows"
created_at: 2022-12-10T00:01:36
last_modified_at: 2022-12-13T20:12:15
classes: wide
---


So, in the [previous chapter](/docs/message-oriented-rpc) we saw how an Endpoint could be constructed. However, an Endpoint
picks up messages that arrives on its incoming queue. Granted, other endpoints might put messages there, but this is
turtles all the way down: Someone has got to _start_ these _Mats Flows_.

## MatsInitiator

So we need a way, from the "outside" of the Mats Fabric, to put a message on the incoming queue of a Mats Endpoint. This
is called initiation, and you need a `MatsInitiator` to produce and send such initiation messages. A `MatsInitiator` is
gotten from the `MatsFactory`, the typical way is using the method `getDefaultInitiator()`. This is a thread-safe
entity, and you are not supposed to get an initiator for every new message you send - you get it, and keep it around,
using it for all your initiation needs, from multiple threads. In a Spring context, you'd stick it in the context and
inject it where you need it.

### Send

The following is a "fire and forget"-style `send(..)` initiation, which just sends a message to a Mats Endpoint, thereby
initiating a Mats Flow. Whether this is dozen-stage endpoint, or a single stage Terminator, is of no concern to the
initiator.

```java
matsInitiator.initiate((init) -> init
        .traceId("SomeTraceId_mandatory")
        .from("Example.exampleSend") // "initiatorId"
        .to("Some.endpoint")
        .send(message));
```
_Example of a fire-and-forget test [here](https://github.com/centiservice/mats3/blob/main/mats-api-test/src/test/java/io/mats3/api_test/basics/Test_SimplestSendReceive.java)._

So, to initiate a Mats Flow, you need to get hold of a `MatsInitiator`, and must specify:

* TraceId for the new flow. This should be a unique and descriptive String for this Mats Flow.
* The InitiatorId of this flow, i.e. where this Mats Flow was initiated. It represents the "0th Call" of the Flow.
* Which Mats EndpointId it targets.
* What operation you want, `send(..)`, and the message to the endpoint.

Specifying good TraceIds and InitiatorIds will help immensely when debugging, and wrt. metrics - there's a document
about this [here](https://github.com/centiservice/mats3/blob/main/docs/developing/TraceIdsAndInitiatorIds.md).

The InitiateLambda is executed within a transaction. While the typical initiation is a single Mats Flow
(one outgoing message), you may initiate as many as you want.

The resulting Mats Flow will terminate when no new Flow messages are produced - or if the endpoint targeted by the
fire-and-forget send-invocation performs a Reply, as there is no one to Reply to. The latter is analogous to invoking a
Java method which return something, but where you do not take its return. For example `map.put(key, value)` returns the
previous value at the key position, but often you do not care about this.

### Request

If you in the initiation want a reply from the Mats Flow, you employ a `request(..)` initiation, where you specify a
`replyTo` endpoint. Such a reply-target Endpoint is called a Terminator, as it will receive the final Reply, and then
eventually must terminate the Mats Flow since there is no one to Reply to. It is typically a single-stage endpoint, but
this is not a requirement. You can supply a state object in the initiation, which will be present on the Terminator.

Illustrating a request with a unit test: The test sets up a single-stage Endpoint which we will request. It also sets up
a Terminator which should get the Reply from the Endpoint. Then an initiation is performed, requesting the single-stage
Endpoint, specifying the Terminator as replyTo.

```java
public class Test_SimplestEndpointRequest {
    @ClassRule
    public static final Rule_Mats MATS = Rule_Mats.create();

    @BeforeClass
    public static void setupEndpointAndTerminator() {
        // This service is very simple, where it just returns with an alteration of what it gets input.
        MATS.getMatsFactory().single("Test.endpoint", ServiceReply.class, ServiceRequest.class,
                (context, dto) -> {
                    // Calculate the resulting values
                    double resultNumber = dto.number * 2;
                    String resultString = dto.string + ":FromService";
                    // Return the reply DTO
                    return new ServiceReply(resultNumber, resultString);
                });

        // A "Terminator" is a service which does not reply, i.e. it "consumes" any incoming messages.
        // However, in this test, it resolves the test-latch, so that the main test thread can assert.
        MATS.getMatsFactory().terminator("Test.terminator", StateClass.class, ServiceReply.class,
                (context, sto, dto) -> {
                    MATS.getMatsTestLatch().resolve(sto, dto);
                });
    }

    @Test
    public void doTest() {
        ServiceRequest dto = new ServiceRequest(42, "TheAnswer");
        StateClass sto = new StateClass(420, 420.024);

        // Initiation: Send request to "Test.endpoint", specifying reply to "Test.terminator".
        MATS.getMatsInitiator().initiateUnchecked((init) -> init
                .traceId("SomeTraceId_mandatory")
                .from("Example.exampleRequest")
                .to("Test.endpoint")
                .replyTo("Test.terminator", sto)
                .request(dto));

        // Wait synchronously for terminator to finish. NOTE: Such synchronous wait is not a typical Mats flow!
        Result<StateClass, ServiceReply> result = MATS.getMatsTestLatch().waitForResult();
        Assert.assertEquals(sto, result.getState());
        Assert.assertEquals(new ServiceReply(dto.number * 2, dto.string + ":FromService"), result.getData());
    }
}
```
_Code available [here](https://github.com/centiservice/mats3/blob/main/mats-api-test/src/test/java/io/mats3/api_test/basics/Test_SimplestEndpointRequest.java)._

Compared to the "fire-and-forget" `send(..)` initiation above, this initiation specifies which Terminator should get the
Reply from the invoked Endpoint with the `replyTo(..)` method, which also specifies which state object the Terminator
should receive. A Terminator is an Endpoint which terminates the Mats Flow by not producing any more flow messages. The
initiation then uses the `request(..)` method, supplying the message which the Endpoint should get.

> Do not be misled by the test semantics employed here, using a synchronous coupling between the Terminator and
> the @Test-method, by means of a `MatsTestLatch`. Such a coupling is not a normal way to use Mats, and would in a
> multi-node setup simply not work, as the reply could arrive on a different node. If you need the Reply from the
> invoked Endpoint "in your hand", go to the next chapter.

It is important to understand that there will not be a connection between the initiation-point and the Terminator,
except for the state object. So, if you fire off a request in a HTTP-endpoint, the final Reply will happen on a thread
of the Terminator-endpoint, without any connection back to your initiatiation. Crucially, the Reply might even come on a
different service instance (node/replica) than you initiated the Mats Flow from! This is all well and good in the "new
shipping of widgets arrived" scenario, where you in the Terminator want to set the order status in the database to
"delivered". But it will be a bit problematic when wanting to interactively communicate with the Mats fabric, e.g. from
a web user interface.

So, how can we bridge between a HTTP endpoint's synchronous world, and the utterly asynchronous and distributed
processing of Mats? Go to the [next chapter!](/docs/sync-async-bridge)