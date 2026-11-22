# GenSolar Pro Engineering — delivery status

**Source:** new Flutter/Dart codebase, separate from the earlier Kotlin/WebView repository.

## Improvements in this update

- Reworked the dashboard, application shell, navigation and module directory into a consistent Material 3 responsive design.
- Kept all top-level screens mounted in an `IndexedStack`, retaining form state when navigating between destinations.
- Added a clickable 10-stage project delivery rail inside the engineering workspace.
- Added `Save & continue` actions to calculation tabs, `Continue to CAD` on delivery and `Continue to DPR` on the CAD view.
- Linked project survey dimensions into PV layout defaults; saved PV capacity into yield; PV module quantity into electrical string suggestions and BOM; survey roof area into wind screening; electrical cable length and PV module details into BOM.
- Added downstream `needsReview` invalidation when an upstream section or project metadata changes, including CAD/DPR snapshots; saved values remain for the user to verify.
- Prevented invalid cross-field calculations and impossible PV geometry from being saved as current results.
- Added validation for the procurement record and rollback behavior when a checklist write fails.
- Serialized local repository reads/writes/imports/deletes to avoid races between refresh and persistence.
- Updated backup restore to use the file-picker 13 API, including nullable file-length handling.
- Added 2D roof plan and isometric concept visualizations using the same PV layout / exclusion indexes.
- Added workflow dependency regression tests, including CAD/DPR staleness and evidence-based project status.

## Implemented EPC MVP scope

- Responsive Flutter / Dart application shell for Android, iOS, Web, Windows, macOS and Linux targets.
- Dashboard, project create/list/delete, active project switch and offline local project persistence.
- JSON backup export and restore from file or pasted JSON.
- Site survey inputs and area/slope/usable-footprint calculation.
- Rectangular PV module layout, portrait/landscape comparison, module count/capacity/area, manual module exclusions, DXF export, 2D and concept isometric preview.
- Specific-yield / performance-ratio / loss / tariff annual generation estimate and indicative monthly chart.
- Cold Voc, MPPT window and simplified DC copper voltage-drop screening.
- Battery usable/nominal energy and nominal Ah estimate with reserve visualization.
- Basic wind velocity-pressure/effective-force screening.
- Rate-based material quantity and budget calculation.
- One primary supplier / PO record, construction QA checklist, commissioning / handover checklist.
- Project PDF and text report snapshot.
- Tests for core calculations, data serialization and downstream section review propagation.

## Platform and test verification state

This source-building container does not have the Flutter or Dart SDK, and outbound package-host access is unavailable. Therefore no local claim is made that `flutter pub get`, `dart format`, `flutter analyze`, `flutter test` or platform builds have passed here. `.github/workflows/build.yml` is configured to run formatting, analysis, tests, and individual Android/iOS/Web/Windows/macOS/Linux jobs after the source is pushed. The resulting GitHub workflow must be inspected before treating any artifact as build-verified.

## Not yet implemented / release-blocking scope

- Arbitrary multi-roof polygons, roof zones, obstacles, fire/access corridors and automatic multi-zone allocation.
- Live device GPS, map provider integration, offline maps and survey photo/evidence handling.
- Source-backed weather/resource service, validated monthly yield, sun-position and time-series/module-level shade modelling.
- Full editable CAD entity/layer/dimension tools, DXF import and drawing-sheet release; licensed DWG/SKP support.
- Full synchronized engineering 3D model. The isometric drawing is a conceptual visualization only.
- Complete IS 875 Part 3 structural design, load combinations, member/connection/foundation checks and engineer sign-off.
- Full electrical protection, current allocation, cable ampacity, fault current, AC systems, earthing, lightning and utility SLD/interconnection.
- Manufacturer/catalogue-backed battery and hybrid systems, BMS and dispatch modelling.
- Full multi-vendor procurement, RFQ comparisons, purchase orders, goods receipts, invoice reconciliation and inventory.
- Transactional database, migrations, encryption, authentication, role permissions, cloud synchronization, audit trail and conflict resolution.
- Controlled DPR revision, document evidence, professional sign-off, store signing and device testing.

Do not represent the current package as a complete enterprise EPC system or engineering-certified design release. Structural/electrical/financial and construction outputs require project-specific validated inputs, applicable standards, manufacturer documentation and qualified professional review.

## Advanced engineering library added in package revision 2026-11-22

The **Modules → Advanced engineering library** route adds 19 project-persisted calculators: monthly POA energy, inverter DC/AC allocation, AC cable voltage drop, transformer capacity, wind basis factors, mounting rail beam, bolt-group direct shear, footing soil bearing, earth rod resistance, solar pump energy, financial cash flow, cable-tray fill, power-factor correction, PV string protection, cable ampacity derating, battery C-rate, transformer fault-current, rooftop dead-load, and concrete/rebar quantity. Each result stores inputs, formula, assumptions, warnings, timestamp and engine version in the active project; editing a result marks an existing DPR snapshot for review. A regression test file covers core cases for these calculators with 17 focused advanced-engineering tests.

This does not remove the enterprise gaps listed above. The master register in `MASTER_ENGINEERING_SCOPE.md` and project-owner decisions in `PROJECT_INPUTS_TO_CONFIRM.md` are the definitive scope documents. The additional calculators are deliberately labelled screening/estimate tools; they do not certify compliance or replace full IS/IEC/IEEE design and professional sign-off.
