# GenSolar Pro Engineering — delivery gates

This roadmap is the working release checklist for the Next Flutter/Dart repository.

## Gate 0 — verified baseline
- [x] Flutter/Dart source is separate from the earlier Kotlin/WebView project.
- [x] Offline-first project records and connected EPC workflow exist.
- [x] Core solar calculations and advanced screening calculators exist.
- [x] Baseline CI completed successfully for analysis/tests and six targets on 23 November 2026.
- [ ] Confirm every baseline artifact is downloadable and installable on representative devices.

## Gate 1 — field-ready survey
- [ ] GPS capture with permission denial/grant handling and manual coordinate fallback.
- [ ] Map view with selectable location, map attribution and offline-safe fallback.
- [ ] Survey photos, document evidence, timestamps and project association.
- [ ] Multiple roof zones and polygon/obstruction/fire-access geometry.
- [ ] Survey measurement validation and source/evidence register.

## Gate 2 — validated PV engineering
- [ ] Manufacturer/model catalogue with versioned datasheets.
- [ ] Source-attributed weather and monthly irradiation import.
- [ ] Multi-zone placement, inter-row shading, obstacle and walkway handling.
- [ ] String-level MPPT current/voltage and module mismatch validation.
- [ ] Reference test vectors and independent calculation validation.

## Gate 3 — professional design checks
- [ ] Configurable applicable standards and edition register.
- [ ] IS 875 Part 3 wind design inputs, terrain/topography, height and roof zones.
- [ ] Load combinations and verified member, connection, anchor and foundation checks.
- [ ] Full DC/AC cable ampacity/drop/fault/protection coordination.
- [ ] Earthing, lightning, transformer, utility interconnection and SLD.
- [ ] Engineer review/sign-off gate with no auto-promotion from screening to approval.

## Gate 4 — CAD and project controls
- [ ] Editable layers/entities/dimensions and snap/selection/edit tools.
- [ ] DXF import/export round-trip and dimensional regression tests.
- [ ] Cable routing, elevations, sections, SLD, fabrication sheets and synced 3D.
- [ ] Multi-vendor RFQ, quote comparison, PO line items, receipts and inventory.
- [ ] Work schedules, QA inspection evidence, NCRs, commissioning and handover.

## Gate 5 — enterprise and release
- [ ] Secure authentication and role-based access.
- [ ] Transactional encrypted database, schema migrations, audit history.
- [ ] Cloud sync, conflict handling and offline recovery.
- [ ] Revision controlled DPR/drawing packages, approvals and signatures.
- [ ] Android/iOS signing, app store packaging and device validation.
- [ ] Independent security, engineering and usability review.

## Release evidence
A gate is complete only when implementation, automated tests, platform build evidence and documented limitations are present. A green CI build alone does not certify engineering outputs or complete a product gate.
