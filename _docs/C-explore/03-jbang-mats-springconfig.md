---
title: "JBang - Mats SpringConfig"
permalink: /explore/jbang-mats-springconfig/
excerpt: "JBang used to demonstrate Mats SpringConfig: @EnableMats to process @MatsMapping and @MatsClassMapping annotations"
created_at: 2023-04-15T13:56
last_modified_at: 2023-04-15T13:56
classes: wide
---

This article will present a JBang example of how Mats<sup>3</sup> SpringConfig works. Mats' Spring integration
primarily revolves around the three annotations `@EnableMats` to start bean scanning for Mats Endpoints, and the 
method annotation `@MatsMapping` to define a single-stage Mats Endpoint, and the class annotation `@MatsClassMapping`
to define multi-stage Mats Endpoints.

**NOTE: You should definitely first read and preferably do the exercises in [JBang! and Mats<sup>3</sup>](/explore/jbang-mats/)
to understand how JBang works, and how Mats<sup>3</sup> can be used with it.**

Inside that article, there is also a small example of using @EnableMats with a single-stage @MatsMapping Endpoint.

Mats<sup>3</sup> SpringConfig is explained more thoroughly in the Walkthrough's [SpringConfig](/docs/springconfig/), and
further links from there. Here we'll just show and explain a tad larger example with JBang.

## SpringConfig example with everything!

**NOTE: You obviously need an ActiveMQ Message Broker instance running for these examples too. If you do not have it
running already, run `jbang activemq@centiservice`.** 

The following file is a hodgepodge of Spring `@Configuration`, `@Bean`, `@Service` and `@Autowired` to bring up some
Spring beans which is then injected, and the three main Mats SpringConfig annotations `@EnableMats`, `@MatsMapping` and
`@MatsClassMapping`.

It defines two Java service beans, one doing multiplication, and the other exponentiation. The first is injected so that
a single-stage *private* `@MatsMapping` Endpoint can use it, while the second is injected so that the
multi-stage `@MatsClassMapping` Endpoint can use it. The multi-stage Endpoints employs the private single-stage Endpoint
via a Request.

The code and services are of course rather "synthetic" in that it is an absurd, complicated and extremely inefficient
way to accomplish the actual operation, but it is just meant as an illustration.

Put the following in a file `SpringMediumService.java`:

```java
//usr/bin/env jbang "$0" "$@" ; exit $?
//JAVA 17
//DEPS io.mats3.examples:mats-jbangkit:RC1-1.0.0

package spring;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.stereotype.Service;

import io.mats3.MatsEndpoint.ProcessContext;
import io.mats3.MatsFactory;
import io.mats3.examples.jbang.MatsJbangKit;
import io.mats3.spring.EnableMats;
import io.mats3.spring.MatsClassMapping;
import io.mats3.spring.MatsClassMapping.Stage;
import io.mats3.spring.MatsMapping;

/** Demonstrates Mats3' SpringConfig with @MatsMapping and @MatsClassMapping. */
@EnableMats // Enables Mats3 SpringConfig
@Configuration // Ensures that Spring processes inner classes, components, beans and configs
public class SpringMediumService {
    public static void main(String... args) {
        // One way to do it: Manually create MatsFactory in main, then use this for Spring
        // Could also have made it using a @Bean.
        MatsFactory matsFactory = MatsJbangKit.createMatsFactory();
        // Manually fire up Spring
        AnnotationConfigApplicationContext ctx = new AnnotationConfigApplicationContext();
        ctx.registerBean(MatsFactory.class, () -> matsFactory);
        ctx.register(SpringMediumService.class);
        ctx.refresh();
        // Note: SpringSimpleService instead uses a single-line MatsExampleKit to start Spring.
    }

    private static final String PRIVATE_ENDPOINT = "SpringMediumService.private.matsMapping";

    // A minimal Java "MultiplierService", defined as a Spring @Service.
    @Service
    static class MultiplierService {
        double multiply(double multiplicand, double multiplier) {
            return multiplicand * multiplier;
        }
    }

    // Inject the minimal Java MultiplierService, for use by the single-stage Mats Endpoint below.
    @Autowired
    private MultiplierService _multiplierService;

    // A single-stage Mats Endpoint defined using @MatsMapping
    @MatsMapping(PRIVATE_ENDPOINT)
    PrivateReplyDto endpoint(PrivateRequestDto msg) {
        return new PrivateReplyDto(_multiplierService.multiply(msg.multiplicand, msg.multiplier));
    }
    
    // An interface for an "ExponentiationService", which is required by the @MatsClassMapping below,
    // and provided by a @Bean in the @Configuration class below.
    interface ExponentiationService {
        double exponentiate(double base, double exponent);
    }

    @Configuration
    static class ConfigurationForMediumService {
        // Create an instance of the ExponentiationService interface
        @Bean
        public ExponentiationService exponentiationService() {
            return new ExponentiationService() {
                @Override
                public double exponentiate(double base, double exponent) {
                    return Math.pow(base, exponent);
                }
            };
        }
    }

    // A multi-stage Endpoint defined using @MatsClassMapping
    @MatsClassMapping("SpringMediumService.matsClassMapping")
    static class SpringService_MatsClassMapping_Leaf {

        // Autowired/Injected Spring Bean: the ExponentiationService defined above
        // (Constructor injection is of course possible)
        @Autowired
        private transient ExponentiationService _exponentiationService;

        // ProcessContext is injected, but can also be provided as argument, simplifying testing.
        private ProcessContext<SpringMediumServiceReplyDto> _context;

        // This is a state field, since it is not the other two types, and not static.
        private double _exponent;

        @Stage(Stage.INITIAL)
        void receiveEndpointMessageAndRequestMultiplication(SpringMediumServiceRequestDto msg) {
            _exponent = msg.exponent;
            _context.request(PRIVATE_ENDPOINT, new PrivateRequestDto(msg.multiplicand, msg.multiplier));
        }

        @Stage(10)
        SpringMediumServiceReplyDto exponentiateResult(PrivateReplyDto msg) {
            double result = _exponentiationService.exponentiate(msg.result, _exponent);
            return new SpringMediumServiceReplyDto(result);
        }
    }

    // ----- Private Endpoint DTOs

    record PrivateRequestDto(double multiplicand, double multiplier) {
    }

    record PrivateReplyDto(double result) {
    }


    // ----- Contract DTOs:

    record SpringMediumServiceRequestDto(double multiplicand, double multiplier, double exponent) {
    }

    record SpringMediumServiceReplyDto(double result) {
    }
}
```

