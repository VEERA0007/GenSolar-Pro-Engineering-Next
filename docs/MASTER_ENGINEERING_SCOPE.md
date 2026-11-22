# GenSolar Pro Engineering — Master EPC Engineering Scope

**Package edition:** 2026-11-22  
**Application:** `gensolar_pro_engineering`  
**Application architecture:** Flutter/Dart, offline-first, one versioned project record  
**Purpose:** make the full solar EPC lifecycle explicit, preserve every existing workspace, and prevent a user interface from claiming an engineering discipline is complete when only a screening calculation exists.

## 1. Application lifecycle

1. Lead/customer capture and project creation.
2. Site reconnaissance, site coordinates, survey evidence and utility information.
3. Roof/building/ground-mount survey and exclusion-zone definition.
4. Component catalogue and datasheet selection.
5. PV module layout, inverter allocation and DC/AC optimisation.
6. Solar resource, energy-yield, shade and loss modelling.
7. Mounting-structure design basis, wind actions, member, connection and foundation engineering.
8. DC electrical, AC electrical, protection, earthing, lightning, transformer and grid-interconnection design.
9. Battery, hybrid, off-grid, backup and solar-pumping applications.
10. CAD drawings, 3D/BIM model, SLD, cable routes and fabrication schedules.
11. BOM/BOQ, vendor RFQ, quotation comparison, purchase order and goods receipt.
12. Construction method statements, site QA/QC, HSE, inspections and non-conformance tracking.
13. Testing, commissioning, utility synchronization, performance verification and handover.
14. DPR, calculation notes, drawing register, document revision, approvals and operations/maintenance.

## 2. Modules already present in this source package

### Project and survey
- Project create, search, edit, switch and delete.
- Shared project JSON record, offline repository, backup/restore and update timestamps.
- Site coordinates, elevation, roof dimensions, tilt, setback, walkway and usable-area screening.
- Upstream changes mark dependent records/reports for review rather than deleting prior work.

### PV and solar resource
- Rectangular portrait/landscape module fit screening.
- Module quantity, DC capacity, footprint, spacing, setback, walkway and manual cell exclusions.
- Roof plan and conceptual isometric preview from the same saved layout data.
- DXF export for the rectangular roof/module grid.
- Annual energy and indicative monthly yield from supplied resource assumptions.
- New monthly POA yield calculator accepts twelve separate irradiation inputs, PR, losses and degradation.
- Inverter DC/AC ratio screening.

### Electrical and storage
- Existing PV string cold-Voc/MPPT/DC-cable screen.
- New single/three-phase AC voltage-drop calculation from entered R/X, current, length, PF and voltage-drop limit.
- Cable tray geometric fill screen.
- Transformer kVA screening from peak kW, PF, loading limit and margin.
- Power-factor correction kvar estimate.
- PV string overcurrent-device screening using entered Isc, factor, fuse, module maximum fuse and cable allowance.
- Cable ampacity derating using entered ambient, grouping and installation correction factors.
- Battery charge/discharge C-rate and DC current screen.
- Transformer impedance-only three-phase fault-current estimate.
- Rooftop PV/module/mounting average dead-load screen.
- Rectangular concrete volume and user-rate reinforcement quantity take-off.
- Battery usable/nominal energy sizing foundation.
- Earthing rod resistance approximation with soil resistivity and rod geometry.

### Structural, mechanical and civil
- Existing velocity-pressure awareness screen.
- New wind-factor input screen (K1–K4 entered by the user) with reference pressure and projected-force estimate.
- New simply supported mounting-rail beam UDL bending/deflection screen.
- New bolt-group direct shear distribution screen.
- New rectangular isolated-footing soil-pressure and concrete-volume screen.

### Applications and commercial
- Solar pump daily energy/PV-array estimate from daily volume, TDH, PSH and entered efficiencies.
- Financial cash-flow screening: first-year gross value, O&M, simple payback, NPV and discounted LCOE proxy.
- Existing BOM/BOQ budget workflow, supplier/PO record, QA checklist, commissioning/handover checklist, CAD and DPR project snapshots.

## 3. Advanced calculators in the new Engineering Library

Open **Modules → Advanced engineering library**. Calculations can be saved to the active project under `engineeringData.advancedEngineering.calculations`. Saving a new calculation marks an existing DPR snapshot as needing review.

