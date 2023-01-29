---
title: "Batching when using messaging"
permalink: /patterns/batching/
excerpt: "When having many similar jobs that needs processing, you can gain a major performance advantage by executing them in batches."
created_at: 2023-01-11T08:58
last_modified_at: 2023-01-11T08:58
classes: wide
---

> Messaging naturally provides high availability, scalability, location transparency, prioritization, stage transactionality, fault tolerance, great monitoring, simple error handling, and efficient and flexible resource management. However, messaging can be much harder to employ in practice due to a fundamentally different programming model.
>
> <b>Mats<sup>3</sup></b> is a client side Java library that makes asynchronous message-oriented interservice communications mimic a synchronous, blocking and linear/sequential way of coding, greatly reducing the mental shift and cognitive load, and increases developer productivity when using messaging. You gain all the positives of messaging, while virtually eliminating the negatives.

## Scenario

You have a microservice architecture using messaging as interservice communications. You have certain batch processes
where you need to perform a specific job for many entities. If the job to do for each entity is very similar, e.g.
creating a yearly report for all your customers, it might be rather wasteful to treat each of these as separate jobs,
creating a separate process or _flow_ for each of them. Instead, you could batch them, either by performing them "all at
once", or in slices of e.g. 1000 and 1000.

## Handling a year-end report generation for all your customers

In the [Work Queues](/patterns/work-queues/) article, we looked at the situation of running many jobs through a
microservice architecture using messaging, and argued that it might be smart to not just chuck all the jobs onto the MQ
in one go, but instead use a pacing mechanism to send off smaller slices of the total batch. This so that you would have
monitoring and control capabilities, and also to not load the system to its knees while performing this large set of
jobs.

However, it was still implied that each of the jobs was issued as a separate message, thus initiating a separate
down-stream process for each job. For a Mats<sup>3</sup>-based system, each such initiated process would be called a
<i>Mats Flow</i>.

This again implies that each step, or stage, of each job would need to query any service-specific databases separately.
If this concerned a million customers, and if generating a single report needs to perform 10 queries over 5 services,
each service having a different database, this could become a pretty heavy burden for your total system.

Had this been a monolithic system, where you had access to all data from any thread, one must hope that your code review
process would have caught the opportunity for batching these queries to the databases, instead of issuing a bunch of
separate "single-row SELECTs" for each individual customer.

It is implied here that the work to be done for each entity, each customer, is identical. We're going to generate a
year-end report, and for each of them, the work to be done is exactly the same: Get the customer's transactions for the
year, get current outstanding orders, get current standing from invoices, and then generate the PDF. Such a bunch of
jobs are ripe for batching. Other types of jobs, where each individual instance might have different "ifs" or "elses"
based on the entity's type and properties, and thus will execute different sub-flows of the process, are probably not as
easily batchable. But then again, you might need to batch anyway if the volume is high enough.

## Two approaches

There are probably plenty of ways to handle this, but here we'll focus on two variants: The first is doing multiple jobs
per issued message/flow - either the entire batch, or <i>slices/chunks</i> of the batch. The second is to first gather
the needed information to the database of a specific service, and then perform the final composition of data and
generation of the PDF locally on this central service.

Both of these variants require you to somehow know what the total batch constitute, e.g. a list of all active customers.
For the example at hand, where we'll each year will generate a report for all our customers, I would argue that it makes
sense to make a `batchruns` table. You'd create a new entry in this table, having a `batchrun_id`. Then you'd find all
the customers which should be included in this year's batch, and stick them all in as rows in another
table `yearly_reports`, with a key back to this year's `batchrun_id`. Each row in this table would hold the `state` of
this customer's report, starting out with e.g. `NOT_STARTED`, and be progressively updated with whatever states your
generation flow will pass through. It could also have a column for the finished PDF.

This would be your "Work Queue", and our goal is to get all rows into a "completed" state like `FINISHED`, having the
PDF column filled, as efficient as possible. Note that another "completed" state might be `ERROR`, if we get into
problems generating a particular report. Such a state is, temporarily, regarded as a "completed" state, since it for the
time being is not in progress anymore, and we must not start generating it again until we've found out why it didn't
work out.

