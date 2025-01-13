# Week 6 Data Pipeline Maintenance

## Table of Contents
- [Week 6 Data Pipeline Maintenance](#week-6-data-pipeline-maintenance)
  - [Table of Contents](#table-of-contents)
  - [Pipeline Overview](#pipeline-overview)
  - [Owners and Responsibilities](#owners-and-responsibilities)
    - [Primary vs. Secondary Owners](#primary-vs-secondary-owners)
  - [On-Call Schedule](#on-call-schedule)
    - [Example Monthly On-Call Rotation](#example-monthly-on-call-rotation)
    - [Holiday Considerations](#holiday-considerations)
  - [Runbooks for Investor-Facing Pipelines](#runbooks-for-investor-facing-pipelines)
    - [1. Profit Pipeline](#1-profit-pipeline)
    - [2. Growth Pipeline](#2-growth-pipeline)
    - [3. Engagement Pipeline](#3-engagement-pipeline)
    - [4. Aggregated Data Pipeline](#4-aggregated-data-pipeline)

---

## Pipeline Overview
We have **5 pipelines** that cover the business areas of Profit, Growth, and Engagement. Each area has two outputs: one for **daily or unit-level** needs (experiments, internal reports), and one for **aggregate data** that ultimately goes to executives and investors.

1. **Profit**
   - **Daily/Unit-Level**: Needed for experiment teams (A/B testing).
   - **Aggregate**: Monthly investor-facing reports.

2. **Growth**
   - **Daily**: Needed for experiments and tracking new sign-ups in near real-time.
   - **Aggregate**: Monthly investor-facing reports on total user growth, expansion, churn.

3. **Engagement**
   - **Daily**: Used by product teams to measure feature usage and conduct experiments.
   - **Aggregate**: Monthly investor-facing reports highlighting user engagement trends.

---

## Owners and Responsibilities
We have 4 data engineers sharing responsibilities:

1. **Alice**
2. **Bob**
3. **Carol**
4. **David**

### Primary vs. Secondary Owners

| Pipeline                                     | Primary Owner | Secondary Owner |
|---------------------------------------------|--------------|----------------|
| **Profit (Daily + Aggregate)**              | Alice        | Bob            |
| **Growth (Daily + Aggregate)**              | Bob          | Carol          |
| **Engagement (Daily + Aggregate)**          | Carol        | David          |
| **Aggregated Data (Investor-Facing)**       | David        | Alice          |

- **Primary Owner**: Responsible for day-to-day oversight, triaging incidents, and ensuring SLAs are met.
- **Secondary Owner**: Steps in when the primary owner is on vacation, holiday, or otherwise unavailable. Provides assistance for major incidents.

---

## On-Call Schedule

Below is a proposed **4-week rotation** that is fair for all, including considerations for holidays. This schedule will repeat every 4 weeks. Adjust as needed for your organization’s fiscal/calendar months.

### Example Monthly On-Call Rotation
| Week        | On-Call (Primary) | Backup (Secondary) | Notes                                   |
|-------------|-------------------|---------------------|-----------------------------------------|
| **Week 1**  | Alice             | Bob                | Alice covers Profit pipelines primarily; monitors others if needed. |
| **Week 2**  | Bob               | Carol              | Bob covers Growth pipelines primarily.   |
| **Week 3**  | Carol             | David              | Carol covers Engagement pipelines.       |
| **Week 4**  | David             | Alice              | David covers Aggregated investor pipeline. |

### Holiday Considerations
- If a holiday (e.g., company-wide or public holiday) falls during someone’s on-call shift:
  1. The **secondary owner** steps in during the holiday(s).
  2. If the holiday spans multiple days, the schedule can shift so no single person is overly burdened.
- Vacation coverage: If a primary on-call engineer is on vacation, the backup secondary engineer becomes primary for that period. Another volunteer from the team can step in as secondary if needed.

---

## Runbooks for Investor-Facing Pipelines

Below are the runbooks for **investor-facing** (aggregate) pipelines. While daily/experiment pipelines are essential, the investor-facing ones (monthly/quarterly aggregates) have the highest visibility and risk for the business if they fail.

### 1. Profit Pipeline

**Description**
This pipeline consolidates revenue and expense data across all accounts to produce monthly profit metrics presented to investors.

- **Primary Owner**: Alice
- **Secondary Owner**: Bob

**Data Sources**
1. **Revenue Records**: Subscription fees, account upgrades, monthly statements.
2. **Expense Records**: Salaries (aggregated), infrastructure costs, third-party licenses.

**Potential Issues**
1. **Mismatched Financial Data**: Financial numbers not aligning with official accounting filings (may need manual verification by Finance).
2. **Stale or Delayed Data**: If expense records from the Ops team are delayed, monthly totals might be inaccurate or incomplete.
3. **Scaling / Performance Problems**: Large data volumes near month-end can cause slowdowns, OOM in Spark jobs, or other ETL bottlenecks.
4. **Data Quality / Missing Entries**: Incomplete logs for revenue or expenses can lead to erroneous profit calculations (risk of negative or zero profit).

**SLAs**
- **Monthly Refresh**: Data must be accurate 2 business days before investor presentations.
- **Data Integrity**: >99.5% data completeness for financial records each month.

**On-Call Actions**
- **Weekly Monitoring**: Check pipeline run status, watch for error logs.
- **Critical Time**: End-of-month (EOM) spike. Possibly daily checks in the last week of the month.

---

### 2. Growth Pipeline

**Description**
Tracks account sign-ups, cancellations, and subscription changes. Produces monthly growth metrics for executives and investor updates.

- **Primary Owner**: Bob
- **Secondary Owner**: Carol

**Data Sources**
1. **Account Updates**: CRM or subscription system logs.
2. **License Changes**: Increases or decreases in seat count.
3. **Status Changes**: Renewals, cancellations.

**Potential Issues**
1. **Missing Status Updates**: The account executive team forgot to enter a status change, leading to inconsistent time-series data.
2. **Churn/Retained Overlapping**: If old accounts overlap with new sign-ups in the data pipeline, might get double-counting.
3. **Latency**: Growth metrics must be near real-time for experiments, but investor data only needs monthly aggregates.

**SLAs**
- **Monthly Aggregates**: Must be finalized 2 business days before monthly executive report.
- **Daily / Real-Time Growth**: Data updated by end of each day for product experiments.

**On-Call Actions**
- **Monitor**: Weekly checks to ensure pipeline is picking up all new sign-ups or cancellations.
- **Debug**: If pipeline fails, fix during normal business hours (no immediate emergency for daily pipeline unless near month-end).

---

### 3. Engagement Pipeline

**Description**
Collects clickstream, usage, and session data to measure platform engagement. Aggregated results appear in monthly investor slides.

- **Primary Owner**: Carol
- **Secondary Owner**: David

**Data Sources**
1. **Clickstream**: Web and mobile analytics (Kafka).
2. **Session Tracking**: Logins, session durations, team-based usage stats.

**Potential Issues**
1. **Late-Arriving Data**: Events may arrive in Kafka hours or days later, leading to incomplete daily counts.
2. **Kafka Downtime**: Complete loss of engagement events if Kafka is offline.
3. **Duplicate Events**: Some events might be sent multiple times and need de-duplication.
4. **Large Scale**: High volume of events may cause join and aggregation steps to fail due to memory limits.

**SLAs**
- **Monthly Reporting**: Final numbers must be accurate by EOM to show consistent daily engagement totals.
- **Data Latency**: 48-hour maximum to capture all late-arriving events for monthly aggregates.

**On-Call Actions**
- **Weekly**: De-dup checks on raw data.
- **Critical**: If Kafka is down or high-latency is discovered, escalate to the Infrastructure team.

---

### 4. Aggregated Data Pipeline

**Description**
Combines **Profit**, **Growth**, and **Engagement** data into a single monthly report consumed by executives and investors.

- **Primary Owner**: David
- **Secondary Owner**: Alice

**Data Sources**
1. **Profit Pipeline Outputs**: Merged with account-level revenue/expenses.
2. **Growth Pipeline Outputs**: Summaries of new accounts, churn, seat expansions.
3. **Engagement Pipeline Outputs**: Aggregated usage metrics, time spent.

**Potential Issues**
1. **Join Failures**: Large Spark joins across multiple datasets can cause OOM errors.
2. **Stale Downstream Data**: If upstream pipelines (Profit, Growth, Engagement) are delayed or backfilled, the aggregated pipeline has outdated data.
3. **Missing Data**: Gaps in daily usage or financial data can cause `NaN`, `NULL`, or divide-by-zero errors in final metrics.

**SLAs**
- **Monthly Deliverable**: Must be finalized 1–2 business days before executive meetings / investor calls.
- **Data Completeness**: All upstream pipelines must have at least 99% coverage.

**On-Call Actions**
- **Last Week of Month**: Intensive monitoring to ensure all upstream data flows are complete and correct.
- **Escalation**: If OOM or major pipeline break, contact entire data engineering team + relevant application teams.
