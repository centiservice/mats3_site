---
title: "Documentation"
permalink: /docs/
excerpt: "Overview of Mats3 documentation"
created_at: 2022-12-07T23:45:44
last_modified_at: 2022-12-13T23:14:35
classes: wide
---

Mats documentation is continuously evolving. There should be enough to get you going. What I do hope will trickle in bit
by bit, is tips, tricks and techniques from experience gained after using Mats and message-based communications for
close to a decade in a substantial financial system.

### Documentation @ mats3.io

Step through the navigation pane to the left (desktop) or click _"Table of Contents"_ at top (mobile)!
[Start here!](/docs/message-oriented-rpc/)
This is meant to be a guided introduction to what Mats is, and the basics of using it. After that, you should brew a pot
of coffee, and read [Mats Endpoints, Stages and Initiations](../using-mats/endpoints-and-initiations/), and then the
rest of the "Using Mats" section!

### JavaDoc

Mats have pretty extensive [JavaDoc](/javadoc/), so when you need something from the API, that's where you want to go.

### Explore Mats, with JBang!

A bunch of [JBang script files, as well as a small toolkit](/explore/jbang-mats/), is created to demonstrate Mats<sup>
3</sup> in live action. The goal is to make it simple to explore and play around with the library.

### Documentation @ Mats<sup>3</sup> repo

You should read the repo [README.md](https://github.com/centiservice/mats3#readme). Most of the rest of the
documentation is now moved to this site.

### Tests & Code @ Mats<sup>3</sup> repo

Many of the unit tests are instructive, so you can head over to the tests of
[API](https://github.com/centiservice/mats3/tree/main/mats-api-test/src/test/java/io/mats3/api_test),
[Spring](https://github.com/centiservice/mats3/tree/main/mats-spring/src/test/java/io/mats3/spring),
[MatsFuturizer](https://github.com/centiservice/mats3/tree/main/mats-util/src/test/java/io/mats3/util/futurizer), and
tests of the testing tools for
[JUnit](https://github.com/centiservice/mats3/tree/main/mats-test-junit/src/test/java/io/mats3/test/junit) /
[Jupiter](https://github.com/centiservice/mats3/tree/main/mats-test-jupiter/src/test/java/io/mats3/test/jupiter) /
[Spring](https://github.com/centiservice/mats3/tree/main/mats-spring-test/src/test/java/io/mats3/spring/test). There's
also a rudimentary "dev area" with a _TestJettyServer_ for the Metrics Interceptor
[MatsMetrics](https://github.com/centiservice/mats3/tree/main/mats-intercept-micrometer/src/test/java/io/mats3/test/metrics/MatsMetrics_TestJettyServer.java)
, and same for Local
Introspector [LocalHtmlInspect](https://github.com/centiservice/mats3/tree/main/mats-localinspect/src/test/java/io/mats3/localinspect/LocalHtmlInspect_TestJettyServer.java)
, both of which you may start from your IDE - check out
chapter [Mats<sup>3</sup> Source Code](/explore/mats-source-code/)!

### Reach out!

Feel free to contact me if you wonder about anything! _(It would make sense to first having skimmed through the provided
documentation!)_

Any suggestions wrt. the documentation is highly appreciated.

Email: `endre@stolsvik.com`<br>
Twitter: [stolsvik](https://twitter.com/stolsvik), [centiservice](https://twitter.com/centiservice)

If you find the library interesting, a star on [Github/centiservice/mats3](https://github.com/centiservice/mats3) is
very much appreciated.