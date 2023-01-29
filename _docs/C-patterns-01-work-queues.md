---
title: "Work queues when using messaging"
permalink: /patterns/work-queues/
excerpt: "When having many jobs that needs processing, throwing them all on the MQ in one go might not always be what you want."
created_at: 2023-01-11T08:58
last_modified_at: 2023-01-11T08:58
classes: wide
---

> Messaging naturally provides high availability, scalability, location transparency, prioritization, stage
transactionality, fault tolerance, great monitoring, simple error handling, and efficient and flexible resource
management. However, messaging can be much harder to employ in practice due to a fundamentally different programming
model.
>
> <b>Mats<sup>3</sup></b> is a client side Java library that makes asynchronous message-oriented interservice
communications mimic a synchronous, blocking and linear/sequential way of coding, greatly reducing the mental shift and
cognitive load, and increases developer productivity when using messaging. You gain all the positives of messaging,
while virtually eliminating the negatives.

## Scenario

You have a microservice architecture using messaging as interservice communications. You have certain jobs that will
touch multiple services when they are processed. When you suddenly get many such jobs that needs processing, throwing
them all on the MQ in one go might not always be what you want.

## Handling many fulfillable Orders

So, say you have a heap of outstanding, not-fulfilled orders. You then get some new information, possibly incoming
products, which makes a bunch of these orders fulfillable.

Say 10 000 orders became fulfillable at the same time, and you now need to start a process for each of them, where the
processes will consist of multiple stages spanning multiple services.

If you were using HTTP as your interservice communications, you would most probably _not_ fire up 10k threads and do
them all at once. You would rather pick e.g. 10 of them and run these in parallel (or better yet, batch them, but that's
for a later post!). Once these are done, you'd fire up 10 more. Or, you might make a logic where you attempt to keep 10
outstanding, in-progress jobs until the list is done.

The reason for the need for such pacing is that all resources are limited. Trying to perform 10k queries simultaneously
on the different services and the databases they employ, would trash them. It would probably also make the total
processing time even longer than doing them sequentially. In addition, these parts of the system would probably be
effectively unusable for anything else during the time it took to process them, as they were utterly saturated.

When using messaging, it is possible to just throw all 10k jobs on the queue, and then let the MQ handle the pacing of
the messages: You can tune the number of consumers on each stage, so that the external resources like DB didn't
saturate. It is even possible to use the initial stage of such a "handle many orders" processing flow act as an explicit
choke-point: Tune down the concurrency on this first stage, so that the rest of the system got a nice pace of incoming
processes. Assuming that this choke-point processing stage only was used for this mass-fulfill scenario, you could even
throw in a small `Thread.sleep(100+random(100))` there to further lower the pace.

However, if this is a central and important part of your system, there are arguments for still using explicit pacing by
repeatedly enqueueing smaller subsets of the total.

## Problems (and solutions) with large number of jobs on the MQ

Some problems with throwing all 10k jobs on the queue at the same time is that you might tax the total system rather
heavily, and that you loose introspection, monitoring and control of them.

1. <b>Introspection of system, monitoring of jobs</b>: It is harder to get a total understanding of your full set of
   outstanding processes. While e.g. JMS have a `QueueBrowser` concept whereby you can introspect a queue, this is more
   usable as an operations-side introspection tool than as monitoring specific processes.
    * A solution to this is to let the processes at certain points swing back to the orders table and record which stage
      it has finished, and/or which stage it embarks on.