| Calculator | Core equation / method | Main caveat |
|---|---|---|
| Monthly solar yield | DC kWp × POA irradiation × days × PR × (1 − loss) × degradation | No PVsyst/PV*SOL-equivalent weather or shade simulation |
| Inverter DC/AC | PV DC kWp ÷ inverter AC kW | Must check actual datasheet MPPT/current/voltage limits |
| AC cable voltage drop | 1φ: 2IL(R cosφ + X sinφ); 3φ: √3IL(R cosφ + X sinφ) | Does not check ampacity, grouping, fault current or protection |
| Transformer | kVA = kW/PF, adjusted for margin/loading | No impedance, vector group, losses, harmonics or utility review |
| Wind basis screen | Vd from entered factors; q = 0.6V²; F = qCfA | User must source factors; not a complete IS 875 design |
| Mounting rail | Simply-supported UDL M=wL²/8; δ=5wL⁴/384EI; σ=M/Z | No buckling, shear, connection, fatigue or load-combination checks |
| Bolt group | Direct shear divided equally by entered bolt count | No eccentricity, tension, bearing, tear-out or code design |
| Footing bearing | Linear pressure distribution for a rigid rectangle | No settlement, sliding, overturning, reinforcement or punching shear |
| Earth electrode | Approximate vertical-rod resistance in homogeneous soil | No mutual rod interaction, touch/step study or field verification |
| Solar pump | Hydraulic daily energy from volume × TDH; efficiency and PSH based array | No pump curve, pipe losses, well drawdown or controller envelope |
| Financial model | Escalated/degraded energy cash flows, NPV and LCOE proxy | No taxes, debt, replacements, incentives or lender model |
| Cable tray fill | Cable OD area ÷ usable tray area | No spacing, derating, bend radius or thermal check |
| Power-factor correction | Qc = P × [tan(cos⁻¹ PFexisting) − tan(cos⁻¹ PFtarget)] | No harmonic resonance, switching or detuning checks |
| PV protection | Isc × strings × entered design factor compared with fuse/module/cable input limits | No interrupt rating, fuse class or coordination |
| Cable ampacity | Base ampacity × user-entered ambient/grouping/installation factors | No code table, installation geometry or fault withstand |
| Battery C-rate | Charge/discharge kW ÷ nominal kWh | No BMS, cell or thermal validation |
| Transformer fault current | I rated = kVA/(√3 V); Isc ≈ I rated/(Z%/100) | Infinite source approximation; no X/R or cable contribution |
| Roof dead load | Equipment mass × g ÷ entered distributed area | No local roof member/slab design |
| Concrete/rebar take-off | L×B×D; volume × entered kg/m³ rate | Estimate only; no bar detailing/design |

All calculators persist: input values, metrics, formula text, assumptions, warning text, engine version and timestamp. The status is a calculation status only, never a legal or engineering approval.

## 4. Full discipline register — planned completion gates

A full EPC product needs the following capabilities in addition to the implemented screening tools. The register is intentionally specific; an item is not considered implemented because a card or tab exists.

### A. Geospatial, site and survey
- Native GPS permission, location accuracy and timestamp; manual override with source tag.
- Maps, satellite/terrain layers, north reference, site boundary and geospatial coordinate reference.
- Offline map packs, survey photos, annotated images, evidence attachments and chain of custody.
- Multiple buildings, roof zones, elevations, roof types, drainage, parapet, skylights, vents, HVAC and exclusion corridors.
- Polygon drawing/editing, self-intersection checks, area/centroid and coordinate transformations.

### B. PV design and energy
- Equipment catalogue with module/inverter datasheets, revision, manufacturer, Voc/Vmp/Isc/Imp, temperature coefficients and bifacial data.
- Module row/column placement on arbitrary polygons and multi-roof sites; portrait/landscape, tilt, azimuth, pitch, setbacks, fire paths and shading obstacles.
- Per-string allocation, inverter MPPT allocation, current windows, cold Voc, hot Vmp, clipping and DC/AC assessment.
- Source-backed GHI/DNI/DHI/GTI, plane-of-array transposition, temperature, horizon, albedo, bifaciality and monthly/hourly time series.
- Sun path, 3D obstacles, per-module shadow map, string mismatch, bypass-diode and yield-loss calculation with provenance.
- Energy balance, availability, curtailment, export limitation, self-consumption, battery dispatch and financial sensitivity.