### Chunking of the batch

So, the first variant is really just to ensure that all the implicated endpoints handle a "list"-variant of its incoming
request, that is, instead of the Request DTO specifying a single `String customerId`, you take
a `List<String> customerIds` - and of course, the Reply DTO must also respond with a List of results.

> As a side note here, it is heavily suggested to _always_ do that: Implement multi-Request and Reply DTOs for your
> endpoints to allow for later use in a batch solution. It cost little to do this, and it is still easily usable if you
> only need a single instance. However, the endpoint is now much better suited for performant processes. Do this even if
> you just perform the most basic implementation of multiple-handling, i.e. take the list and do a for-each execution of
> each of the entities inside the service, by e.g. performing a single-row SELECT for each of the requested entities.
> Even by implementing such a banal solution locally in the service, you've probably captured 50% of the performance
> gain. You now actually have a solution where you can query for 250 entities in one go, and you thus avoid 249 x 
> request and reply round trips over the MQ for this data.
>
> Also, once you have multi-Request and Reply DTOs, you can at a later time easily reimplement the endpoint to be
> more performant locally in the service, without changing the endpoint interface: Inside in the service, you change the
> implementation from a for-each single-row-lookup in the database, to instead query the database for all 250 records in
> one go. But you can defer the decision of such a heavier implementation to when you can find a data point showing
> that it would be beneficial to do so.

So, basically, this is just the simplest refactor of the solution described in the [Work Queues](/patterns/work-queues/)
article: By having the ability to employ multiple-Request and Reply DTOs, you can simply replace sending 10 and 10
messages, with sending messages with 10 and 10 entities in each message. But since this is so much more efficient locally
in each service, and the chunking heavily reduces the number of messages and hence concurrent flows sloshing about, you
probably want to increase the number of entities per message, that is, the chunk size, to e.g. 500. If the batch is
small enough, you could do them all in one go.

> You can get into size limitations. Passing gigabytes over the MQ in a single message is really not what it is meant
> for. If you as a final Reply pass the generated PDFs back, let's hope you've been smart wrt. to size of the documents
> you generate: If such a report PDF as a base include a TIFF logo of 1 MB, in addition to the dynamic data, you might
> choke the processing, either on the MQ, or on the service node which might have to handle multiple of these
> 500-PDFs-bundle messages concurrently. Size per PDF is of course a big point at any rate: It is nicer to keep one
> million PDFs in your customers' inboxes when the individual PDFs are between 25 and 100 kB with some outliers at 200
> kB, than if they are all over 1 MB. Be critical of how the PDFs are generated, the amount of cruft in them, and use
> vector graphics for logos, not TIFF files! Your customers will also love you for not throwing a multi-MB PDF at them,
> when it could have been 67 kB!

With this approach, it is important that all the needed endpoints in the flow support multiple-Request and Reply DTOs.
This is because it is hard to midway in such a flow have to "split up" the processing due to an annoying endpoint which
only have a single-entity Request/Reply DTO. This would basically involve a _scatter/gather_ style logic, and the bad
part of that is that it needs state for the gather phase. So, instead go over to that endpoint and add a List-variant
inside the Request/Reply DTOs (and as mentioned in the aside above, a banal solution of such multi-handling is just fine
as a first pass).

#### Error handling

A thing to worry about is the error handling. While such chunking is a pretty simple improvement for the good path, it
becomes a tad more annoying when things start going wrong: In the individual flow per customer solution, any error with
a single customer is handled OK: If some data is missing, or erroneous, that one single flow would probably DLQ, while
no other customer is affected. However, in the chunking scenario, where you've grouped this customer together with 499
other, the report generation of all those 500 customers would be affected by this single customer's erroneous data,
since this one message would DLQ and stop the processing for all 500.

Solutions to such problems are multiple:

1. Don't have bad data! Make some way to validate and correct the data before sending off the batch generation.
2. Code robust, handle corner cases properly! The data might not be erroneous, it is just that the one stage didn't
   handle negative outstanding balance or somesuch. That is bad code. Have good testing, where all corner cases are
   exercised.
