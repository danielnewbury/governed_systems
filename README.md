# Governed Infrastructure Bootstrap

This repository provides a **governed Terraform control-plane bootstrap system**.

It is designed to enforce **explicit intent, non-repudiation, provider parity, and deterministic rebuilds** before *any* Terraform infrastructure can be planned or applied.

This is **not** a general Terraform example.
It is a **security and governance system** that wraps Terraform with hard guarantees.

---

## Design Principles

This system enforces the following invariants:

- **Explicit backend selection**  
  No implicit or default Terraform backends are allowed.

- **Template integrity verification**  
  Backend configuration is hash-locked and verified before use.

- **Signed intent (non-repudiation)**  
  Backend intent is GPG-signed and verified on every run.

- **Provider feature parity**  
  Regions, naming, and metadata are policy-controlled and enforced equally across providers.

- **Deterministic rebuilds**  
  A tagged release produces the same control plane every time.

- **Fail closed**  
  Any missing requirement halts execution immediately.

---

## Repository Structure

```text
.
├── bootstrap.sh                 # Primary governed entrypoint
├── VERSION                      # Human-readable version
├── backend_templates/           # Approved backend templates (hash-locked)
├── infra/
│   └── bootstrap/               # Terraform bootstrap configuration
├── policy/
│   └── provider-parity.yaml     # Provider parity & naming policy
├── scripts/
│   ├── select-backend.sh
│   ├── setup-{aws,gcp,local}.sh
│   ├── verify-backend-lock.sh
│   ├── validate-backend.sh
│   ├── enforce-parity.sh
│   └── setup-gpg-identity.sh
└── README.md


Here’s a tight, accurate description you can use verbatim. It explains *what the system is* without marketing fluff and without underselling the discipline you’ve built.

---

This repository implements a governed Terraform bootstrap system designed to establish a secure, auditable control plane for infrastructure management.

The system wraps Terraform with strict governance controls that enforce explicit intent, policy compliance, and non-repudiation before any infrastructure can be planned or applied. It is intentionally opinionated and fail-closed: if any requirement is unmet, execution halts immediately.

At its core, the bootstrap process requires an explicitly selected backend, verified against a cryptographic hash to prevent configuration drift or substitution. Backend selection is recorded in a lock file that captures metadata such as provider, region, and system identity. This lock file must be signed with a trusted GPG key, ensuring all foundational infrastructure changes are traceable to a verified human actor.

Provider parity is enforced through a centralized policy that governs allowed regions, naming conventions, and required metadata across all supported providers. No provider may bypass global rules. This guarantees consistent behavior, predictable environments, and prevents silent divergence between cloud, on-prem, or local execution contexts.

The system requires execution from a tagged release, ensuring deterministic rebuilds and preventing uncontrolled drift introduced by unreviewed code changes. Runtime artifacts, including backend locks and signatures, are intentionally excluded from version control to preserve intent integrity while keeping history auditable.

Execution is interactive by design. Operators must acknowledge warnings, confirm destructive actions, and explicitly authorize applies using multi-step confirmations. Safe defaults are prioritized, with plan-only execution as the standard path.

This system is not a replacement for Terraform, CI/CD pipelines, or configuration management. It is a control-plane guardrail designed to be run from a trusted administrative workstation to establish or re-establish foundational infrastructure under clear governance.

Its purpose is to make infrastructure decisions explicit, attributable, reviewable, and repeatable—by construction, not convention.

