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
  <small>Naturally resilient and highly available microservices, with great DevX and OpsX</small>
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

In a Message-oriented microservice architecture, the individual services connects to a _Message Broker_ and subscribes
to _queues_ from which they consume messages. Services also posts messages to these queues, for other services to
consume and handle. The broker acts as an intermediary, a post-office, holding the messages from the producers until a
consumer is ready to take it. The communication between the services is asynchronous: One service posting a message, and
another service consuming a message, are separate operations, not blocking on each other.
{: style="text-align: justify;"}

Interservice communication using messages has many advantages over traditional synchronous HTTP-based systems. Messaging
naturally provides high availability, scalability, location transparency, prioritization, processing transactionality,
fault tolerance, great monitoring, simple error handling, and efficient and flexible resource management.
{: style="text-align: justify;"}

### Message-based Architectures Can be Complex

Despite many benefits, developers and architects seems to shy away from message-oriented architectures due to the
challenges of implementing and maintaining them. It requires a large mental shift to asynchronous, multi-staged
distributed processing, where processing flows often span multiple services and codebases, and the result can be
difficult to grasp and manage.
{: style="text-align: justify;"}

### Mats<sup>3</sup> Solves the Cognitive Load of Messaging!

Mats<sup>3</sup> allows developers to code message-based systems in a way that feels familiar and intuitive, by
providing a programming model that _appears_ to be sequential and synchronous. However, under the hood, each step of a
Mats Endpoint is actually a separate and autonomous consumer, processor and producer of messages. Systems using
Mats<sup>3</sup> get to enjoy all the advantages of an asynchronous, transactional and message-oriented architecture,
while feeling as simple as if using HTTP - giving you the best of both worlds without the cognitive load!
{: style="text-align: justify;"}
