---
title: "Explore Mats"
permalink: /docs/explore/
excerpt: "How to get your hands dirty with Mats - explore, experiment, investigate, play around"
created_at: 2022-12-24T11:31
last_modified_at: 2022-12-24T11:31
classes: wide
---

For the time being, the simplest ways to explore and experiment with Mats<sup>3</sup> all start with checking out the
repository, and go from there.

> Note: To use Mats in a project, fetch [`mats-impl-jms`](https://mvnrepository.com/artifact/io.mats3/mats-impl-jms)
> from [Maven Central](https://mvnrepository.com/artifact/io.mats3).

So, clone down the repository, and test and build it (you can do that in a container to be on the safer side):
```shell
./gradlew clean test build
```

After this pans out, fire up your IDE and head over to the unit/integration tests of
[API](https://github.com/centiservice/mats3/tree/main/mats-api-test/src/test/java/io/mats3/api_test),
[Spring](https://github.com/centiservice/mats3/tree/main/mats-spring/src/test/java/io/mats3/spring),
[MatsFuturizer](https://github.com/centiservice/mats3/tree/main/mats-util/src/test/java/io/mats3/util/futurizer), 
and tests of the testing tools for
[JUnit](https://github.com/centiservice/mats3/tree/main/mats-test-junit/src/test/java/io/mats3/test/junit) /
[Jupiter](https://github.com/centiservice/mats3/tree/main/mats-test-jupiter/src/test/java/io/mats3/test/jupiter) /
[Spring](https://github.com/centiservice/mats3/tree/main/mats-spring-test/src/test/java/io/mats3/spring/test).

There's also a very rudimentary "dev area" for the Metrics Interceptor
[MatsMetrics_TestJettyServer](https://github.com/centiservice/mats3/tree/main/mats-intercept-micrometer/src/test/java/io/mats3/test/metrics/MatsMetrics_TestJettyServer.java), 
and same for Local Introspector
[LocalHtmlInspect_TestJettyServer](https://github.com/centiservice/mats3/tree/main/mats-localinspect/src/test/java/io/mats3/localinspect/LocalHtmlInspect_TestJettyServer.java), 
both of which you may start from your IDE by Right-click -> debug.

Firing up `LocalHtmlInspect_TestJettyServer`:

![Starting LocalHtmlInspect_TestJettyServer](/assets/images/explore/LocalHtmlInspect_TestJettyServer_in_Intellij-2022-12-24_11-51.png)

Hitting up <a href="http://localhost:8080/">http://localhost:8080/</a>

![Browseing of LocalHtmlInspect](/assets/images/explore/LocalHtmlInspect_browser_2022-12-24_11-56.png)