### C. Structural, mechanical and civil
- Project wind design basis with applicable standard edition, location wind speed, risk/importance, terrain, height, topography, roof zone and internal/external pressure coefficients.
- Complete load cases/combinations and load transfer from module to clamp, rail, purlin, rafter, frame, anchor and foundation.
- Aluminium/steel section catalogues and verified section properties; bending, shear, axial, combined stress, buckling, local buckling, lateral torsional buckling, deflection and serviceability.
- Connection engineering: clamp, bolt, weld, bearing, tear-out, pull-out, pull-over, embedment, anchor group, concrete breakout and corrosion.
- Civil/geotechnical inputs: soil investigation, SBC, settlement, uplift, sliding, overturning, pile/ground-screw design, concrete and reinforcement schedules.
- Drawings: module clamp zones, rail spacing, purlin spacing, support frame, anchor details, footing/ pedestal, cut lists and fabrication drawings.

### D. Electrical, storage and grid
- Complete DC string design: corrected cell/module temperatures, maximum series voltage, current, MPPT allocation, parallel string current, connector and fuse limits.
- Cable ampacity with installation method, ambient/soil temperature, grouping, harmonic and short-circuit withstand derating.
- DC/AC isolators, fuses, MCB/MCCB/ACB, relays, SPD types, selectivity/coordination and interrupting ratings.
- AC cable, voltage rise/drop, transformer, HT/LT bus, fault level, protection settings, CT/PT, metering and SLD.
- Earthing grid, earth conductor thermal sizing, lightning risk assessment, bonding, touch/step voltage and test results.
- Battery chemistry, cell/rack/string topology, C-rate, BMS limits, thermal management, degradation, round-trip efficiency, dispatch and fire-safety requirements.
- Hybrid/off-grid operation modes, generator integration, islanding/anti-islanding, transfer logic, black start and grid-code compliance.
- Utility applications, approvals, synchronization tests, export limitation and metering documentation.

### E. CAD, 3D and document control
- Editable layered CAD entities, snapping, constraints, dimensions, blocks, symbols, annotation, scale and units.
- Robust DXF import/export round-trip. DWG/SKP support only through a licensed, tested converter.
- SLD editor, roof/equipment layout, cable routing, elevations, sections, mounting detail and fabrication sheets.
- Synchronized 3D model with inspectable object properties and 2D/3D revision link.
- PDF drawing sheets, DPR, calculation reports, revision comparison, approval/sign-off, document register and controlled transmittals.

### F. EPC delivery, commercial and operations
- Multi-vendor RFQ, technical/commercial bid tab, quotation comparison, PO approvals, partial receipts, inventory and invoice reconciliation.
- Resource-loaded schedules, activity dependencies, site diary, labour/equipment, progress photos, measurement book and delay/variation register.
- ITP, hold/witness points, NCR/CAPA, material inspection, torque log, megger/continuity/earth tests, IV curve, relay tests and commissioning records.
- HSE risk assessment, toolbox talk, permit to work, working at height, electrical isolation/LOTO and incident log.
- Plant monitoring: inverter/logger APIs, time-series telemetry, alarms, PR, performance ratio, availability, soiling and O&M schedule.
- User roles, customer/contractor/engineer separation, MFA, audit trail, encrypted cloud backup, synchronization and conflict resolution.

## 5. Architecture and data rules

- One project record is the root aggregate; workspace sections must never create unrelated project copies.
- Every saved result stores inputs, units, formula/engine version, assumptions, warnings, source references, author and timestamp.
- Upstream edits mark dependent calculations and reports stale. Stale results must not be shown as current/approved.
- Calculators are pure functions where possible; UI widgets only collect inputs and display outputs.
- All units must be explicit. Convert at the boundary; do not mix mm, m, N, kN, Pa, kPa, W, kW, Wh and kWh implicitly.
- All user-entered engineering constants must be editable and traceable to a named data source/datasheet/standard edition.
- Missing or invalid required inputs must return INCOMPLETE/REVIEW, not an invented pass.
- Keep the application offline-first. Network/map/cloud integrations are optional adapters; the core project editor and calculation history remain usable offline.
- Persisted project backups require schema versioning and migration tests.

## 6. Engineering approval and legal safety

The application is a workflow and engineering-calculation aid. It does not certify compliance, approve fabrication, issue a statutory drawing, provide a professional engineer's stamp, or replace authority/utility approval. Before any construction release, qualified engineers must independently verify calculations against the applicable standards and editions, manufacturer datasheets, site survey, soil report, environmental data and statutory requirements. The software must keep approval identity, review date, standard edition and signed evidence as separate fields.
