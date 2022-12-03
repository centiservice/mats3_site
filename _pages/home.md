---
layout: splash
permalink: /
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
  <small>Resilient and highly available services by default, with great DevX and OpsX</small>
feature_row:
  - title: "Message-Oriented RPC"
    excerpt: "Code fully asynchronous message based architecture, but reason like blocking RPC."
    url: "/docs/matsbasics/"
    btn_class: "btn--primary"
    btn_label: "Learn more"
  - title: "Developer happiness"
    excerpt: "Simple code, easy to understand with great introspection, painless debugging."
    url: "/docs/developer/"
    btn_class: "btn--primary"
    btn_label: "Learn more"
  - title: "Logging and metrics"
    excerpt: "Logging (slf4j) and metrics (micrometer) plugins, using Mats Interceptor API."
    url: "/docs/loggingmetrics/"
    btn_class: "btn--primary"
    btn_label: "Learn more"
  - title: "MatsBrokerMonitor"
    excerpt: "Tool for monitoring the message broker, inspect and reissue DLQs."
    url: "/docs/matsbrokermonitor/"
    btn_class: "btn--primary"
    btn_label: "Learn more"
  - title: "Free to use, source on github"
    excerpt: "Noncompete licensed - PolyForm Perimeter."
    url: "/docs/license/"
    btn_class: "btn--primary"
    btn_label: "Learn more"      
---

{% include feature_row %}
