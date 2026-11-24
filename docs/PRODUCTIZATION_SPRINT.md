# GenSolar Pro Engineering Next — Productization sprint

Date: 24 November 2026  
Branch: `feat/epc-productization-and-ux`

## Verified starting point
- Baseline commit: `555b05e14abc06adab3381fcbd19c79a4f7337f3`.
- Latest baseline CI run: [45219956216](https://github.com/VEERA0007/GenSolar-Pro-Engineering-Next/actions/runs/45219956216), successful for analysis/tests and Android APK, Web, Linux, Windows, macOS and unsigned iOS.
- The source is an offline-first Flutter/Dart EPC MVP, not a certified or production enterprise system.

## Product capabilities already present
Projects and offline storage; survey inputs; rectangular PV layout; yield estimation; preliminary DC electrical and battery sizing; wind screening; BOM/BOQ; supplier/procurement record; QA and commissioning checklists; conceptual 2D/3D plan; DXF export; PDF/JSON/text project snapshots; 19 advanced screening calculators; cross-platform CI.

## High-priority gaps to implement
1. **Site capture and geometry:** GPS permissions/capture, maps, evidence/photos, multiple roof zones, polygon edges, obstructions, setbacks and fire/access corridors.
2. **PV and yield:** manufacturer equipment catalogue, source-attributed weather/irradiance, monthly resource profile, shading and string mismatch.
3. **Engineering design:** controlled IS 875 Part 3 basis and load combinations; structural member/connection/anchor/foundation checks; complete DC/AC protections, earthing, lightning, transformer and utility SLD.
4. **CAD/3D:** editable entities/layers/dimensions, DXF import and round-trip tests, cable routes, elevations, SLD, fabrication sheets and synchronized 3D.
5. **EPC operations:** multi-vendor RFQ comparison, purchase-order lines, receipts, inventory, photo-based QA/NCRs, commissioning test sheets and handover evidence.
6. **Enterprise services:** authenticated roles, encrypted transactional data, schema migrations, cloud sync/conflict resolution, audit logs and revision-controlled approvals.
7. **Release quality:** robust automated tests, responsive UI tests, physical-device permission/offline/file tests, signed Android/iOS release pipelines and release monitoring.

## Guardrails
- Do not report a screening estimate as code-compliant, approved or certified.
- Every engineering output must identify units, inputs, formula/version, assumptions, source and review state.
- Missing source data or incomplete safety checks must produce REVIEW, not PASS.
- Do not add API keys, signing credentials, service-account JSON or customer data to source control.

## Sprint completion evidence
This document records a productization scope and verified baseline. It does not claim the full requirements are implemented. Completion is measured by merged code, passing tests, platform artifacts and the owner-specific integration inputs in `docs/PROJECT_INPUTS_TO_CONFIRM.md`.
