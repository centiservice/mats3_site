---
title: "Documentation"
permalink: /docs/
excerpt: "Overview over Mats3 documentation"
created_at: 2022-12-07T23:45:44
last_modified_at: 2022-12-13T23:14:35
toc: true
---

Mats documentation is continuously evolving. There should be enough to get you going. What I do hope will trickle in bit
by bit, is tips, tricks and techniques from experience gained after using Mats and message-based communications for
close to a decade in a substantial financial system.

### JavaDoc

Mats have pretty extensive [JavaDoc](/javadoc/), so when you need something from the API, that's where you want to go.

### Documentation @ mats3.io

Step through the navigation pane to the left (desktop) or click _"Toogle Menu"_ at top (mobile)!
[Start here!](/docs/message-oriented-rpc/)
This is meant to be a guided introduction to what Mats is, and the basics of using it.

### Documentation @ Mats<sup>3</sup> repo

This is currently where most of the prose documentation resides. First, you should read the
repo [README.md](https://github.com/centiservice/mats3#readme). After that, there are a few documents in
the [docs folder](https://github.com/centiservice/mats3/tree/main/docs#readme) of the repo. A fairly substantial 
document worth fetching a cup of coffee for is [Endpoints and Initiations](https://github.com/centiservice/mats3/blob/main/docs/developing/EndpointsAndInitiations.md). Well, make that a coffee pot, actually.

### Tests & Code @ Mats<sup>3</sup> repo

Many of the unit tests are instructive, so you can head over to the tests of
[API](https://github.com/centiservice/mats3/tree/main/mats-api-test/src/test/java/io/mats3/api_test),
[Spring](https://github.com/centiservice/mats3/tree/main/mats-spring/src/test/java/io/mats3/spring),
[MatsFuturizer](https://github.com/centiservice/mats3/tree/main/mats-util/src/test/java/io/mats3/util/futurizer),
and tests of the testing tools for
[JUnit](https://github.com/centiservice/mats3/tree/main/mats-test-junit/src/test/java/io/mats3/test/junit) /
[Jupiter](https://github.com/centiservice/mats3/tree/main/mats-test-jupiter/src/test/java/io/mats3/test/jupiter) /
[Spring](https://github.com/centiservice/mats3/tree/main/mats-spring-test/src/test/java/io/mats3/spring/test).
There's also a rudimentary "dev area" with a _TestJettyServer_ for the Metrics Interceptor
[MatsMetrics](https://github.com/centiservice/mats3/tree/main/mats-intercept-micrometer/src/test/java/io/mats3/test/metrics/MatsMetrics_TestJettyServer.java),
and same for Local Introspector [LocalHtmlInspect](https://github.com/centiservice/mats3/tree/main/mats-localinspect/src/test/java/io/mats3/localinspect/LocalHtmlInspect_TestJettyServer.java),
both of which you may start from your IDE - check out chapter [Explore Mats<sup>3</sup>](/docs/explore/)!

### Reach out!

Feel free to contact me if you wonder about anything! _(It would make sense to first having skimmed through the
provided documentation!)_

Any suggestions wrt. the documentation is highly appreciated.

