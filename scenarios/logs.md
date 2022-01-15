# SOLUTION: troubleshooting firewall rules with log Analytics

## Pre-requisites

In order to apply this solution you have to deploy hub playground only.

## Solution
First step is to create a Log Analytics Workspace named `playground-workspace` in `west-europe`.
In order to analyze firewall logs go to `lab-firewall` -> Diagnostic Settings -> Add Diagnostic Settings:
* Name: firewall-diagnostics 
* Logs: Category Group -> All logs
* Metrics: All Metrics
* Destination details: Send to Log Analytics Workspace -> `playground-workspace`
* SAVE

Prepare routing and firewall rules as described in [ping-any-to-any-firewall](./ping-any-to-any-firewall.md): when all these steps will be completed each machine will be able to communicate with any other via Firewall.

## Test solution
Connect via RDP from `spoke-01-vm` to `spoke-02-vm` (`10.13.2.4`).
After that the connection is estabilished, go to `lab-firewall` -> Logs -> click on `Run` button in **Network Rule Log Data** Box.

In the Result pane, the first row should be something like:

| Time | msg | Protocol | SourceIP | srcport| TargetIp | target port | Action |
|---|---|----|---|---|---|---|---|
|...|...|TCP|10.13.1.4|xxx|10.13.2.4|3389|**Allow**|

> Log ingestion from Azure Firewall can require from 60 seconds to 15 minutes, so if nothing is displayed, wait some minute and try again.

now to test the **deny** logging, change the firewall network policy as follow:

| rule name | source | port | protocol | destination | 
|---|---|---|---|---|
| all-to-all | group-spoke-01<br>  group-spoke-03 | * | Any | group-spoke-01<br> group-spoke-02<br> group-spoke-03 | 

go back to `spoke-01-vm` and repeat the RDP connection. The connection will be **allowed**. This is **correct** because we have denied the traffic that starts from spoke-02 to any other spokes, but because our connection begins from spoke-01 it will be still possible.

Now change the firewall network policy again as follow:

| rule name | source | port | protocol | destination | 
|---|---|---|---|---|
| all-to-all | group-spoke-02<br>group-spoke-03 | * | Any | group-spoke-01<br> group-spoke-02<br> group-spoke-03 | 

go back to `spoke-01-vm` and repeat the RDP connection. The connection will be **denied**. Infact now we have denied all the connections that begin from spoke-01.

Now go to `lab-firewall` -> Logs -> click on `Run` button in **Network Rule Log Data** Box.

In the Result pane, the first row should be something like:

| Time | msg | Protocol | SourceIP | srcport| TargetIp | target port | Action |
|---|---|----|---|---|---|---|---|
|...|...|TCP|10.13.1.4|xxx|10.13.2.4|3389|**Deny**|
