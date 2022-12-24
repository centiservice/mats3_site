---
title: "SpringConfig"
permalink: /docs/springconfig/
excerpt: "Mats integrates with Spring, and lets you define Endpoints using annotations"
created_at: 2022-12-10T00:02:00
last_modified_at: 2022-12-13T00:18:00
classes: wide
---

> The Mats API itself has zero dependencies. The JMS Mats implementation depends on the Mats API, JMS API for messaging,
> SLF4J for logging, and MatsTrace for wire protocol. In addition, you need an implementation of JMS (ActiveMQ or
> Artemis client), and an implementation of MatsTrace, the default using Jackson JSON.

Mats is pure Java.

However, if your app is Spring oriented, you might want to define Mats Endpoints using annotations, much like you use
`@RequestMapping` in Spring to define HTTP endpoints.

## @EnableMats

And there is a solution for this. This entails annotating some Spring `@Configuration` class with `@EnableMats`, which
enables annotation scanning for Mats-annotations. The `@MatsMapping` annotation can be added to a method of a Spring
Bean, for creating single-stage and Terminator Endpoints. The `@MatsClassMapping` annotation can be added to a class
to define a multi-stage Endpoint.

## @MatsMapping

Here's an example of `@MatsMapping` to define a single-stage Endpoint:

```java
// Note: MatsFactory must reside in Spring context, and some @Configuration-class
// must have the @EnableMats annotation added.

@Service
class MatsEndpoints {
    
    // possibly inject/autowire stuff here

    @MatsMapping("Service.calculate")
    public ServiceReplyDto springMatsSingleStageEndpoint(ServiceRequestDto msg) {
        // Calculate the resulting values
        double resultNumber = msg.number * 2;
        String resultString = msg.string + ":FromService";
        // Return the reply DTO
        return new ServiceReplyDto(resultNumber, resultString);
    }
}
```

Here's the [@MatsMapping JavaDoc](https://mats3.io/javadoc/mats3/0.19/modern/io/mats3/spring/MatsMapping.html).

## @MatsClassMapping

Here's an example using `@MatsClassMapping` to define a two-stage Endpoint.

_It is a service calculating some shipping cost, giving free shipping if the customer is one of our special customers.
If not, the shipping is rebated if the last year's total value is > 1000, otherwise standard. To find that last year
value, another Mats Endpoint is consulted._

```java
@MatsClassMapping("ShippingService.calculateShipping")
class ShippingEndpointClass {

    // Injected
    private transient ShippingService _shippingService;

    @Autowired
    ShippingEndpointClass(ShippingService shippingService) {
        _shippingService = shippingService;
    }

    // The ProcessContext can be injected, or sent as argument to stage methods
    ProcessContext<ShippingCostReply> _context;

    // This is the state field
    List<OrderLine> _orderLines;

    @Stage(0)
    void initialStage(ShippingCostRequest msg) {
        // Check if this is one of our special customers
        if (_shippingService.isSpecialCustomer(request.customerId)) {
            // Yes, so he always gets free shipping - reply early.
            _context.reply(ShippingCostReply.freeShipping());
            return;
        }

        // Store the values we need in next stage in state-object ('this').
        _orderLines = msg.orderLines;

        // Perform request to the totalValueLastYear Endpoint...
        _context.request("OrderService.orders.totalValueLastYear",
                new OrderTotalValueRequest(customerId));
    }

    @Stage(1)
    ShippingCostReply calculate(OrderTotalValueReply orderTotalValueReply) {
        // Based on OrderService's response, we'll give rebate or not.
        return orderTotalValueReply.getValue() > 1000
                ? _shippingService.rebated(_orderLines)
                : _shippingService.standard(_orderLines);
    }
}
```

So, when defining a multi-stage using annotations, you make the stages as separate methods, annotated with `@Stage` and
an ordinal.

Notice how it uses the class itself for state, while still being able to have Spring Beans injected. This variant also
has the ProcessContext injected, but that can also be passed in with the arguments for the stage methods, simplifying
testing. Depending on your acceptance of "magic", this can be a bit head-twisting, but in actual usage it feels pretty
natural.

It is explained more thoroughly
in [Endpoints and Initiations](https://github.com/centiservice/mats3/blob/main/docs/developing/EndpointsAndInitiations.md),
and the [@MatsClassMapping JavaDoc](https://mats3.io/javadoc/mats3/0.19/modern/io/mats3/spring/MatsClassMapping.html)

So, Mats has an integration with Spring, which is great for developers. But there's more, and this stuff also needs to
run in production! Over to the [next chapter](/docs/devops-happiness/) _(Or go to [explore](/docs/explore)!)_