Then either `chmod 755 SpringMediumService.java`, and run it: `./SpringMediumService.java`.
Or run it via jbang: `jbang SpringMediumService.java`. Alternatively, run the catalog-variant 
`jbang SpringMediumService@centiservice` ([file w/comments](https://github.com/centiservice/mats3-jbang/blob/main/jbang/spring/SpringMediumService.java))


## Invoke the multi-stage service

"Calling" this service's Mats Endpoint is identical to calling the single-stage "SimpleService" from the
introduction [JBang! and Mats<sup>3</sup>](/explore/jbang-mats/): There is no difference seen from the calling side
whether the requested Mats Endpoint is a single-stage Endpoint, or a dozen-stage Endpoint which again invokes a whole
graph of required services. Just as with an ordinary method call: You call the method. Whether the method sums two
numbers and returns, or makes a dozen network calls and calculates the Mandelbrot set, this makes no difference to how
you invoke it. (The time taken to reply might of course vary wildly between one case or the other, though.)

Notice that we don't use anything Spring-related here. Mats<sup>3</sup> SpringConfig mainly revolves around setting up
Endpoints, while Initiation and thus MatsFuturization are just Java method calls. You will of course typically put the
MatsFactory and MatsFuturizer in the Spring Context.

Stuff the following into `SpringMediumServiceCall.java`:

```java
//usr/bin/env jbang "$0" "$@" ; exit $?
//JAVA 17
//DEPS io.mats3.examples:mats-jbangkit:RC1-1.0.0

package spring;

import io.mats3.examples.jbang.MatsJbangKit;
import io.mats3.test.MatsTestHelp;
import io.mats3.util.MatsFuturizer;
import io.mats3.util.MatsFuturizer.Reply;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ThreadLocalRandom;

public class SpringMediumServiceCall {
    public static void main(String... args) throws Exception {
        MatsFuturizer matsFuturizer = MatsJbangKit.createMatsFuturizer();

        double random = ThreadLocalRandom.current().nextDouble(-10, 10);

        // ----- A single call
        CompletableFuture<Reply<SpringMediumServiceReplyDto>> future = matsFuturizer.futurizeNonessential(
                MatsTestHelp.traceId(), "SpringMediumServiceCall.main",
                "SpringMediumService.matsClassMapping", SpringMediumServiceReplyDto.class,
                new SpringMediumServiceRequestDto(Math.PI, Math.E, random));

        // :: Receive, verify and print.
        SpringMediumServiceReplyDto reply = future.get().getReply();
        boolean correct = Math.pow(Math.PI * Math.E, random) == reply.result;
        System.out.println("######## Got reply! " + reply + " - " + (correct ? "Correct!" : "Wrong!"));

        // Clean up
        matsFuturizer.close();
    }

    // ----- Contract copied from SpringMediumService

    record SpringMediumServiceRequestDto(double multiplicand, double multiplier, double exponent) {
    }

    record SpringMediumServiceReplyDto(double result) {
    }
}
```
Invoke it as shown previously. Alternatively, run the catalog-variant
`jbang SpringMediumServiceMainFuturization@centiservice` ([file w/comments](https://github.com/centiservice/mats3-jbang/blob/main/jbang/spring/SpringMediumServiceMainFuturization.java))

The service we created previously needs to be running while invoking the script. Or at least make it run within the
default timeout for the MatsFuturizer of 150 seconds. Actually, it is quite cool to see how this caller doesn't care one
bit that the service isn't running when you start the call: Once it has put the message on the target service's Endpoint
queue, it doesn't know or care whether it takes 1 ms, or 2 minutes, to get the reply.

_(This is a sync setting, and there are typically timeouts involved on the "edges" of the Mats Fabric. When running
system-internal processes, a delay of days wouldn't matter (except due to business requirements): You could take down
the entire system from AWS, and set it back up in Azure, and once you again fire up the different services and the
message broker, all 'Mats Flows' would just start up again from wherever they stopped.)_

## Invoke using a Spring Service

Okay, okay, since you really want to see initiation "done with Spring", here you go!

Put this inside `SpringMediumServiceSpringCall.java`:

```java
//usr/bin/env jbang "$0" "$@" ; exit $?
//JAVA 17
//DEPS io.mats3.examples:mats-jbangkit:RC1-1.0.0

package spring;

import io.mats3.examples.jbang.MatsJbangKit;
import io.mats3.spring.EnableMats;
import io.mats3.test.MatsTestHelp;
import io.mats3.util.MatsFuturizer;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.stereotype.Service;

import java.util.concurrent.ExecutionException;

@EnableMats // Enables Mats3 SpringConfig
@Configuration // Ensures that Spring processes inner classes, components, beans and configs
public class SpringMediumServiceSpringCall {

    public static void main(String... args) {
        var springContext = MatsJbangKit.startSpring();
        // Fetch the Spring service bean from the Spring Context
        var client = springContext.getBean(SpringMediumServiceClient.class);
        // Invoke it. (Note: This should never be done inside a Mats Stage!)
        double result = client.multiplyAndExponentiate(5, 6, Math.PI);
        // Dump the Spring Context, taking down everything.
        springContext.close();

        // Verify and output
        boolean correct = Math.pow(5 * 6, Math.PI) == result;
        System.out.println("######## Got reply! " + result + " - " + (correct ? "Correct!" : "Wrong!"));
    }

    @Service
    static class SpringMediumServiceClient {
        @Autowired
        private MatsFuturizer _matsFuturizer;

        double multiplyAndExponentiate(double multiplicand, double multiplier, double exponent) {
            var future = _matsFuturizer.futurizeNonessential(MatsTestHelp.traceId(), 
                    "SpringMediumServiceClient.client", "SpringMediumService.matsClassMapping",
                    SpringMediumServiceReplyDto.class, 
                    new SpringMediumServiceRequestDto(multiplicand, multiplier, exponent));
            try {
                return future.get().getReply().result();
            }
            catch (InterruptedException | ExecutionException e) {
                throw new RuntimeException("Couldn't get result from Service.", e);
            }
        }
    }

    // ----- Contract copied from SpringMediumService

    record SpringMediumServiceRequestDto(double multiplicand, double multiplier, double exponent) {
    }

    record SpringMediumServiceReplyDto(double result) {
    }
}
```
Invoke it as shown previously. Alternatively, run the catalog-variant
`jbang SpringMediumServiceSpringFuturization@centiservice` ([file w/comments](https://github.com/centiservice/mats3-jbang/blob/main/jbang/spring/SpringMediumServiceSpringFuturization.java))

This creates a Spring service bean which autowires/injects the MatsFuturizer. A service method employs the MatsFuturizer
like previously. From the main class, we fetch this bean from the Spring context, and invoke the service method. A more
relevant setup would be a Servlet Container, in which case you'd probably inject it into a class with 
`@RequestMapping`-annotated methods on it.

While making such clients might seem very tempting, as it resembles how you'd make clients when using REST endpoints for
inter-service communications, it has a couple of pitfalls. Most notably, it is rather important that you ***do not***
employ a MatsFuturizer, and hence not such a service bean, *from within a Mats Stage*. More about this can be read in the
articles [Composition of Mats Endpoints, 'Client-wrapping' and MatsFuturizer](/using-mats/composition-of-mats-endpoints/)
and [Designing internal Services when using Mats](/using-mats/designing-internal-services/).

## Conclusion

You should now understand a bit of how Mats<sup>3</sup> SpringConfig works. By annotating a `@Configuration`-class with
`@EnableMats`, you enable bean scanning for annotated Mats Endpoints. There are two types: For single-stage Mats
Endpoints, you can use `@MatsMapping` on methods of Spring beans. For multi-stage Mats Endpoints, you can annotate
a class with `@MatsClassMapping`.

The Github project '[mats3-jbang](https://github.com/centiservice/mats3-jbang)' contains all the above files, as well as
several others. It also has the source for `MatsJbangKit` and `MatsJbangJettyServer`, and if you point your
Gradle-handling IDE to the project, you should be able to right-click->Run the different JBang files, as well as easily
navigate to the code that pulls up the infrastructure.

Thanks! If you like this, please give me a star on [Github/centiservice/mats3](https://github.com/centiservice/mats3),
and follow [me](https://twitter.com/stolsvik) and [centiservice](https://twitter.com/centiservice) on Twitter!