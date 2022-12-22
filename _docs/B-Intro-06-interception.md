---
title: "Intercept API"
permalink: /docs/interception/
excerpt: "Mats Intercept API enables hooking of Flow initiations and processing."
created_at: 2022-12-08T00:10:22
last_modified_at: 15.12.2022T20:37
classes: wide
---

The Mats Intercept API allows tooling to intercept all initiation and stage processing, and have a ton of metadata about
such processing, in particular timings.

The JMS Mats implementation implements this API, in addition to the Mats API itself.

Logging (over SLF4J) and Metrics gathering (using Micrometer) is implemented as plugins to Mats using this API. The
`LocalHtmlInspectForMatsFactory` also has an interceptor that gathers local statistics.

## Features

You get detailed information about each stage's processing, and how much time went into receiving and destructuring
the message, decompressing it (if compressed), performing the transactional demarcation, invoking the "user lambda", 
sending message, and committing.

You may also add and remove messages, and even intercept the entire user lambda invocation.

See JavaDoc [here](/javadoc/mats3/0.19/modern/io/mats3/api/intercept/package-summary.html), in particular the main
interfaces [MatsInitiateInterceptor](/javadoc/mats3/0.19/modern/io/mats3/api/intercept/MatsInitiateInterceptor.html)
and [MatsStageInterceptor](/javadoc/mats3/0.19/modern/io/mats3/api/intercept/MatsStageInterceptor.html).

## Logging

Logging is implemented as an Intercept plugin: Initiations, Message reception, Process complete, and any sent messages,
are logged. Each of the log lines have a rich set of MDC properties set, which, if you've configured your logging system
sanely, will end up as fields. These props are metrics and states, which can both be used to query on, but also used to
make statistics and graphs.

See JavaDoc [here](/javadoc/mats3/0.19/modern/io/mats3/intercept/logging/MatsMetricsLoggingInterceptor.html)

## Metrics

Metrics is also implemented as an Intercept plugin: Several key metrics are kept using Micrometer. You may expose these
as e.g. Prometheus scrape or any other of the dozens metric collector/exposition solutions Micrometer support, it
being "SLF4J for Metrics". From your metrics system, you may then graph out e.g. stage timings, message broker send and
commit times etc.

See JavaDoc [here](/javadoc/mats3/0.19/modern/io/mats3/intercept/micrometer/MatsMicrometerInterceptor.html)