2. <b>Control</b>: Since you already threw all 10k jobs on the queue, you do not easily have a way to stop the
   processing. If there are some problem down the processing flow, e.g. a database that went offline, a logic error wrt.
   system state where effectively all orders will fail, or a newly introduced coding error, you are now in a though
   spot:
   You have already added those 10k jobs to the queue, and they need to run their course. If each job will end up with a
   DLQ, you'll get up to 10k DLQs that needs handling by reissuing or deleting. Also, putting a message on DLQ takes
   time, as the MQ will first try multiple redeliveries before giving up. So you might now have a heap of outstanding
   messages which you know with certainty will all DLQ, but this will take much more time than it would have taken in
   the good case.
    * A solution here could be that you on the initial pacing stage, or the points where the processes report back - the
      solution mentioned in #2 - you could also let the job check a flag of whether the system status was "HALT", or the
      job status was "CANCEL", or somesuch. In these cases, the job would stop its multi-stage processing, record that
      it has accepted cancel and which stage it was in at that time.
3. <b>Heavy load</b>: It might load the system quite hard. While this does point at you not having tuned the concurrency
   of each stage/queue processor correctly, such a large concurrent heap of similar jobs will load the totality of the
   system differently than each processing stage would have done by itself in normal use. That is, the concurrency of
   the different stage processors might be good for a normal usage, but with the load from many near identical job flows
   running through multiple services at the same time, you get a degenerate situation - maybe three of the involved
   microservices different databases actually reside on the same physical server.
    * A partial solution to this is, as mentioned, to use an initial choke-point stage processor with very few, possibly
      just one, concurrent processor. This would effectively reduce the downstream concurrency.
    * However, you could still end up in a situation where some downstream service already was struggling: Maybe there
      was another batch process going on, or some external resource was in a reduced state. Even with a reduced pacing
      from the start, you could still max out this service and get queues built up.

### Explicit Work Queues

While there are ways to mitigate the problem you create by sending 10k jobs onto the MQ at the same time, it might be
better to use explicit work queues. You could then pace the issuing. As a simple example, this could be a schedule that
runs every 5 seconds, and looks at the current list of jobs. It counts how many jobs are in state
"PROCESSING". It tries to keep 20 jobs outstanding, and thus picks the next up to `20 - count_processing` jobs that are
in state "NOT_STARTED" (thus avoiding other states like "PROCESSING", "DONE" and "ERROR"), and starts processing
for these.

These numbers can be tuned. You could increase or decrease the number of outstanding jobs. You could adjust the
interval, or better yet, make a solution where a job that "came home" to mark the job as "DONE" would trigger the job
issuer. You could thus tune the concurrency and speed of execution versus system load and responsiveness for other
concurrent work.

You could make a solution whereby you can tune the numbers runtime, and also make a function whereby you can stop the
job issuer altogether. You'd then have a "stop the world!" button if needed: If you realize that there is a problem, you
would have a way to reduce the mess and resulting clean up.

Such runtime tuning will be nice in the future, when you for the first time set your rather heavily refactored
processing code into production: You could reduce the number of outstanding jobs down to 1, and increase the interval.
Maybe you could even stop the issuer, and manually trigger a single run, and follow the resulting few orders through the
process flow - to see if your code testing and staging verification actually held true in production.

And crucially, if your primary outstanding-queue is a SQL table, you can make whatever introspection and monitoring
features you want, including a way to trigger a specific job, or manually state-change it if needed. This compared to
the more basic, and harder to efficiently employ, solutions the MQ natively provide. (As mentioned, these MQ-native
solutions are primarily meant as ops-introspection. Think monitoring the JVM via JMX and instrumenting, as opposed to
dedicated GUIs for daily work)

## Batching instead?

All this said: There are very good arguments for batching jobs, instead of performing them one by one. This one-by-one
logic will obviously result in very many single-row accesses to databases and other external resources, from all the
processing stages in the flow. Instead, you could send all 10k jobs in one message, or divide them into 10 x 1k job
messages - where you've coded all downstream stages to also handle multiple jobs at the same time.

Batching is smart if all jobs will be handled exactly the same (e.g. generation of a years-end orders report, where you
make the same type of document for all customers), and less compelling if there are twists and forks in the process -
one job would take this route, while another that route, based on job properties.

There are other avenues for batching, and it also introduces new challenges, is explored in the article 
[Batching](/patterns/batching).