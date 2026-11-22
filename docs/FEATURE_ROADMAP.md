# GenSolar Pro Engineering — implementation status and release roadmap

This checklist applies only to the new Flutter/Dart source package. A checked item means a working implementation exists in this source tree; it does not imply engineering certification or successful multi-platform CI.

## Implemented in the current source

- [x] Responsive Flutter / Dart Material 3 application shell with phone/tablet/desktop navigation.
- [x] Dashboard with portfolio metrics, project pipeline, quick actions and recent project selection.
- [x] Project create/search/edit/list/delete, active-project switching and project-scoped engineering data; project-level target/site edits flag dependent sections.
- [x] Offline local repository with serialized reads/writes/import/delete operations.
- [x] JSON backup export/import with schema, size, count and record validation.
- [x] Survey inputs and rectangular roof footprint / slope / preliminary usable-area calculations.
- [x] Rectangular PV portrait/landscape grid estimate, capacity, module count and manual cell exclusion.
- [x] Survey → PV → yield/electrical/BOM data prefill links.
- [x] Downstream review propagation when saved upstream project inputs change.
- [x] Clickable 10-step EPC workflow rail and Save & continue navigation; CAD/DPR capture is tied to export actions and stale snapshots remain in REVIEW.
- [x] Yield estimate and explicitly illustrative monthly distribution chart.
- [x] Cold-corrected string Voc, MPPT window and simplified DC cable voltage-drop screening.
- [x] Battery usable/nominal energy, Ah estimate and reserve visualization.
- [x] Basic wind pressure/force screening with required structural engineering review.
- [x] PV/electrical-linked budget BOM/BOQ calculation.
- [x] One primary supplier/RFQ/PO record, delivery status and project QA/commissioning checklists.
- [x] 2D roof-plan preview, conceptual isometric roof preview and metre-unit DXF export.
- [x] Project PDF/text/JSON report snapshots.
- [x] Unit tests for project serialization, calculation functions and workflow dependency propagation.
- [x] GitHub Actions validate/test and six-target platform build matrix.
- [x] Advanced engineering library route available from Modules with 19 engineering/commercial screening calculators.
- [x] Monthly POA yield, inverter DC/AC, AC voltage drop, transformer, wind-factor, mounting rail, bolt direct shear, footing bearing, earth rod, solar pump, finance, cable tray and power-factor correction calculators.
- [x] Advanced calculation records persist to the active project with inputs, results, formula, assumptions, warnings and engine version; report snapshots are marked stale when calculations change.
- [x] Extra electrical, battery, roof-load and civil take-off screens: PV fuse, cable ampacity, battery C-rate, transformer fault level, rooftop dead load, concrete and rebar quantity.

## Remaining product implementation

### Survey and geometry
- [ ] Multiple independent roof zones with stable IDs and shared project coordinates.
- [ ] Arbitrary polygon roof boundaries, obstacles, parapets, fire/access corridors and elevations.
- [ ] Device GPS capture, map layers, offline tiles, survey photos, document evidence and calibrated measuring-device integrations.

### Solar and PV engineering
- [ ] Equipment catalogues with manufacturer/model/datasheet revisions and controlled electrical characteristics.
- [ ] Multi-zone automatic/manual module placement with orientation, row pitch, setbacks, fire access and obstruction handling.
- [ ] Source-attributed solar resource/weather API, traceable monthly profile, performance ratio and loss model.
- [ ] Sun position, horizon and time-series shading; per-module/per-string shade mismatch and validated reference cases.

### CAD and 3D
- [ ] Complete editable CAD entity/layer/dimension model, snapping and selection/editing tools.
- [ ] Robust DXF import and round-trip tests, PDF/image underlays, dimensions, cable routes, elevations, sections, SLD and fabrication drawings.
- [ ] Synchronized building/roof/module/rail/obstacle 3D scene, 2D/3D data exchange and drawing sheets.
- [ ] DWG/SKP support only after a licensed and verified converter has been selected.

### Structural and electrical engineering
- [ ] Controlled IS 875 Part 3 design workflow, terrain/topography/height, roof pressure zones, coefficients and load combinations.
- [ ] Structural member, connection, anchor and foundation checks with controlled material/section properties and engineer sign-off.
- [ ] Full PV inverter allocation, MPPT current, cable ampacity/voltage drop, fault current, protection coordination, earthing, lightning, transformer and utility interface.
- [ ] Battery chemistry, C-rate, temperature, ageing, BMS, surge and hybrid dispatch modelling from manufacturer documents.

### EPC operations and production readiness
- [ ] Multi-vendor RFQ, normalized quotation comparison, approval, purchase-order lines, staged goods receipts, invoice reconciliation and inventory.
- [ ] Construction schedules, inspection test plans, photo evidence, NCR/punch-list and approval history.
- [ ] Commissioning test sheets, measured values, warranties, customer acceptance and controlled handover.
- [ ] Revision-frozen DPR/drawing pack, traceable formulas, source citations and professional signatures.
- [ ] Transactional encrypted database, migrations, authentication, roles, audit log, cloud sync and merge conflict resolution.
- [ ] Platform permission integration, physical-device QA, signing, store packaging and release monitoring.

## Release gates

1. `dart format --output=none --set-exit-if-changed lib test`.
2. `flutter analyze --fatal-warnings`.
3. `flutter test --reporter expanded`.
4. Build each target on its supported runner and retain only successful artifacts.
5. Install and test on physical Android/iOS devices: offline launch, file import/export, local persistence, relaunch, rotation, permission denial/grant and backup restore.
6. Validate calculations against manufacturer datasheets, controlled engineering reference examples and applicable standards.
7. Keep incomplete or unverified outcomes in REVIEW; require qualified professional sign-off before structural, electrical, statutory, procurement or construction release.

A successful CI run proves only the configured code checks and build tasks. It does not certify a solar design, structural calculation, protection scheme, construction method or utility approval.
