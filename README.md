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
