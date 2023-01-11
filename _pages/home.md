---
layout: splash
permalink: /
title: Mats<sup>3</sup>
hidden: true
header:
  overlay_color: "#F75000"
  # overlay_image: /assets/images/mm-home-page-feature.jpg
  actions:
    - label: "<i class='fa fa-book'></i> <b>Docs</b>"
      url: "/docs/"
    - label: "<i class='fab fa-github'></i> GitHub"
      url: "https://github.com/centiservice/mats3"
    - label: "Maven Central"
      url: "https://mvnrepository.com/artifact/io.mats3"
    - label: "<i class='fa fa-arrow-up'></i> Sister project: MatsSocket"
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
  - title: "Sync-Async bridge"
    excerpt: "_MatsFuturizer_ enables a sync setting, like a Servlet, to invoke a Mats Endpoint."
    url: "/docs/sync-async-bridge/"
    btn_class: "btn--primary"
    btn_label: "Learn more"
  - title: "Dev & Ops happiness"
    excerpt: "Simple code, easy to understand with great introspection and painless debugging."
    url: "/docs/devops-happiness/"
    btn_class: "btn--primary"
    btn_label: "Learn more"
  - title: "Intercept API"
    excerpt: "Hooks flow initiation and processing. Plugins for logging (slf4j) and metrics (micrometer)."
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


<figure class="align-left" style="max-width: 450px">
  <img src="assets/images/StandardExampleMatsFlow-halfsize-pagescaled.svg" alt="Standard Example Mats Flow">
  <figcaption>Illustrates a set of Mats Endpoints including a Terminator, as well as the initiator setting off a
  Mats Flow. Code <a href="https://github.com/centiservice/mats3/blob/main/mats-api-test/src/test/java/io/mats3/api_test/stdexampleflow/Test_StandardExampleMatsFlow.java">here</a>.</figcaption>
</figure>

### Message-based Interservice Communication is Great!

Interservice communication using messages has many advantages over traditional HTTP-based systems. Messaging naturally
provides high availability, scalability, fault tolerance, great monitoring, simple error handling, and efficient and
flexible resource management.
{: style="text-align: justify;"}

### Message-based Architectures Can be Complex

Despite these benefits, many developers and architects shy away from message-oriented architectures due to the
challenges of implementing and maintaining them. It requires a shift to asynchronous, multi-staged distributed
processing, where processing flows often span multiple services and codebases, and the result can be difficult to grasp
and manage.
{: style="text-align: justify;"}

In contrast, synchronous protocols, typically over HTTP, offers a sequential and blocking code style that is simpler to
follow and easy to reason about, which is why they're often preferred over messaging.
{: style="text-align: justify;"}

### Mats<sup>3</sup> Solves the Cognitive Load of Messaging!

Mats<sup>3</sup> allows developers to code message-based systems in a way that feels familiar and intuitive, using a
linear, blocking-like programming style. But at the same time, systems using Mats<sup>3</sup> get to enjoy all the
advantages of an asynchronous message-oriented architecture. Mats<sup>3</sup> gives you the best of both
worlds without the cognitive load.
{: style="text-align: justify;"}
