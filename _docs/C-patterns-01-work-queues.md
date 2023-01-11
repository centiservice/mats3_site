---
title: "Work queues"
permalink: /patterns/work-queues/
excerpt: "When having many jobs that needs processing, throwing them all on the MQ might not always be what you need."
created_at: 2023-01-11T08:58
last_modified_at: 2023-01-11T08:58
classes: wide
---

When having many jobs that needs processing, throwing them all on the MQ might not always be what you need.

## Handling many Orders

So, say you have a heap of outstanding, not-fulfilled orders. You then get some new information, possibly incoming
products, which makes a bunch of these orders fulfillable.

Say 10 000 orders became fulfullable at the same time, and you now need to start a process for each of them, which will
span multiple services.

If you were using HTTP as your interservice communications, you would most probably _not_ fire up 10k threads and do
them all at once. You would rather pick e.g. 10 of them and run these in parallel (or better yet, batch them, but that's
for a later post!). Once these are done, you'd fire up 10 more. Or, you might make a logic where you attempt to keep 10
outstanding, in-progress jobs until the list is done.

The reason for the need for such pacing is that all resources are limited. Trying to perform 10k queries simultaneously
on the different databases your microservices employ would trash them, and make the total time possibly even longer than
doing them sequentially. In addition, these parts of the system would probably be effectively unusable for anything else
during the time it took to process them - which as just pointed out might even be longer due to high concurrency and
resulting complete saturation of resources.

When using messaging, it is possible to just throw all 10k jobs on the queue, and then let the MQ handle the pacing of
the messages: You can tune the number of consumers on each stage, so that the external resources like DB didn't
saturate. It is even possible to use the initial stage of such a "handle many orders" processing flow as an explicit
choke-point: Tune down the concurrency on this first stage, so that the rest of the system got a nice pace of incoming
processes. Assuming that this choke-point processing stage only was used for this mass-fulfill scenario, you could even
throw in a small `Thread.sleep(100)` there to further lower the pace.

However, if this is a very central and important part of your system, there are arguments for still using an explicit
pacing.

## Problems (and solutions) with large number of jobs on the MQ

Some problems with throwing all 10k jobs on the queue at the same time is that you might tax the total system rather
heavily, and that you to some degree loose introspection, monitoring and control of them.

1. <b>Heavy load</b>: It might load the system quite hard. While this does point at you not having tuned the concurrency
   of each stage/queue processor correctly, such a massive concurrent heap of identical jobs will load the totality of
   the system differently than each processing stage would have done by itself. That is, the concurrency of the
   different stage processors might be good in the overall situation, but with the load from many identical jobs, you
   get a degenerate situation - maybe three of the involved microservices different databases actually reside on the
   same physical server.
   1. A solution to this is, as mentioned, to use an initial choke-point stage processor that effectively reduced the
      downstream concurrency.
2. <b>Introspection of system, Monitoring of jobs</b>: It is harder to get a total understanding of your full set of
   outstanding processes. While e.g. JMS have a `QueueBrowser` concept whereby you can introspect a queue, this is more
   usable as an operations-side introspection tool than as monitoring specific processes.
   1. A solution to this is to let the processes at certain points swing back to the orders table and record which stage
      it has finished, and/or which stage it embarks on.
3. <b>Control</b>:
   1. Since you already threw all 10k jobs on the queue, you do not have a way to stop the issuing. Had you used an
      approach of dishing out smaller sets via a scheduler, and you had foresight enough to code up a way to stop the
      schedule, you could have stopped the scheduler to avoid even more cleanup work.
   2. If there are some problem down the processing flow, e.g. a database that went offline, a logic error wrt. system
      state where effectively all orders will fail, or a newly introduced coding error, you are now in a though spot:
      You have already added those 10k jobs to the queue, and they effectively need to run their course. If each job
      will end up with a DLQ, you'll get up to 10k DLQs that needs handling by reissuing or deleting. Also, putting a
      message on DLQ takes time, as the MQ will first try multiple redeliveries before giving up. So you might now have
      a heap of outstanding messages which you know with certainty will all DLQ, but this will take much more time than
      it would have taken in the good case.
   3. A solution here could be that you on the points where the processes report back - the solution mentioned in #2 -
      you could also let the job check a flag of whether the system status was "HALT", or the job status was "
      CANCEL_PROCESSING", or somesuch. In these cases, the job would stop its multi-stage processing, record that it has
      accepted cancel and which stage it was in at that time.

### Explicit Work Queues

However, while there are ways to mitigate the problem you create by sending 10k jobs onto the queues at the same time,
it might be better to use explicit work queues. You could then pace the issuing. As a simple example, this could be a
schedule that runs every 1 minute, and looks at the current list of jobs. It picks the next up to 10 jobs that are in
state "NEEDS_PROCESSING" (thus avoiding other states like "UNDER_PROCESSING", "DONE"
and "ERROR"), and starts processing for these.

Also, if your primary outstanding-queue is a SQL table, you can make whatever introspection and monitoring features you
want, compared to the more basic, and harder to efficiently employ, solutions the MQ natively provide. (As mentioned,
these solutions are primarily meant as ops-introspection. Think monitoring the JVM via JMX and instrumenting, as opposed
to dedicated GUIs for daily work)

If you make a solution whereby you can stop the issuer runtime, you would have a "stop the world!" button so that if you
realized that there is a problem, you would have a way to reduce the mess and resulting clean up.

These numbers can be tuned, maybe even runtime if you code up something. You could increase the number of issued per
batch, you could reduce the interval, or make a smarter solution which tried to continuously keep a given number of
orders "in flow" - tuning the concurrency, speed and load.

This will be nice in the future, when you for the first time set your rather large processing refactoring into
production: You could reduce the number of issued jobs, and increase the interval. Maybe you could even stop the issuer,
and manually run a single issue, and follow the resulting one or few orders through - to see if your code testing and
staging verification actually held true in production.

## Batching instead?

All this said: There are very good arguments for batching. This one-by-one logic will obviously result in very many
"singular" accesses to databases and other external resources, from all the processing stages in the flow. Instead, you
could send all 10k in one message - where you've coded all downstream stages to also handled multiple at the same time.

Batching is smart if all jobs will be handled exactly the same (i.e. report generation where you make the exact same
document for all customers), and less compelling if there are twists and forks in the process - one job would take this
route, while another that route, based on properties and circumstances.

There are other avenues for batching, and it also introduces new challenges, which will be explored in a future article.