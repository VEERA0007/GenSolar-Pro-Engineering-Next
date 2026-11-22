# Implementation plan — from clean clone to verified release

## Phase 0 — initialise
- Create the empty GitHub repository `GenSolar-Pro-Engineering-Next`.
- Push this complete source tree to `main`.
- Pin Flutter 3.50.0 stable and Dart 3.14.0; CI must report the exact installed versions.
- Resolve dependencies, run formatter, analyzer and tests before enabling platform builds.

## Phase 1 — quality and core data
- Resolve all analyzer warnings and runtime exceptions.
- Add database migrations, crash-safe writes, backup validation, export schema and repository contract tests.
- Add project audit events and optimistic revision checks.
- Add localization, unit preferences and accessibility checks.

## Phase 2 — site and geospatial
- Implement live GPS capture with permission state and accuracy metadata.
- Add site map, coordinate system, survey images and offline map adapter.
- Implement multiple building/roof zones and arbitrary polygon editing with topology validation.
- Add obstacle/exclusion geometry, roof elevations, slope and roof-type materials.

## Phase 3 — complete PV and solar model
- Add manufacturer equipment catalogue and versioned datasheets.
- Implement portrait/landscape and multi-roof optimizer; preserve manual placement overrides.
- Add inverter MPPT/current/voltage mapping, module temperature correction and clipping.
- Add licensed/source-attributed weather and POA model, monthly/hourly yield, time-series shadow and string mismatch engine.
- Verify against known reference cases from the qualified engineering team.

## Phase 4 — engineering design
- Structural: standards edition/configuration, load cases, wind zones, structural solver validation, member/connection/foundation design and drawings.
- Electrical: full DC/AC design, ampacity, fault current, protection coordination, transformer, earthing/lightning, SLD and utility packages.
- Battery/hybrid: catalogue/BMS, C-rate, dispatch, thermal and safety checks.
- Civil: geotechnical database, foundations, concrete/rebar and ground mounting.
- Every discipline includes units, source data, validation fixture, limitations and engineer review gate.

## Phase 5 — CAD and deliverables
- Build editable CAD document model with layers, entities, snapping, dimensions, annotations and undo/redo.
- Test DXF import/export round trip. Add DWG/SKP only after licensed SDK approval.
- Build synchronized 3D model and project drawing sheets.
- DPR generated from a locked project revision and referenced calculation results; support review comments, signatures and controlled issue.

## Phase 6 — EPC operations
- Multi-vendor RFQ, comparative statement, PO approvals, goods receipts, inventory and invoice reconciliation.
- Construction work packages, method statement, schedule, daily progress, QA/QC, NCR/CAPA and inspection hold points.
- HSE risk register, permit to work, toolbox talks, isolation/LOTO and incident reporting.
- Commissioning, utility synchronization, performance verification and digital handover.
- O&M tickets, preventive maintenance, telemetry ingestion, alarms and KPI trends.

## Phase 7 — platform and cloud
- Cloud backend with tenancy, role/permission matrix, MFA, encrypted storage, audit history and conflict-safe sync.
- Confirm Android, iOS, Web, Windows, macOS and Linux builds individually.
- Create signed release profiles only using approved secrets and platform accounts.
- Run device/browser tests, screen-reader checks, offline/online transition tests and upgrade migration tests.

## Completion rules
- A module is complete only after implementation, integration, tests, documentation and acceptance evidence.
- A build is verified only when the current GitHub Actions run completed and its artifact record is inspected.
- A calculation is approved only when the applicable engineering review and sign-off are recorded.
- Never call an unsigned debug APK a store release; never claim all platforms passed based on one platform.
