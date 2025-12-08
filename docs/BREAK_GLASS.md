# Break-Glass Procedures  
## Governed Infrastructure Control Plane

**Document Type:** Operational Security Control  
**Classification:** Restricted  
**Applies To:** Production and Pre-Production Systems  
**Standards Alignment:**  
- ISO 27001:2022 Annex A  
- SOC 2 (Security, Availability, Change Management)

---

## 1. Purpose

This document defines the emergency (“break-glass”) procedure used when standard governance controls prevent timely recovery from a material operational incident.

Break-glass is designed to:
- Preserve availability
- Protect data integrity
- Enable recovery when normal control paths are unavailable

Break-glass use is **exceptional, time-bound, auditable, and reversible**.

**ISO 27001:**  
- A.5.1 – Policies for information security  
- A.16.1 – Management of information security incidents  

**SOC 2:**  
- CC1.1 – Integrity and ethical values  
- CC5.1 – Control activities aligned to objectives  

---

## 2. Authorization Conditions

Break-glass MAY be invoked only when **all governed access paths have failed** and **material risk exists**.

Authorized triggers:
- Loss or unavailability of cryptographic signing keys
- Backend lock integrity prevents recovery
- Prolonged system outage or imminent impact to customers or regulators

Break-glass MUST NOT be used for:
- Expediency
- Routine change
- Governance avoidance

**ISO 27001:**  
- A.6.2 – Segregation of duties  
- A.8.2 – Privileged access rights  

**SOC 2:**  
- CC6.1 – Logical access restrictions  
- CC6.2 – Authentication and authorization enforcement  

---

## 3. Control Principles

All break-glass activity adheres to:

- Least privilege  
- Time-limited access  
- Named human accountability  
- Full auditability  

No anonymous or shared access is permitted.

**ISO 27001:**  
- A.8.3 – Information access restriction  
- A.5.18 – Access rights review  

**SOC 2:**  
- CC6.3 – Privileged access monitoring  

---

## 4. Preconditions for Use

Before execution, the operator MUST have:
- Authenticated OS access to the secured admin host
- Provider credentials scoped to the affected environment
- An incident reference ID (ticket, pager, or alert)
- Ability to commit audit evidence to Git

**ISO 27001:**  
- A.12.3 – Backup  
- A.8.1 – User endpoint devices  

**SOC 2:**  
- CC7.2 – Incident response readiness  

---

## 5. Break-Glass Declaration

Prior to any action, the following environment variables MUST be set:

```bash
export GOVERNED_BREAK_GLASS=true
export BREAK_GLASS_REASON="Describe incident and justification"
export BREAK_GLASS_TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
