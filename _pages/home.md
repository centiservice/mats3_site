---
layout: splash
permalink: /
title: Mats<sup>3</sup>
hidden: true
header:
  overlay_color: "#F7420A"
  # overlay_image: /assets/images/mm-home-page-feature.jpg
  actions:
    - label: "<i class='fab fa-fw fa-github'></i> Mats3"
      url: "https://github.com/centiservice/mats3"
    - label: "Maven Central"
      url: "https://mvnrepository.com/artifact/io.mats3"
    - label: "Sister project: MatsSocket"
      url: "https://matssocket.io/"
excerpt: >
  Message-based Interservice Communication made easy!<br />
  <small>Naturally resilient and highly available services, with great DevX and OpsX</small>
feature_row:
  - title: "Message-Oriented RPC"
    excerpt: "Code fully asynchronous message-based architectures, but reason like blocking RPC."
    url: "/docs/message-oriented-rpc/"
    btn_class: "btn--primary"
    btn_label: "Learn more"
  - title: "Dev & Ops happiness"
    excerpt: "Simple code, easy to understand with great introspection, painless debugging."
    url: "/docs/devops-happiness/"
    btn_class: "btn--primary"
    btn_label: "Learn more"
  - title: "Sync-Async bridge"
    excerpt: "_MatsFuturizer_ enables a sync setting like a Servlet to invoke a Mats Endpoint"
    url: "/docs/sync-async-bridge/"
    btn_class: "btn--primary"
    btn_label: "Learn more"
  - title: "Intercept API"
    excerpt: "Hook Flow initiation and processing. Plugins for logging (slf4j) and metrics (micrometer)."
    url: "/docs/interception/"
    btn_class: "btn--primary"
    btn_label: "Learn more"
  - title: "MatsBrokerMonitor"
    excerpt: "Tool for monitoring the message broker, inspect messages and reissue DLQs."
    url: "/docs/matsbrokermonitor/"
    btn_class: "btn--primary"
    btn_label: "Learn more"
  - title: "Free to use, source on github"
    excerpt: "Noncompete licensed - PolyForm Perimeter."
    url: "/license/"
    btn_class: "btn--primary"
    btn_label: "Learn more"      
---

{% include feature_row %}


### Message-based interservice communication is superior to HTTP

Multi-service architectures developed using message-oriented asynchronous communication have a number of advantages over
systems developed using blocking HTTP. They naturally provide high availability, scalability, fault tolerance, great
monitoring, simple error handling and debugging. Messages are processed asynchronously and can be prioritized, allowing
for more efficient and flexible use of resources.

<figure class="align-center" style="max-width: 400px">
  <img src="assets/images/StandardExampleMatsFlow-halfsize-pagescaled.svg" alt="Standard Example Mats Flow">
  <figcaption>Illustrates a set of Mats Endpoints including a Terminator, as well as the initiator setting off a
  Mats Flow. Code <a href="https://github.com/centiservice/mats3/blob/main/mats-api-test/src/test/java/io/mats3/api_test/stdexampleflow/Test_StandardExampleMatsFlow.java">here</a>.</figcaption>
</figure>


### Despite many advantages, message-oriented architectures are often shunned

Implementing a message-oriented architecture can be challenging because it requires fully embracing asynchronous,
multi-staged distributed processing and maintaining state throughout the message flows. This can make it difficult to
implement and modify, and make the overall structure of the system hard to grasp.

Protocols like HTTP gives a synchronous and blocking code style that is simple to follow and reason about, and is a main
reason why developers and architects choose these over messaging.

### Mats<sup>3</sup> gives you messaging with a call stack!

Mats<sup>3</sup> is a library that allow developers to code message-based systems in a similar way to using HTTP calls,
and thus feels familiar and intuitive. Mats Endpoints can invoke other Mats Endpoints, and are developed using a linear
and blocking-like code style, while still benefiting from all the advantages of an asynchronous message-oriented
architecture. You get the best from both worlds, without the cognitive load.

