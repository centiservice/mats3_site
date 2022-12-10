---
title: "Initiation"
permalink: /docs/mats-flow-initiation/
excerpt: "How to initiate Mats Flows"
created_date: 2022-12-10T00:01:36
last_modified_at: 2022-12-10T00:01:36
classes: wide
---


So, in the [previous chapter](/docs/message-oriented-rpc) we saw how an Endpoint could be constructed. However, an Endpoint
picks up messages that arrives on its incoming queue. Granted, other endpoints might put messages there, but this is
turtles all the way down: Someone got to _start_ such a _Mats Flow_?

## MatsInitiator

There is basically two distinct situations here: Asynchronous/"Batch" initiation, and synchronous/interactive
invocations. However, both of these employ the concept of initiation, that is, starting a Mats Flow from "the outside"
of the Mats fabric.

### Send

The following is a "fire and forget"-style `send(..)` initiation, which just sends a message to a Mats Endpoint, thereby
initiating a Mats Flow. Whether this is dozen-stage endpoint, or a single stage, is of no concern to the initiator.

```java
class Example {
    public void exampleSend(MatsFactory matsFactory, MessageDto message) {
        // Initiation:
        matsFactory.getDefaultInitiator().initiateUnchecked((init) -> init
                .traceId("SomeTraceId_mandatory") // <- Bad TraceId!
                .from("Example.exampleSend")
                .to("Some.endpoint")
                .send(message));
    }
}
```
_Example code for this is [here](https://github.com/centiservice/mats3/blob/main/mats-api-test/src/test/java/io/mats3/api_test/basics/Test_SimplestSendReceive.java)._

So, to initiate a Mats Flow, you need to get hold of a `MatsInitiator`, and must specify:

* TraceId for the new flow. This should be a unique and descriptive String for this Mats Flow.
* The InitiatorId of this flow, i.e. where this Mats Flow was initiated. It represents the "0th Call" of the Flow.
* Which Mats EndpointId it targets.
* What operation you want, `send(..)`, and the message to the endpoint.

Specifying good TraceIds and InitiatorIds will help immensely when debugging, and wrt. metrics - there's a document
about this [here](https://github.com/centiservice/mats3/blob/main/docs/developing/TraceIdsAndInitiatorIds.md).

This Mats Flow will terminate when no new Flow messages are produced - or if the endpoint targeted by the fire-and-forget
send-invocation performs a Reply, as there is no one to Reply to. The latter is analogous to invoking a Java method
which return something, but where you do not take its return. For example `map.put(key, value)` returns the previous
value at the key position, but often you do not care about this.

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
        // Send request to "Service", specifying reply to "Terminator".
        ServiceRequest dto = new ServiceRequest(42, "TheAnswer");
        StateClass sto = new StateClass(420, 420.024);

        // Initiation:
        MATS.getMatsInitiator().initiateUnchecked((init) -> init
                .traceId("SomeTraceId_mandatory") // <- Bad TraceId!
                .from("Test.simplestEndpointRequest")
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

Compared to the "fire-and-forget" `send(..)` initiation above, this initiation specifies which Endpoint should get the
Reply from the invoked Endpoint with the `replyTo(..)`, and what state object that Reply-receiving Endpoint should be
invoked with. It also uses the `request(..)` method, supplying the message which the Endpoint should get.

> Do not be misled by the test semantics employed here, using a synchronous coupling between the Terminator and
> the @Test-method. Such a coupling is not a normal way to use Mats, and would in a multi-node setup simply not work, 
> as the reply could arrive on a different node.

It is important to understand that there will not be a connection between the initiation-point and the terminator,
except for the state object. So, if you fire off a request in a HTTP-endpoint, the final Reply will happen on a thread
of the Terminator-endpoint, without any connection back to your initiatiation. Crucially, the Reply might even come on a
different service instance (node/replica) than you initiated the Mats Flow from! This is all well and good in the "new
shipping of widgets arrived" scenario, where you in the terminator want to set the order status in the database to
"delivered". But it will be a bit problematic when wanting to interactively communicate with the Mats fabric, e.g. from
a web user interface.

So, how can we bridge between a HTTP endpoint's synchronous world, and the utterly asynchronous and distributed
processing of Mats? Go to the [next chapter!](/docs/sync-async-bridge)