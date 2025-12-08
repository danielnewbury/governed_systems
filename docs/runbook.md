
---

The Governed Infrastructure Bootstrap is a minimal, auditable control-plane foundation that treats infrastructure as governed product rather than ad-hoc IaC. Grounded in secure bootstrapping patterns, it enforces explicit backend selection, integrity (checksums + GPG signatures), signed human intent, and policy-driven parity (tags, naming, regions) before any Terraform state becomes mutable. The control plane is versioned and gate-kept: bootstrap runs only from signed repository tags, and a two-step confirmation (typed token + explicit APPLY) prevents accidental destructive actions.

Operationally, the bootstrap creates remote state stores (S3/GCS/OCI Object Storage/Spaces/MinIO), KMS/Vault keys, and CI service identities (OIDC federation where available). It pushes responsibility for ongoing applies to CI runners using least privilege while preserving an emergency interactive path for certified admin machines. Every bootstrap action is recorded and signed; break-glass steps are rare, documented, and produce auditable artifacts (signed lock records, revocation artifacts, and `BREAK_GLASS_ACTIVE` entries).

Security controls include artifact signing, immutable backend locks, parity enforcement via a policy file, and automated CI checks that fail builds when required governance artifacts are missing. The design separates concerns: DNS authoritative control sits outside this repo; control-plane hosts are ephemeral and stateless where possible; secrets live in dedicated secret stores. For enterprise use, the bootstrap is the “ground zero” that allows deterministic rebuilds, supports DR drills, and integrates with policy engines (OPA/Sentinel) for guardrails. The artifact and process model map cleanly to ISO 27001 and SOC 2 audit expectations: defined scope, documented procedures, cryptographic identity, least privilege, monitoring, and evidentiary trails for all bootstrap and break-glass operations.

---

**It’s a solid governed foundation but not "production-ready" out of the box.**

Why:
- You have the critical controls (signed intent, backend locking, parity enforcement). That’s excellent.
- To be production hardened you still need:
  - Centralized audit logging (immutable WORM storage, SIEM integration).
  - Secrets rotation automation (Vault auto-unseal, KMS key policies).
  - Formalized role separation and cross-account IAM trust models.
  - Resilient remote state (multi-region replication), and tested recovery playbooks.
  - Automated tests/DR drills and continuous compliance checks.
- So treat this as a governed *platform* that must be integrated with infra observability, secrets lifecycle, and enterprise IAM to be fully production.

---

# Break-Glass Rebuild Procedure (Governed Control Plane)

> Purpose: emergency rebuild of control plane when CI and standard management paths are unavailable.

## Preconditions
- Offline copy of repository (git bundle / signed zip) stored in secure locations.
- Offline copy of GPG signing key or access to HSM/KMS emergency unwrap.
- Physical access plan and at least two authorized operators (separation of duties).

## Steps (concise)
1. Retrieve offline repo + signing keys from secure location.  
   - Evidence: printed custody log, retrieval timestamp.  
   - ISO: A.8.1 (Asset management).  # SOC2: CC6.1

2. Confirm identity & authorization of operators (2-person rule). Record time, operator IDs, reason.  
   - Evidence: operator signatures, recorded justification.  
   - ISO: A.9.2 (User access management).  # SOC2: CC6.4

3. On secure admin laptop (air-gapped when possible), copy the correct backend template to `infra/bootstrap/backend.tf`.  
   - Verify template SHA matches authorized copy.  
   - ISO: A.12.1 (Operational procedures).  # SOC2: CC7.2

4. Using local admin credentials, run `terraform init` then `terraform apply` to create state bucket, lock store and KMS keys.  
   - Capture console logs, cloud audit IDs, resource ARNs.  
   - ISO: A.12.3 (Backup).  # SOC2: CC7.1

5. Upload signed backend lock (`.backend.lock` + `.backend.lock.asc`) to repo and to an append-only evidence store.  
   - ISO: A.10.1 (Cryptographic controls).  # SOC2: CC6.5

6. Create CI service accounts and configure OIDC/workload identity; deploy minimal runner. Rotate and store credentials in Vault.  
   - ISO: A.9.4 (System and application access control).  # SOC2: CC6.2

7. Run automated smoke tests and DR verification plan. Record outputs and make artifacts available to auditors.  
   - ISO: A.14.2 (Security in development).  # SOC2: CC5.1

8. Rotate emergency keys, revoke temporary access, and document the incident (timeline, evidence, mitigations). Store artifacts in evidence bucket.  
   - ISO: A.16.1 (Management of information security incidents).  # SOC2: CC4.1

## Evidence retention
- Store: signed lock, apply logs, operator attestations, resource ARNs, and key rotation logs.
- Retention policy: per legal/regulatory requirements (e.g., 7 years recommended) and immutable storage.

## Controls mapping (brief)
- Signing & locks → ISO A.10 / A.12.1 ; SOC2 CC6  
- Two-person rule → ISO A.9 / A.6 ; SOC2 CC6.4  
- Evidence retention → ISO A.12 / A.18 ; SOC2 CC8

