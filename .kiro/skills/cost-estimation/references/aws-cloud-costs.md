# Cloud (Infrastructure) costs - AWS Calculator workflow

The cloud/infrastructure cost is estimated **service by service** with the **AWS Pricing
Calculator** (https://calculator.aws). The deck shows a per-service detail table (slide 58) and a
single "Cloud consumption" line in the global view (slide 59), plus the **shared Calculator link**.

## Step 1 - List the AWS services to estimate
Enumerate every AWS service the target architecture uses (take them from the technical
architecture / DAT and the data-flow). For each service, the Calculator needs the **region** and
the **consumption metrics**. Do NOT invent metrics - derive them from the design or ask the user.

Common services and the metrics that drive their cost:
| Service | Cost-driving metrics to estimate |
|---------|----------------------------------|
| **Amazon S3** (static hosting / storage) | Stored volume (GB), PUT/GET requests per month, data retrieval, data transfer out |
| **Amazon CloudFront** (CDN) | Data transfer out to internet (GB/TB per month), data transfer to origin, number of HTTPS requests per month, number of edge locations/regions |
| **Application Load Balancer** | Number of ALBs, LCU (new/active connections, processed bytes, rule evaluations) |
| **Amazon ECS Fargate** | vCPU count, memory (GB), average task duration, number of tasks/day, ephemeral storage |
| **Amazon ECR** | Stored image volume (GB), data transfer in/out |
| **Amazon RDS / Aurora** | Instance class, Multi-AZ, storage (GB), IOPS, backup storage |
| **AWS Lambda** | Requests/month, average duration (ms), memory (MB) |
| **Amazon API Gateway** | Requests/month, cache size |
| **CloudWatch / logs** | Ingested/stored log volume (GB), custom metrics, alarms |
| **Data transfer** | Inter-AZ, out to internet, to on-prem |

Estimate **per environment** (PROD + non-prod) and note **Multi-AZ** where relevant - the slide
title says "per environment (Multi-AZ)".

## Step 2 - Help the user estimate metrics / consumption
The user often needs help turning business volumes into service metrics. Reason from the expected
usage:
- expected **users / sessions / requests per day or month** -> CloudFront requests, S3 GETs,
  Lambda/API requests;
- **page/asset weight** x requests -> CloudFront/S3 data-transfer-out (GB/TB per month);
- **peak concurrency** and task profile -> ECS/Fargate vCPU-hours, ALB LCU;
- **data retention** -> S3/CloudWatch stored volume.
Always write the assumption next to the number (e.g. "1.5 M HTTPS requests/month, 1.5 TB DTO/month
assuming X visits x Y MB"). These assumptions become the slide's "Configuration summary" column.
If a volume is unknown, mark `TBD` and ask.

## Step 3 - Build and share the AWS Calculator estimate
Ask the user to enter each service in https://calculator.aws with the agreed metrics, then:
- **Save and share** the estimate -> copy the **public share link** (this is what the deck
  references on slide 59 - not a screenshot).
- **Export** the estimate (CSV / JSON / PDF). The export lists, per service: region, service name,
  monthly cost, annual (or 12x monthly), currency, and the configuration.

The agent does not have Calculator access; it consumes the **export or the numbers the user
provides**. Never fabricate service prices.

## Step 4 - Turn the export into the deck tables
- **Slide 58 (detail)**: one row per service = **Region(s) | Service | Monthly | Annual |
  Currency | Configuration summary**. Replace the template example rows (ALB, ECS Fargate, ECR,
  CloudFront) with the project's actual services; delete example rows that do not apply
  (per presentation-gates rule 8d).
- **Slide 59 (global view) - "Cloud consumption" line**: convert the **annual** cloud cost to
  **k€** (apply the agreed FX rate if the Calculator is in USD) and phase it across the columns:
  - during **build** (Year 1) the running cost ramps up as environments come online -> split across
    Q1-Q4 as the design dictates (e.g. non-prod first, prod at go-live);
  - **Year 2 "recurrent"** = the full steady-state annual cloud run cost.
- Record every service, metric and amount in the costs README so it is auditable and persisted.

## Currency note
Calculator export is typically **USD**. The global view is **k€**. Convert with the FX rate agreed
with the user (note the rate + date). Keep slide 58 in the Calculator's currency (USD) and the
global view (slide 59) in k€ - state both clearly.
