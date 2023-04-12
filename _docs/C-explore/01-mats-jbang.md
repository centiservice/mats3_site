---
title: "JBang! and Mats3"
permalink: /explore/mats-jbang/
excerpt: "JBang can help in understanding Mats3, and small helper 'MatsJbangKit' has been made to strip away boilerplate."
created_at: 2023-04-11T22:05
last_modified_at: 2023-04-11T22:05
classes: wide
---

[JBang](https://jbang.dev/)'s tagline is: *"Lets Students, Educators and Professional Developers create, edit and run
self-contained source-only Java programs with unprecedented ease."*

We'll first introduce JBang, and explain how to install it. We'll then take up an ActiveMQ instance using a very small
JBang script. Next we'll take up a simple single-stage Mats Endpoint, and finally invoke this endpoint a single time,
using a demonstration-only main-class.

## What's *JBang* and how to install

If you've used Groovy, you might know of the 'Grapes' concept, whereby you in a single Java source file can include
`@Grab` annotations and `Grape.grab(..)` method calls which can pull in dependencies and make them available to the
subsequent code. Also, Groovy can directly invoke a source code file, like a script executor.

Java 11 introduced the ability to invoke a single Java source file directly via the `java` command. It also
supports "shebang" notation, where you put the command to run on the first line of the file, like 
`#!/bin/java --source 11`. However, it did nothing with dependencies, like with Groovy's Grapes, thus severely limiting
its usefulness.

In comes JBang! By running a Java source file using the `jbang` command, you can run it directly, and with special
comment notation, you can specify which Java version to run with (downloading it if not present), and what dependencies
to download. It also supports shebang, albeit with "//" as the first letters - which several unix shells supports. Jbang
can also run files directly from the internet, and also have a *jbang-catalog* feature where you indirectly can point to
a file - more on this later.  

> *Security note:* By using these scripts, and in particular the jbang-catalog commands, you implicitly trust the
> author completely. Jbang will point this out when you invoke files directly from the internet, but since the scripts 
> presented here invokes random classes from the Mats3 libraries, this also requires a severe level of trust: There
> could be `System.exec("format C:\")` or worse inside these classes. You can not even trust it after having
> read the source on github, as the libraries uploaded to Maven Central could contain something completely different.
> 
> To avoid this problem, you could run this stuff inside a container. In that case, note that since the entire point
> of the following exercises is networking, the easiest way would be to use a single container, which you run multiple
> shells inside. Start a detached container (mapping out a bunch of ports so that you can access ActiveMQ and HTTP
> servers inside) `docker run -tdp 0.0.0.0:8000-8200:8000-8200 -p61616:61616 ubuntu`, and then start multiple
> shells inside the same container: `docker exec -it <container_id> bash` (the container-id is shown when making the
> detached container, and also with `docker ps`). To use the JBang curl installation below, you must first get hold of
> curl: `apt-get update; apt-get install curl nano -y` - nano/pico is nice to have for editing these scripts.

To install JBang, go to its site: [https://jbang.dev/download/](https://jbang.dev/download/). Short form for Linux, the
container described above, and Mac: `curl -Ls https://sh.jbang.dev | bash -s - app setup` or, if you have *SDKMan*
already installed: `sdk install jbang` - for Mac there's also Homebrew. There's also multiple solutions for Windows,
including PS, Chocolatey and Scoop.

## Run ActiveMQ

To use JBang to set up your environment for Mats3, you can start by creating a JBang script that sets up an instance of
ActiveMQ. Put the following in a file `ActiveMqMinimal.java`:

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

Then either `chmod 755 ActiveMqMinimal.java` and then run it: `./ActiveMqMinimal.java` - or run it via jbang:
`jbang ActiveMqMinimal.java` (the latter is needed if you want to supply system arguments to Java, e.g. `-Dwarn` to
turn down the log level)

This sets up a ActiveMQ instance. It is "Mats3 optimized" in that it configures certain features, but Mats3 works fully
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
its internal file log database KahaDB to store persistent messages so that such messages survives a broker restart.

## Run a minimal Mats single-stage Endpoint

Once you have the ActiveMQ running (which will be a prerequisite for all other exercises!), you can make a new script
in a new terminal/shell. Put this in a file `SimpleServiceMinimal.java`:

```java
//usr/bin/env jbang "$0" "$@" ; exit $?
//JAVA 17
//DEPS io.mats3.examples:mats-jbangkit:RC1-1.0.0

import io.mats3.examples.jbang.MatsJbangKit;

public class SimpleServiceMinimal {
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

If you started the jbang-catalog ActiveMQ, you can go to the webpage http://localhost:8000/ and see that the queue for
endpoint 'SimpleService.simple' has shown up. By clicking on the message count for the single stage, you'll go to the
queue. It is empty now.

**Just to be on the safe side wrt. high availability of that service, start the same file a few more times (in a few
more shells).** When messages are sent to its queue, ActiveMQ will round-robin them to the instances.