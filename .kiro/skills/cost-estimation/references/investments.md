# Investments (hardware + software licenses)

The third TCC cost family is one-off / capital **investments**, shown on the global-view slide as
two sub-lines:

## Hardware costs (servers, ...)
- On-premise servers, network gear, appliances, workstations, test devices, etc.
- For a **cloud-only** solution there is usually **no hardware** to buy (compute is rented as
  cloud consumption). State "N/A - fully cloud, no hardware" rather than leaving blank.
- If hardware is needed, capture: item, quantity, unit cost, total k€, and the year/quarter of
  purchase (usually Year 1).

## Software license costs
- Commercial software / SaaS subscriptions / tool licenses NOT already covered by cloud
  consumption: e.g. a paid framework, a monitoring/observability SaaS, a security tool, a design
  system, a commercial component, IDE/CI licenses specific to the project.
- Open-source frameworks (e.g. Angular, RxJS) have **no license cost** - note that explicitly.
- Capture per license: product, metric (per seat / per environment / per year), unit cost, total
  k€, and whether it is one-off (Year 1) or **recurrent** (also in the Year-2 recurrent column).

## Phasing
- One-off purchases -> the Year-1 quarter of acquisition.
- Recurrent subscriptions -> both Year-1 quarters (pro-rated) AND the **Year-2 recurrent** column.

## Inputs to ask the user (never invent)
- List of any hardware to purchase (or confirm none).
- List of paid software/licenses/SaaS and their pricing metric + fee (or confirm all
  open-source / already covered).
Mark unknowns as `TBD` in the costs README.