3. Fix the code or the data for this customer (after having scoured the logs for which customer created the problem),
   and reissue the DLQ.
    * However, if the data inside the message already is bad, due to the error having been introduced by a previous
      stage, no amount of reissuing will fix the problem (unless you handle it by introducing code so that this stage
      accepts or at least handle the problematic data). Therefore ..
4. You should have a way to reissue outstanding/not-completed report generations, preferably via some GUI. Delete any
   DLQ, and just reissue the generation.
5. It could be beneficial to runtime be able to decide the chunking size. If you've gotten 99% of the reports through,
   but where the last 5000 customer's reports was "locked up" inside 10 different DLQ'ed messages due to 10 customers
   with bad data, you could instead set the chunking size down to 1, and reissue the generation of the outstanding
   reports. They would now be done individually, so that you were only left with DLQs of the actual 10 customers that
   causes problems, relieving the pressure of handling this.
6. Or, alternatively, implement the code so that no stage of the implicated endpoints in the flow will DLQ. Instead, if
   a stage find bad data, it'll mark the "slot" for the affected customer with an error-result, including some
   description of what was the problem. Any downstream stages would have to omit any such marked customer, and
   eventually report back home to the
   _work queue_ with the 499 correctly generated PDFs, plus the 1 error.
    * It might be relevant to have a "mode"-flag in such endpoints: In the ordinary mode, the endpoint would DLQ a bad
      Request, under the general idea of "offensive coding". But in such a batch-processing situation, you'd rather not
      have DLQs ever, but instead a Reply with the indicated failure.

### Gather data to central location, process locally

The other approach is to back a tad off from the idea of using the MQ and Mats Flows for the full process of generation
these PDFs.

