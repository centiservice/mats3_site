---
title: "Intercept API"
permalink: /docs/interception/
excerpt: "Mats Intercept API enables hooking of Flow initiations and processing."
created_date: 2022-12-08T00:10:22
last_modified_at: 2022-12-10T12:46:18
classes: wide
---

The Mats Intercept API allows tooling to intercept all initiation and stage
processing, and which have a ton of metadata about such processing, in particular timings.

The JMS Mats implementation implements this API, in addition to the Mats API itself.

Logging (over SLF4J) and Metrics gathering (using Micrometer) is implemented as plugins to Mats using this API.

## Intercept API

You get detailed information about each stage's processing, and how much time went into receiving and destructuring
the message, decompressing it (if compressed), performing the transactional demarcation, invoking the "user lambda", 
sending message, and committing.

You may also add and remove messages, and even intercept the entire user lambda invocation.

## Logging

Good JavaDoc [here](http://localhost:4000/javadoc/mats3/0.19/modern/io/mats3/intercept/logging/MatsMetricsLoggingInterceptor.html).

### Initiation

Outputs one logline per completed initiation, and per sent message. If there is only one outgoing message, the "
complete" and "message sent" log lines are combined.

### Stage Processing

Outputs one logline for receiving a message, and then one when the message is finished processing, as well as one
logline per sent message. If there is only one outgoing message, the "complete" and "message sent" log lines are
combined.


## Metrics

Some JavaDoc [here](http://localhost:4000/javadoc/mats3/0.19/modern/io/mats3/intercept/micrometer/MatsMicrometerInterceptor.html)

Metrics are gathered for a subset of the available datapoints.

You may for example expose these using a Prometheus exposition plugin for Micrometer. 