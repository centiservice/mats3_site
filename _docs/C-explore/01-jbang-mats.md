---
title: "JBang! and Mats<sup>3</sup>"
permalink: /explore/jbang-mats/
excerpt: "JBang can help in understanding Mats3, and some small helper classes like 'MatsJbangKit' has been made to strip away boilerplate when making JBang scripts."
created_at: 2023-04-11T22:05
last_modified_at: 2023-04-15T13:56
classes: wide
---

[JBang](https://jbang.dev/)'s tagline is: *"Lets Students, Educators and Professional Developers create, edit and run
self-contained source-only Java programs with unprecedented ease."*

[Mats<sup>3</sup>](https://mats3.io/)'s tagline is *"Message-Oriented Async RPC. Message-based Interservice Communication
made easy! Naturally resilient and highly available microservices, with great DevX and OpsX."*

We'll first introduce JBang, and explain how to install it. We'll then take up an *ActiveMQ Message Broker* instance
using a very small JBang script. Next we'll spin up a simple single-stage Mats Endpoint in a new JBang script and a new
shell/console. Finally, we'll invoke this Mats Endpoint, using a demonstration-only main-class, using yet another new
JBang script in yet another new shell. This is meant to demonstrate how Mats<sup>3</sup> is an interesting *Interservice
Communication* tool, and show how the JBang support tools of Mats<sup>3</sup> can make exploration of Mats<sup>3</sup>
dead simple.

## What's *JBang* and how to install

If you've used Groovy, you might know of the 'Grapes' concept, whereby you in a single Java source file can include
`@Grab` annotations and `Grape.grab(..)` method calls which can pull in dependencies and make them available to the
subsequent code. Also, Groovy can directly invoke a source code file, like a script executor.

Java 11 introduced the ability to invoke a single Java source file directly via the `java` command. It also supports 
the unix "shebang" notation, where you put the command to run on the first line of the file, like
`#!/bin/java --source 11`, and can thus invoke the file itself like an executable. However, it did nothing with
dependencies, like with Groovy's Grapes, thus severely limiting its usefulness.

**In comes JBang!** By running a Java source file using the `jbang` command, you can run it directly, and with special
comment notation, you can specify which Java version to run the source with (automatically downloading the version if
not present), and what dependencies to download. It also supports shebang, albeit with "//" as the first letters - which
several unix shells supports. Jbang can also run files directly from the internet, and also have a *jbang-catalog*
feature where you indirectly can point to a file - more on this later.

> *Security note:* By using these scripts, and in particular the jbang-catalog commands, you implicitly trust the
> author completely. Jbang will point this out when you invoke files directly from the internet. However, since even the
> scripts presented here invokes random classes from the Mats3 libraries, this also requires a severe level of trust:
> There could be `System.exec("format C:\")` or worse inside these classes. You can not even trust it after having
> read the source on github, as the libraries uploaded to Maven Central could contain something completely different.
> 
> To avoid this problem, you could run this stuff inside a container. In that case, note that since the entire point
> of the following exercises is networking, the easiest way would be to use a single container, which you run multiple
> shells inside. Start a detached container (mapping out a bunch of ports so that you can access ActiveMQ and HTTP
> servers inside) `docker run -tdp 0.0.0.0:8000-8200:8000-8200 -p61616:61616 ubuntu`, and then start multiple
> shells inside the same container: `docker exec -it <container_id> bash` (the container-id is shown when making the
> detached container, and also with `docker ps`). To use the JBang curl installation below, you must first get hold of
> curl: `apt-get update; apt-get install curl nano git -y` - nano/pico is nice to have for editing these scripts, and
> git is good for cloning down the '[mats3-jbang](https://github.com/centiservice/mats3-jbang)' project.

To install JBang, go to its site: [https://jbang.dev/download/](https://jbang.dev/download/).

Short form for Linux, and the container described above, and Mac:

```shell
curl -Ls https://sh.jbang.dev | bash -s - app setup
```

Alternatively, if you have *SDKMan* already installed: `sdk install jbang`. For Mac there's also Homebrew. There's also
multiple solutions for Windows, including PS, Chocolatey and Scoop.

## Run ActiveMQ

To use JBang to set up your environment for Mats3, you can start by creating a JBang script that starts an instance of
the ActiveMQ Message Broker. Put the following in a file `ActiveMqMinimal.java`:

```java
//usr/bin/env jbang "$0" "$@" ; exit $?
//JAVA 17
//DEPS io.mats3.examples:mats-jbangkit:RC1-1.0.0

import io.mats3.examples.jbang.MatsJbangKit;
import io.mats3.test.broker.MatsTestBroker;
import io.mats3.test.broker.MatsTestBroker.ActiveMq;

public class ActiveMqMinimal {
    public static void main(String[] args) {
        MatsJbangKit.configureLogbackToConsole_Info();
        MatsTestBroker.newActiveMqBroker(ActiveMq.LOCALHOST, ActiveMq.SHUTDOWNHOOK)
                .waitUntilStopped();
    }
}
```

Then either `chmod 755 ActiveMqMinimal.java`, and run it: `./ActiveMqMinimal.java`. Or run it via jbang:
`jbang ActiveMqMinimal.java` (the latter mode is needed if you want to supply system properties to Java, e.g. `-Dwarn`
to turn down the log level)

This fires up an ActiveMQ instance. It is "Mats3 optimized" in that it configures certain features, but Mats3 works fully
on a stock ActiveMQ server too. It has no GUI, just being accessible on standard port 61616. It also doesn't have
persistence, but you can add that by adding `ActiveMQ.PERSISTENT` to the flags.

However, when you have JBang installed, you can use the *jbang-catalog* functionality, and just invoke:

```shell
jbang activemq@centiservice
```

That command will run the file located 
[here on Github](https://github.com/centiservice/mats3-jbang/blob/main/jbang/ActiveMqRun.java), which also
includes a Jetty HTTP server containing the [MatsBrokerMonitor](/docs/matsbrokermonitor/) for introspection of messages
on queues and DLQs, and provide functionality for reissuing DLQed messages. The jbang-catalog used by this notation
resides here: [centiservice/jbang-catalog](https://github.com/centiservice/jbang-catalog/blob/main/jbang-catalog.json).

If you invoke it with `jbang -Dpersistent activemq@centiservice`, you will get a persistent broker, in that it will use
its native file log database KahaDB to store persistent messages so that such messages survives a broker restart.

## Run a minimal Mats single-stage Endpoint

Once you have the ActiveMQ running (which will be a prerequisite for all other exercises!), you can make a new script
in a new terminal/shell. Put this in a file `SimpleService.java`:

```java
//usr/bin/env jbang "$0" "$@" ; exit $?
//JAVA 17
//DEPS io.mats3.examples:mats-jbangkit:RC1-1.0.0

import io.mats3.examples.jbang.MatsJbangKit;

public class SimpleService {
    public static void main(String... args) {
        var matsFactory = MatsJbangKit.createMatsFactory();
        // Create the Mats single-stage Endpoint:
        matsFactory.single("SimpleService.simple",
                SimpleServiceReplyDto.class, SimpleServiceRequestDto.class,
                (processContext, msg) -> {
                    String result = msg.string + ':' + msg.number + ":FromSimple";
                    return new SimpleServiceReplyDto(result, result.length());
                });
    }

    // ----- Contract Request and Reply DTOs
    
    record SimpleServiceRequestDto(int number, String string) {
    }

    record SimpleServiceReplyDto(String result, int numChars) {
    }
}
```

Run it as shown previously. Alternatively, run `jbang SimpleService@centiservice` ([file w/comments](https://github.com/centiservice/mats3-jbang/blob/main/jbang/simple/SimpleService.java)).

Notice the use of the class `MatsJbangKit`, which contains a set of convenience functions to quickly get hold of pieces
needed to make such JBang scripts with minimal boilerplate. Most notably the `MatsFactory` which is needed for all
interaction with Mats3: Making Endpoints, and performing Initiations. The methods are short, but it would nevertheless
be annoying to write these lines for each script file. It makes more sense to focus on the actual Mats interactions,
instead of the code for pulling up the infrastructure.

If you started the jbang-catalog ActiveMQ, you can go to the webpage [http://localhost:8000/](http://localhost:8000/)
and see that the queue for endpoint 'SimpleService.simple' has shown up:

![MatsBrokerMonitor Broker Overview](/assets/images/explore/MatsBrokerMonitor_after_SimpleService.simple_boot_2023-04-13_22-10.png)

By clicking on the message count for the single stage, you'll go to the queue. It is empty now:

![Browing queue of SimpleService.simple](/assets/images/explore/MatsBrokerMonitor_after_SimpleService.simple_boot_queue_2023-04-13_22-13.png)

**Just to be on the safe side wrt. high availability of this service, start the same file a few more times (in a few
more shells).** When messages are sent to its queue, ActiveMQ will round-robin them to the instances.

## Make a "futurized" call to the service

We'll now use the `MatsFuturizer` tool to invoke this service. This is Mats's "sync-async bridge", whereby you may
"call" a Mats Endpoint and get a `CompletableFuture` in return. There is some slight magic involved in how the futurizer
works, which is described in the [Sync-Async Bridge](/docs/sync-async-bridge/) part of the Walkthrough. Essentially, it
creates a new Mats Endpoint (a SubscriptionTerminator) which is node-specific. It then performs a request to the
desired Endpoint, setting the replyTo parameter to target the new receiver Endpoint. It uses a correlation Id to wake up
the correct future when replies come back in.

Shove the following into a file called `SimpleServiceCall.java`:
```java
//usr/bin/env jbang "$0" "$@" ; exit $?
//JAVA 17
//DEPS io.mats3.examples:mats-jbangkit:RC1-1.0.0

import io.mats3.examples.jbang.MatsJbangKit;
import io.mats3.test.MatsTestHelp;
import io.mats3.util.MatsFuturizer;
import io.mats3.util.MatsFuturizer.Reply;

import java.util.concurrent.CompletableFuture;

public class SimpleServiceCall {

    public static void main(String... args) throws Exception {
        MatsFuturizer matsFuturizer = MatsJbangKit.createMatsFuturizer();

        // A "futurization" to the 'SimpleService.simple' MatsEndpoint
        CompletableFuture<Reply<SimpleServiceReplyDto>> future = matsFuturizer.futurizeNonessential(
                MatsTestHelp.traceId(), "SimpleServiceMainFuturization.main.1", "SimpleService.simple",
                SimpleServiceReplyDto.class, new SimpleServiceRequestDto(1, "TestOne"));
        // Sync wait for the reply
        System.out.println("######## Got reply! " + future.get().getReply());

        // Clean up
        matsFuturizer.close();
    }

    // ----- Contract copied from SimpleService

    record SimpleServiceRequestDto(int number, String string) {
    }

    record SimpleServiceReplyDto(String result, int numChars) {
    }
}
```

Run it as shown previously. Alternatively, run `jbang SimpleServiceMainFuturization@centiservice` ([file w/comments](https://github.com/centiservice/mats3-jbang/blob/main/jbang/simple/SimpleService.java)) (note that this 
catalog-variant makes three such calls).

If you want to avoid the logging, to more clearly see the `System.out` reply, you may invoke it using the `-Dwarn`
switch, as such: `jbang -Dwarn SimpleServiceCall.java`, or from the
catalog `jbang -Dwarn SimpleServiceMainFuturization@centiservice`.

If you followed the advice of running more than once instance of `SimpleService.java`, you can run the call a few times,
and witness that the invocations will be processed round-robin by the instances. Note that since the MatsFactory
*concurrency* is set to 2 by the `MatsJbangKit` tool, meaning that there will be two threads consuming from this
particular queue, you will typically have the first two messages processed by instance 1, then the next two by instance
2 etc.

## Experience the magic of queuing

Now, kill all instances of `SimpleService.java` (Ctrl-C), and then run the `SimpleServiceCall.java` again. You will now
obviously not get the log line about a received reply, as there are no consumers of this queue, and thus the
CompletableFuture will just hang waiting for a reply.

However, the message should reside on the queue of `SimpleService.simple`. Let's check the MatsBrokerMonitor:

![Browing queue of SimpleService.simple](/assets/images/explore/MatsBrokerMonitor_after_SimpleService.simple_call_without_service_2023-04-13_23-31.png)

Look at that, a queued message!

Now, lets hit the "view" button:
![Examine message of SimpleService.simple queue](/assets/images/explore/MatsBrokerMonitor_after_SimpleService.simple_call_without_service_messageview_2023-04-13_23-36.png)

As we can see, there's pretty detailed information about the message - you should take a few minutes to read through
what you have at disposal. This is typically the view you will use to examine a message that have been put on the
*Dead Letter Queue* of an Endpoint when the processing failed even after multiple retries.

However, this is not a DLQ. The message just sits there waiting for a consumer, and since there are none, it will just
hang around. Notice that the way we've employed the futurizer, with the `futurizeNonessential(..)` method, the message
will both be non-persistent, and prioritized. The non-persistent part means that even if you've started the broker with
persistence, this message will not survive a broker reboot. Read the 
[JavaDoc of the futurizer](https://mats3.io/javadoc/mats3/0.19/modern/io/mats3/util/MatsFuturizer.html#futurizeNonessential(java.lang.String,java.lang.String,java.lang.String,java.lang.Class,java.lang.Object))
to understand why this makes some sense.

So, let's now start `SimpleService.java` again. You should see that it instantly will process the message, and your
currently blocking `SimpleServiceCall.java` should get the reply it is waiting for - _assuming_ that you were quick
enough to avoid the CompletableFuture's `ExecutionException` caused by the default timeout of 150 seconds. (If not, just
restart the call first, before starting the SimpleService).

## Bonus 1: Make the SimpleService using Mats SpringConfig

Mats3 have a [SpringConfig module](/docs/springconfig), which makes it possible to configure Mats Endpoints using
annotations.

Put the following in `SpringSimpleService.java`:
```java
//usr/bin/env jbang "$0" "$@" ; exit $?
//JAVA 17
//DEPS io.mats3.examples:mats-jbangkit:RC1-1.0.0

import io.mats3.examples.jbang.MatsJbangKit;
import io.mats3.spring.EnableMats;
import io.mats3.spring.MatsMapping;

@EnableMats // Enables Mats3 SpringConfig
public class SpringSimpleService {
    public static void main(String... args) {
        MatsJbangKit.startSpring();
    }

    // A single-stage Endpoint defined using @MatsMapping
    @MatsMapping("SimpleService.simple")
    SimpleServiceReplyDto endpoint(SimpleServiceRequestDto msg) {
        String result = msg.string + ':' + msg.number + ":FromSimple";
        return new SimpleServiceReplyDto(result, result.length());
    }

    // ----- Contract DTOs:

    record SimpleServiceRequestDto(int number, String string) {
    }

    record SimpleServiceReplyDto(String result, int numChars) {
    }
}
```

Run it as shown previously.

The endpoint is identical to the pure-Java variant, just using SpringConfig's `@MatsMapping` which is put on methods.
(There's also `@MatsClassMapping` which is put on classes, for multi-stage endpoints. There's of course an 
[example](https://github.com/centiservice/mats3-jbang/blob/main/jbang/spring/SpringMediumService.java) of
that in the '[mats3-jbang](https://github.com/centiservice/mats3-jbang)' project)

## Bonus 2: Fire up a webserver using MatsFuturizer

A HTTP server using MatsFuturizer - put in a file `SimpleServiceHttpServer.java`:
```java
//usr/bin/env jbang "$0" "$@" ; exit $?
//JAVA 17
//DEPS io.mats3.examples:mats-jbangkit:RC1-1.0.0

import io.mats3.examples.jbang.MatsJbangJettyServer;
import io.mats3.test.MatsTestHelp;
import io.mats3.util.MatsFuturizer;
import io.mats3.util.MatsFuturizer.Reply;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

public class SimpleServiceHttpServer {
    public static void main(String... args) {
        MatsJbangJettyServer.create(8080)
                .addMatsFactory() // Creates a MatsFactory, using appName = calling class.
                .addMatsFuturizer() // Creates a MatsFuturizer, using the ServletContext MatsFactory
                .addMatsLocalInspect() // Includes 'localinspect' local MatsFactory Monitor
                .setRootHtlm("""
                        <html><body>
                        <h1>Basic Servlet MatsFuturizer Example, sync and async, sequentially issued</h1>
                        <h3>LocalHtmlInspectForMatsFactory</h3>
                        <a href="localinspect">Monitoring/introspection GUI for the MatsFactory.</a><p>
                        <h3>Single, simple futurization:</h3>
                        <a href="initiate_simple">Simple sync Servlet handling, single call.</a><p>
                        </body></html>
                        """)
                .start();
    }

    // ----- Simple Servlet doing a single Mats futurization, no timings.

    @WebServlet("/initiate_simple")
    public static class InitiateServlet_Simple extends HttpServlet {
        @Override
        protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
            var matsFuturizer = (MatsFuturizer) req.getServletContext().getAttribute(MatsFuturizer.class.getName());

            // The Futurization
            var replyFuture = matsFuturizer.futurizeNonessential(
                    MatsTestHelp.traceId(), "TestJettyServer", "SimpleService.simple", SimpleServiceReplyDto.class,
                    new SimpleServiceRequestDto(42, "teststring"));

            // Outputting the result
            try {
                Reply<SimpleServiceReplyDto> futureReply = replyFuture.get(30, TimeUnit.SECONDS);
                resp.getWriter().println("Got reply: " + futureReply.getReply());
            }
            catch (InterruptedException | ExecutionException | TimeoutException e) {
                throw new IOException("Couldn't get reply.", e);
            }
        }
    }

    // ----- Contract copied from SimpleService

    record SimpleServiceRequestDto(int number, String string) {
    }

    record SimpleServiceReplyDto(String result, int numChars) {
    }
}
```

Run as shown previously. Alternatively, you can use the cooler catalog-variant which also contains URLs that will
fire off 1000 calls: `jbang SimpleServiceHttpServer@centiservice` ([file w/comments](https://github.com/centiservice/mats3-jbang/blob/main/jbang/simple/SimpleServiceHttpServer.java)).

Hit up [http://localhost:8080/](http://localhost:8080/).

Note that this also starts the 'LocalInspect' tool which lets you introspect the MatsFactory and all its Endpoints, with
rudimentary statistics of invocations etc.

If you start the SimpleService instances, as well as the above webserver, with the `-Dwarn` switch, you will avoid
logging in the console. (At least on my machine, the console is way slower than a file when it comes to output, so the
speed is held back by the actual log output.) Now run a bunch of runs with the 1000 calls URL to warm up the multiple
running JVMs. If you scroll down to the bottom of the browser, you should see some timings there. Remember that this
Servlet is sequentially issuing, transactionally, one and one message to the broker via the MatsFuturizer. Each message
is then processed by an instance of SimpleService, transactionally, and then a new message is sent back.

![Output on browser when running 1000 calls](/assets/images/explore/SimpleService_browser_1000calls-2023-04-14_01-24.png)

## Conclusion

This concludes the Mats3 with JBang introduction! This should hopefully have given a glimmer of understanding of
how Mats3 works, as well as showing that JBang can help when exploring Mats<sup>3</sup>!

The Github project '[mats3-jbang](https://github.com/centiservice/mats3-jbang)' contains all the
above files, as well as several others which demonstrates a tad more advanced elements, including multi-stage endpoints.
It also have the source for `MatsJbangKit` and `MatsJbangJettyServer`, and if you point your Gradle-handling IDE to
the project, you should be able to right-click->Run the different JBang files, as well as easily navigate to the
code that pulls up the infrastructure.

Thanks! If you like this, please give me a star on [Github/centiservice/mats3](https://github.com/centiservice/mats3),
and follow [me](https://twitter.com/stolsvik) and [centiservice](https://twitter.com/centiservice) on Twitter!