Instead use Mats (or any other IPC protocol, but once you have Mats, you'll never go back) to reach out to the
individual dependent services for gathering the needed data for all the PDFs to a central location. Once this has been
done, you now have all the data needed to generate these PDFs any way you want. A good approach would be by using a
local thread pool of N threads, which you feed jobs from the local Work Queue - where each job now have the data needed
in the local database.

There are thus two separate phases: First gather the data. When this is done, you can fire off the generate-report
phase. Actually, this might even go concurrently: Once you have the required data for a customer, you can fire off a
task to a thread pool to generate the PDFs.

The first phase consists of separate parts, which can be run concurrently: One to talk to the transactions-service, one
for the outstanding orders, and one for the invoices. Each of these can be tailored to the individual collaborating
service. As opposed to the chunking solution above, it would not be a deal breaker if one of them only had one-by-one
Request/Reply DTOs (but one should still consider to rather fix that problem for performance). However, if a piece of
the data gathered was from an external service, possibly some REST endpoint, and this just accepts single requests, then
that's less of a problem - but it will then probably be the limiting process when it comes to time taken to finish the
total batch.

One way to look at this, is as a massive scatter-gather style process: Scatter out (in parallel) the data fetching
processes, and then gather the results back and store them (temporarily) - and once everything is gathered, you will
finish the process by generating the PDFs.

The local data store would probably both be task-specific and temporary. This means that you do not need to create a
proper data model in the database. Instead, just hammer in the data in any way that makes sense for both the gather and
the generation phase. You could use a document database, or simply store the received DTOs serialized, as long as the
generation-phase was happy with deserializing them again. This again means that you could just use a single row per
report, with the columns representing each of the different data sets, from the different queried services needed to
generate that one single report. Thus, the "work queue" table mentioned in the beginning would be a perfect candidate to
hold this data.

Since this is only an idempotent "getting" phase, with no corresponding flow state, you can employ non-persistent
messaging. You can even employ the `MatsFuturizer` (but do not use the <i>interactive</i> flag), to do this
synchronously. The point is that if anything crashes during this phase, it doesn't matter. The only thing that matters,
is that all those columns in all those rows <i>eventually</i> is filled up - if a node crashes while it is executing
such a getter, there's no problem as long as someone eventually picks it up again and fills it.

You need to implement some kind of task scheduler to do this. On a very high level, what you want is to just pick up
elements that are missing, and fire off queries to the corresponding services to fill them in - until everything is
filled.

You should of course have multiple instances of this service too. This means that you would want a way where the nodes
cooperate or compete for picking up work. A viable approach here is a "job allocation" strategy, where nodes try to
mark work for themselves by a UPDATE construct, up to e.g. 500 in one go, and then fire off those it got allocated.

To give a rough sketch: For fetching the "transactions" part of the gather part, you could make a thread, and do
something like this:

```sql
-- allocate "fetch transactions" sub-jobs to this node:
UPDATE work_queue
SET transactions_fetcher_node = <this_nodename>,
    transaction_fetcher_timestamp = <now>,
    transaction_fetcher_status = 'ALLOCATED'
WHERE job_id IN (SELECT TOP 500 job_id FROM work_queue WHERE transactions_fetcher_node IS NULL)
  AND transactions_fetcher_node IS NULL;
```
Note that the inclusion of `WHERE transactions_fetcher_node IS NULL` in both the inner sub-SELECT and the outer UPDATE
is on purpose: Since the inner sub-SELECT is executed "by itself", there is a possibility for a race condition where
another node is also just in the process of claiming those rows. By including the condition on the outer UPDATE too,
which is executed atomically, you prevent this race. It can potentially result in 0 claimed rows, if the other node
managed to allocate exactly the same set, but this is better han double-allocating.

```sql
-- find our allocated work
SELECT job_id, customer_id
FROM work_queue
WHERE transactions_fetcher_node = < nodename >
      AND transactions_data IS NULL;
```

You then send a request to the Transactions service to get this data for the set of returned customers, possibly using
a `MatsFuturizer`. When the data comes back, record the data, set the status to 'DONE', and go for another round. If you
get any errors back, or if the MatsFuturizer times out (indicating a DLQ situation), then you can set the status to '
ERROR'.

If this returns 0 rows, you are probably finished - but do a double check by issuing the inner sub-SELECT by itself,
which also should return 0 rows.

With this synchronous approach, there are some corner error situations to handle here. If the node goes down, or
respawns with a different nodename, in the period between after it has allocated the rows, but before actually getting
information back, those rows will be allocated but no one is doing anything anymore. That's why we added that timestamp
when allocating - if it has taken more than 10 minutes, and the status is still 'ALLOCATED', you could have another
process to free up the rows again.

Also read up on all the problems mentioned above in the other approach!

After all of the transactions, outstanding orders and invoices have been gotten for all customers, you can start the
second phase. Or, you could do this concurrently, whereby customers that have all of `transactions_data`, `orders_data`
and `invoices` set, you start the composition of the data and generation of the report. This would be a similar kind of
job allocation strategy, where you fire off as many concurrent threads the instance can comfortably handle.

A nice thing is that you can re-run the report generation phase again and again, without incurring the cost of gathering
the data. Thus, if you in quality control find a bug with either all, or a subset of the reports, you can just "null
them out", fix the generating-code, and then re-run the report generation phase.

Depending on how flexible you've implemented the data gathering phase, you could get other benefits too. If you find
that some subset of users have gotten a part of the data gathering wrong, or when you find out what has caused some
gatherings to DLQ, you could reset the fetcher_node and fetcher_status, and "null out" the wrong data, just for the
problematic customers. You'd then start the data gathering machinery again, where it would then find just those "holes",
and ensure that they were filled in. After this, you could run the report generation again, for all, or just for these
problems.

## Monitoring and health checking

For both approaches, a good monitoring solution with a nice introspection GUI is in order. This should probably let you
manually "null out" or otherwise reset the state of certain rows, or certain pieces of data, so that you can refetch, or
regenerate the PDFs, for these rows.

A health check solution could highlight if you get ERROR rows, or stale rows, so that the system "call in the humans" if
things go wrong.

## Some details left as an exercise ..

While the above just sketches out two approaches to do batching in a messages based microservice architecture, there
should be enough meat on the bones to get you going. If you have comments or suggestions, ping me!