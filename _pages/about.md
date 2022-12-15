---
permalink: /about/
title: "About"
classes: wide
---

Mats<sup>3</sup> is a library that attempts to make message-oriented architectures mimic a synchronous, blocking way of
coding. Read more [here](/docs/message-oriented-rpc/)

# Background

The author has been interested in computer since the Commodore 64 days, and in particular found super computers and
distributed computing fascinating. When growing up and going professional, I began to understand that some systems
additionally requires very high uptime. This introduced a new set of challenges, since failures can spuriously occur on
any level of any stack.

There have been many attempts at handling this, basically taking two routes: Either make the system never fail, or
handle failures. When at university, I got to visit Hewlett-Packard and was shown their
[NonStop](https://en.wikipedia.org/wiki/NonStop_(server_computers)) product line. While fascinating, I could not help
feeling that this is not the answer: It uses specialized hardware, specialized OS and application logic. The cost is ..
high, and thus puts it out of reach for many situations. And it still can't, by itself, handle the massive-explosion
scenario, since the handled failure modes basically are constrained to the single server.

Thus, the better route seemed to make a system that handles failures. Even though this might put more requirements on
the application developer, it is much more generic, can run on commodity hardware, and can, if coded for, handle any
level of failure scenario.

This again requires multiple computers, since a failure mode is that one computer burns to the ground. These multiple
computers needs to communicate to agree on who should do what.

However, when going down into protocols for communication, I basically found that most recommendations, at least most
practice, was using blocking comms, typically over HTTP.

_Service-Oriented Architecture_ became all the rage, using XML and SOAP and WSDL, and even though this supposedly
supported asynchronous modes, even sending messages over SMTP, this was never utilized: Every single application used
HTTP. Then SOA got out of favour due to its complexity. As a tangent, I would argue that it was also due to immaturity
on several levels. The software solutions were clumsy and error prone, and the generated schemas and messages were
hellish to read. But more importantly, "granularity killed SOA": People forgot about the 8 fallacies of distributed
computing. In particular, since it was instance oriented, developers were prone to first do `remoteUser.getFirstname()`,
and then `remoteUser.getLastname()`. The result was pure molasses. And that is just one or two of the fallacies.

Java Enterprise Edition, J2EE, was also cool for a while, where you needed a gazillion interfaces and remote and local
implementations of .. way too much .. to query a single SQL table for the age of your customer. The number of stranded
projects, and wasted millions, on J2EE's conscience must be a heavy burden.

Then, finally, came the saviour: REST. Or "REST". Where bitter wars have be fought over RESTful vs.
whatever-maybe-JSON-over-HTTP. Where the one gang insisted on HATEOAS and links in the JSON and anything else was
utterly meaningless. The other side just wanted some data to go from this system to that system, and JSON's most
important feature was that it was not XML, SOAP and WSDL. _(Or maybe we've just done
REST [wrong all the time?](https://htmx.org/essays/how-did-rest-come-to-mean-the-opposite-of-rest/))_

However, everything was still synchronous and blocking. Which I just could not get my head around.

What I perceive as the primary problem is _state_: The state for in-flight processes is residing in memory, possibly
just on the stack of some blocking thread. To handle errors, where some dependent service goes down midway, you also
need to implement retries, getting another type of problem where you don't really know whether the operation was
executed or not. If a service is hung, and needs to be booted, you might kill off hundreds of midway processes. And if
things starts to lock up, you may lose the overview, and get cascading failures percolating through your entire system.
Where you eventually just have to reboot multiple servers to get things cranking again, and thus immediately terminate
even more in-flight processes. And now you would have to rummage through multiple databases and heaps of logs to find
where each of these stranded, and need extreme insight into the system to get those processes going again, or reset them
and get them to start over.

And then I got to experience this first hand. Me and some colleagues were working on NSB.no, the website of the
Norwegian state's railroad. This is a fairly heavily used site. Our part used four quite beefy frontend servers, with
1000 workers each running PHP, then a backend-for-frontend mid-tier using Java and Jetty. We interfaced to the backend
core system called Lisa. Suddenly one day, NSB.no was down. Turns out that Lisa had started answering _really_ slow.
This led to our mid-tier getting all its Servlet threads blocked. And this again eventually got all workers of Apache to
hang on Jetty. So, even though the frontpage didn't need the mid-tier, the entire site was now down. We poured through
logs, and made a little script to check the usage, basically counting entry-to-exit, and found that all the 4000 workers
of Apache had jammed up in less than 90 seconds from Lisa becoming slow.

While it is possible to handle any such problems that synchronous communication gives, by explicitly program for each
kind of failure, implementing idempotent retries, using external state keeping, sagas, backpressure, circuit breakers
and whatnots, the end result will typically always be that you've pretty much coded up something else entirely.

What I started to realize was that asynchronous messaging, with transactional execution of each stage, would have fixed
most of these problems by its basic nature.

In computer science, message passing vs. invocation has evolved pretty much concurrently. So why isn't everything
involving communication between more than one runtime using messaging, it being superior in every single way?

Well, there is _one_ massive way in which it is not superior at all: The developer's cognitive load.

Invoking a method is what you immediately learn when starting out with programming: You invoke a method which prints
out "Hello, World!" to standard out. Invoking things is absolutely fundamental to programming. Then, after a while, you
realize that organization of code is pretty important too. But not until _way_ later you start thinking about talking
with other computers. And what is then the obvious way? Invoke a _remote_ method: It looks and feels and acts and taxes
your brain exactly the same as invoking a local method. Problem solved, case closed. Messaging is only just briefly, if
at all, considered in passing - this HttpClient here solves it all, and look how simple it is to invoke, even just using
a webbrowser. Nevermind those 8 fallacies.

So, what is the actual problem with messaging? I believe it first and foremost is that the mental model is utterly
different, and on top of this, the existing tooling isn't great.

Mats<sup>3</sup> is an attempt at lowering the cognitive load, and also supply tooling to help the developer. Judging by
how it has been used over multiple years, this attempt is not entirely unsuccessful.

Now, go read some [documentation](/docs/)!