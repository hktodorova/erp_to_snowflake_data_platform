# ADR 0001: Data Vault Core with Dimensional Marts

## Status
Accepted

## Context
The ERP platform must support auditability, late-arriving changes, history tracking and business-friendly reporting. A pure star schema is easier for BI but weaker for historized source integration. A pure Data Vault is auditable but less convenient for analysts.

## Decision
Use Data Vault 2.0 for the core integration layer and publish dimensional marts for BI and executive consumption.

## Consequences
- Raw and vault layers preserve source lineage and replayability.
- Mart models remain optimized for reporting and semantic clarity.
- The project requires clear naming standards, hash key consistency and contract tests.
