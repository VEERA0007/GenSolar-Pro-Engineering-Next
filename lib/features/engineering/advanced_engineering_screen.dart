import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/engineering/advanced_engineering.dart';
import '../../core/models/solar_project.dart';
import '../../core/providers.dart';

class _FieldSpec {
  const _FieldSpec(this.key, this.label, this.unit, this.initial, {this.integer = false, this.toggle = false});
  final String key, label, unit;
  final double initial;
  final bool integer, toggle;
}

class _CalcSpec {
  const _CalcSpec({required this.key, required this.title, required this.group, required this.description, required this.fields, required this.calculate});
  final String key, title, group, description;
  final List<_FieldSpec> fields;
  final AdvancedEngineeringResult Function(Map<String, double> v) calculate;
}

final _calculators = <_CalcSpec>[
  _CalcSpec(key:'solar_resource',title:'Monthly solar energy',group:'Solar resource',description:'Estimate monthly energy from a user-supplied plane-of-array irradiation profile, PR and losses.',fields:[
    const _FieldSpec('dcKwp','Installed DC capacity','kWp',100),
    ...List.generate(12,(i)=>_FieldSpec('poa${i+1}','Month ${i+1} POA irradiation','kWh/m²/day',i==5||i==6?4.5:5.2)),
    const _FieldSpec('performanceRatioPercent','Performance ratio','%',80),const _FieldSpec('additionalLossPercent','Additional loss','%',3),const _FieldSpec('degradationPercent','Annual degradation','%',.5),const _FieldSpec('operatingYear','Operating year','years',1,integer:true),
  ],calculate:(v)=>AdvancedEngineering.solarMonthlyYield(dcKwp:v['dcKwp']!,monthlyPoaKwhM2Day:List.generate(12,(i)=>v['poa${i+1}']!),performanceRatioPercent:v['performanceRatioPercent']!,additionalLossPercent:v['additionalLossPercent']!,degradationPercent:v['degradationPercent']!,operatingYear:v['operatingYear']!.round())),
  _CalcSpec(key:'inverter_sizing',title:'Inverter DC/AC allocation',group:'PV equipment',description:'Compare connected PV DC capacity with inverter AC rating and a project-defined ratio range.',fields:[const _FieldSpec('dcKwp','PV DC capacity','kWp',100),const _FieldSpec('acKw','Inverter AC rating','kW',80),const _FieldSpec('minimumRatio','Minimum DC/AC ratio','x',1),const _FieldSpec('maximumRatio','Maximum DC/AC ratio','x',1.5)],calculate:(v)=>AdvancedEngineering.inverterDcAc(dcKwp:v['dcKwp']!,acKw:v['acKw']!,minimumRatio:v['minimumRatio']!,maximumRatio:v['maximumRatio']!)),
  _CalcSpec(key:'ac_cable',title:'AC cable voltage drop',group:'Electrical',description:'Single/three-phase steady-state voltage-drop estimate using cable R and X at design temperature.',fields:[const _FieldSpec('currentA','Load current','A',125),const _FieldSpec('lengthM','One-way cable length','m',80),const _FieldSpec('voltageV','Nominal line voltage','V',415),const _FieldSpec('powerFactor','Power factor','',.95),const _FieldSpec('resistanceOhmPerKm','Conductor resistance','Ω/km',.25),const _FieldSpec('reactanceOhmPerKm','Conductor reactance','Ω/km',.08),const _FieldSpec('threePhase','Three-phase circuit (1=yes, 0=no)','1 / 0',1,toggle:true),const _FieldSpec('projectLimitPercent','Project voltage-drop criterion','%',3)],calculate:(v)=>AdvancedEngineering.acCableDrop(currentA:v['currentA']!,lengthM:v['lengthM']!,voltageV:v['voltageV']!,powerFactor:v['powerFactor']!,resistanceOhmPerKm:v['resistanceOhmPerKm']!,reactanceOhmPerKm:v['reactanceOhmPerKm']!,threePhase:v['threePhase']!>=.5,projectLimitPercent:v['projectLimitPercent']!)),
  _CalcSpec(key:'transformer',title:'Transformer capacity',group:'Electrical',description:'Estimate kVA requirement from peak demand, PF, loading limit and design margin.',fields:[const _FieldSpec('maximumDemandKw','Maximum demand','kW',150),const _FieldSpec('powerFactor','Power factor','',.95),const _FieldSpec('loadingLimitPercent','Maximum design loading','%',80),const _FieldSpec('marginPercent','Design margin','%',15)],calculate:(v)=>AdvancedEngineering.transformerSizing(maximumDemandKw:v['maximumDemandKw']!,powerFactor:v['powerFactor']!,loadingLimitPercent:v['loadingLimitPercent']!,marginPercent:v['marginPercent']!)),
  _CalcSpec(key:'wind_basis',title:'Wind design-basis screen',group:'Structural & mounting',description:'Apply user-entered wind factors and force coefficient. Factor selection and complete IS 875 design remain engineer responsibilities.',fields:[const _FieldSpec('basicWindSpeedMps','Basic wind speed','m/s',44),const _FieldSpec('k1','Risk factor K1','',1),const _FieldSpec('k2','Terrain/height factor K2','',1),const _FieldSpec('k3','Topography factor K3','',1),const _FieldSpec('k4','Importance factor K4','',1),const _FieldSpec('forceCoefficient','Force coefficient Cf','',1.2),const _FieldSpec('effectiveAreaM2','Effective projected area','m²',100)],calculate:(v)=>AdvancedEngineering.windBasis(basicWindSpeedMps:v['basicWindSpeedMps']!,k1:v['k1']!,k2:v['k2']!,k3:v['k3']!,k4:v['k4']!,forceCoefficient:v['forceCoefficient']!,effectiveAreaM2:v['effectiveAreaM2']!)),
  _CalcSpec(key:'mounting_rail',title:'Mounting rail beam',group:'Structural & mounting',description:'Simply-supported beam under a full-span uniform load. Use verified section properties and allowable stress.',fields:[const _FieldSpec('loadNPerM','Uniform design load','N/m',1000),const _FieldSpec('spanM','Clear span','m',1.5),const _FieldSpec('elasticModulusMpa','Elastic modulus','MPa',69000),const _FieldSpec('inertiaMm4','Second moment of area','mm⁴',500000),const _FieldSpec('sectionModulusMm3','Section modulus','mm³',12000),const _FieldSpec('allowableStressMpa','Entered allowable stress','MPa',150),const _FieldSpec('deflectionRatio','Deflection limit L/','',180)],calculate:(v)=>AdvancedEngineering.railBeam(loadNPerM:v['loadNPerM']!,spanM:v['spanM']!,elasticModulusMpa:v['elasticModulusMpa']!,inertiaMm4:v['inertiaMm4']!,sectionModulusMm3:v['sectionModulusMm3']!,allowableStressMpa:v['allowableStressMpa']!,deflectionRatio:v['deflectionRatio']!)),
  _CalcSpec(key:'bolt_group',title:'Bolt group direct shear',group:'Structural & mounting',description:'Equal direct shear distribution only; connection eccentricity and combined actions are not included.',fields:[const _FieldSpec('totalShearKn','Total shear','kN',12),const _FieldSpec('boltCount','Number of bolts','Nos',4,integer:true),const _FieldSpec('allowableShearPerBoltKn','Entered allowable shear per bolt','kN',8)],calculate:(v)=>AdvancedEngineering.boltShear(totalShearKn:v['totalShearKn']!,boltCount:v['boltCount']!.round(),allowableShearPerBoltKn:v['allowableShearPerBoltKn']!)),
  _CalcSpec(key:'foundation',title:'Foundation bearing screen',group:'Civil & foundation',description:'Rectangular footing pressure estimate with vertical load and biaxial moments; not a full footing design.',fields:[const _FieldSpec('verticalLoadKn','Vertical load','kN',80),const _FieldSpec('momentXKnM','Moment about X','kN·m',3),const _FieldSpec('momentYKnM','Moment about Y','kN·m',2),const _FieldSpec('lengthM','Footing length','m',1.5),const _FieldSpec('widthM','Footing width','m',1.5),const _FieldSpec('depthM','Footing depth','m',.6),const _FieldSpec('safeBearingKpa','Geotechnical safe bearing capacity','kPa',150)],calculate:(v)=>AdvancedEngineering.footingBearing(verticalLoadKn:v['verticalLoadKn']!,momentXKnM:v['momentXKnM']!,momentYKnM:v['momentYKnM']!,lengthM:v['lengthM']!,widthM:v['widthM']!,depthM:v['depthM']!,safeBearingKpa:v['safeBearingKpa']!)),
  _CalcSpec(key:'earthing',title:'Earth electrode resistance',group:'Electrical safety',description:'Homogeneous-soil vertical rod estimate. Actual system must be measured and checked for touch/step voltage.',fields:[const _FieldSpec('soilResistivityOhmM','Soil resistivity','Ω·m',100),const _FieldSpec('rodLengthM','Rod length','m',3),const _FieldSpec('rodDiameterMm','Rod diameter','mm',16),const _FieldSpec('rodCount','Number of rods','Nos',4,integer:true)],calculate:(v)=>AdvancedEngineering.earthingRod(soilResistivityOhmM:v['soilResistivityOhmM']!,rodLengthM:v['rodLengthM']!,rodDiameterMm:v['rodDiameterMm']!,rodCount:v['rodCount']!.round())),
  _CalcSpec(key:'solar_pump',title:'Solar water pump',group:'Solar applications',description:'Estimate hydraulic energy requirement and PV array size from daily volume and total dynamic head.',fields:[const _FieldSpec('dailyVolumeM3','Daily water volume','m³/day',50),const _FieldSpec('totalDynamicHeadM','Total dynamic head','m',30),const _FieldSpec('peakSunHours','Peak sun hours','h/day',5),const _FieldSpec('pumpEfficiencyPercent','Pump wire-to-water efficiency','%',55),const _FieldSpec('arrayDeratePercent','PV array derate','%',80)],calculate:(v)=>AdvancedEngineering.solarPump(dailyVolumeM3:v['dailyVolumeM3']!,totalDynamicHeadM:v['totalDynamicHeadM']!,peakSunHours:v['peakSunHours']!,pumpEfficiencyPercent:v['pumpEfficiencyPercent']!,arrayDeratePercent:v['arrayDeratePercent']!)),
  _CalcSpec(key:'financial',title:'Project financial model',group:'Commercial & finance',description:'Indicative cash-flow, simple payback, NPV and discounted LCOE proxy.',fields:[const _FieldSpec('annualGenerationKwh','Annual generation','kWh',150000),const _FieldSpec('tariffInrKwh','Energy value / tariff','₹/kWh',8),const _FieldSpec('projectCostInr','Project cost','₹',3500000),const _FieldSpec('omPercent','Annual O&M','% of capex',1),const _FieldSpec('degradationPercent','Annual degradation','%',.5),const _FieldSpec('tariffEscalationPercent','Annual tariff escalation','%',3),const _FieldSpec('discountRatePercent','Discount rate','%',10),const _FieldSpec('years','Analysis period','years',25,integer:true)],calculate:(v)=>AdvancedEngineering.financial(annualGenerationKwh:v['annualGenerationKwh']!,tariffInrKwh:v['tariffInrKwh']!,projectCostInr:v['projectCostInr']!,omPercent:v['omPercent']!,degradationPercent:v['degradationPercent']!,tariffEscalationPercent:v['tariffEscalationPercent']!,discountRatePercent:v['discountRatePercent']!,years:v['years']!.round())),
  _CalcSpec(key:'cable_tray',title:'Cable tray fill',group:'Electrical',description:'Geometric fill screening from entered cable OD and usable tray dimensions.',fields:[const _FieldSpec('cableCount','Cable count','Nos',12,integer:true),const _FieldSpec('cableOdMm','Cable outside diameter','mm',22),const _FieldSpec('trayWidthMm','Tray usable width','mm',300),const _FieldSpec('trayHeightMm','Tray usable height','mm',75),const _FieldSpec('fillLimitPercent','Project fill limit','%',40)],calculate:(v)=>AdvancedEngineering.cableTrayFill(cableCount:v['cableCount']!.round(),cableOdMm:v['cableOdMm']!,trayWidthMm:v['trayWidthMm']!,trayHeightMm:v['trayHeightMm']!,fillLimitPercent:v['fillLimitPercent']!)),
  _CalcSpec(key:'power_factor',title:'Power-factor correction',group:'Electrical',description:'Estimate capacitor kvar needed to move from existing PF to the requested target PF.',fields:[const _FieldSpec('activePowerKw','Active power','kW',150),const _FieldSpec('existingPf','Existing power factor','',.78),const _FieldSpec('targetPf','Target power factor','',.98)],calculate:(v)=>AdvancedEngineering.powerFactorCorrection(activePowerKw:v['activePowerKw']!,existingPf:v['existingPf']!,targetPf:v['targetPf']!)),
  _CalcSpec(key:'pv_protection',title:'PV string protection',group:'Electrical safety',description:'Compare array current basis, selected fuse rating, module maximum-series-fuse and entered cable allowable current.',fields:[const _FieldSpec('moduleIscA','Module Isc','A',14),const _FieldSpec('parallelStrings','Parallel strings','Nos',4,integer:true),const _FieldSpec('designCurrentFactor','Design current factor','x',1.25),const _FieldSpec('selectedFuseRatingA','Selected fuse rating','A',25),const _FieldSpec('moduleMaximumSeriesFuseA','Module max series fuse','A',30),const _FieldSpec('cableAllowableCurrentA','Cable allowable current','A',32)],calculate:(v)=>AdvancedEngineering.pvProtectionScreen(moduleIscA:v['moduleIscA']!,parallelStrings:v['parallelStrings']!.round(),designCurrentFactor:v['designCurrentFactor']!,selectedFuseRatingA:v['selectedFuseRatingA']!,moduleMaximumSeriesFuseA:v['moduleMaximumSeriesFuseA']!,cableAllowableCurrentA:v['cableAllowableCurrentA']!)),
  _CalcSpec(key:'cable_ampacity',title:'Cable ampacity derating',group:'Electrical',description:'Apply entered ambient, grouping and installation correction factors to a base cable ampacity.',fields:[const _FieldSpec('designCurrentA','Design current','A',125),const _FieldSpec('baseAmpacityA','Base cable ampacity','A',180),const _FieldSpec('ambientFactor','Ambient correction factor','x',.91),const _FieldSpec('groupingFactor','Grouping correction factor','x',.8),const _FieldSpec('installationFactor','Installation correction factor','x',1)],calculate:(v)=>AdvancedEngineering.cableAmpacityDerating(designCurrentA:v['designCurrentA']!,baseAmpacityA:v['baseAmpacityA']!,ambientFactor:v['ambientFactor']!,groupingFactor:v['groupingFactor']!,installationFactor:v['installationFactor']!)),
  _CalcSpec(key:'battery_c_rate',title:'Battery C-rate and current',group:'Battery & storage',description:'Compare requested charge/discharge power with entered battery energy, voltage and C-rate limits.',fields:[const _FieldSpec('nominalEnergyKwh','Nominal battery energy','kWh',200),const _FieldSpec('chargePowerKw','Maximum charge power','kW',50),const _FieldSpec('dischargePowerKw','Maximum discharge power','kW',100),const _FieldSpec('dcVoltageV','Nominal DC voltage','V',512),const _FieldSpec('maximumChargeC','Maximum charge C-rate','C',.5),const _FieldSpec('maximumDischargeC','Maximum discharge C-rate','C',1)],calculate:(v)=>AdvancedEngineering.batteryCRate(nominalEnergyKwh:v['nominalEnergyKwh']!,chargePowerKw:v['chargePowerKw']!,dischargePowerKw:v['dischargePowerKw']!,dcVoltageV:v['dcVoltageV']!,maximumChargeC:v['maximumChargeC']!,maximumDischargeC:v['maximumDischargeC']!)),
  _CalcSpec(key:'fault_current',title:'Transformer fault current',group:'Electrical safety',description:'Transformer impedance-only three-phase fault-current estimate at the secondary terminals.',fields:[const _FieldSpec('transformerKva','Transformer rating','kVA',500),const _FieldSpec('secondaryVoltageV','Secondary line voltage','V',415),const _FieldSpec('impedancePercent','Transformer impedance','%',6)],calculate:(v)=>AdvancedEngineering.transformerFaultCurrent(transformerKva:v['transformerKva']!,secondaryVoltageV:v['secondaryVoltageV']!,impedancePercent:v['impedancePercent']!)),
  _CalcSpec(key:'roof_load',title:'Rooftop equipment loading',group:'Structural & mounting',description:'Estimate average dead load from PV modules and mounting materials against a user-entered roof-load allowance.',fields:[const _FieldSpec('moduleCount','Module count','Nos',180,integer:true),const _FieldSpec('moduleMassKg','Module mass each','kg',28),const _FieldSpec('mountingMassPerModuleKg','Mounting mass per module','kg',5),const _FieldSpec('effectiveAreaM2','Effective distributed area','m²',500),const _FieldSpec('enteredAllowableLoadKpa','Entered allowable roof load','kPa',1.5)],calculate:(v)=>AdvancedEngineering.rooftopLoadScreen(moduleCount:v['moduleCount']!.round(),moduleMassKg:v['moduleMassKg']!,mountingMassPerModuleKg:v['mountingMassPerModuleKg']!,effectiveAreaM2:v['effectiveAreaM2']!,enteredAllowableLoadKpa:v['enteredAllowableLoadKpa']!)),
  _CalcSpec(key:'concrete_rebar',title:'Concrete and reinforcement take-off',group:'Civil & foundation',description:'Estimate rectangular concrete volume, order quantity and a user-entered reinforcement mass rate.',fields:[const _FieldSpec('lengthM','Concrete length','m',1.5),const _FieldSpec('widthM','Concrete width','m',1.5),const _FieldSpec('depthM','Concrete depth','m',.6),const _FieldSpec('concreteWastePercent','Concrete waste allowance','%',3),const _FieldSpec('reinforcementKgPerM3','Reinforcement estimate rate','kg/m³',90)],calculate:(v)=>AdvancedEngineering.concreteAndRebarTakeoff(lengthM:v['lengthM']!,widthM:v['widthM']!,depthM:v['depthM']!,concreteWastePercent:v['concreteWastePercent']!,reinforcementKgPerM3:v['reinforcementKgPerM3']!)),
];

class AdvancedEngineeringScreen extends ConsumerStatefulWidget {
  const AdvancedEngineeringScreen({super.key});
  @override
  ConsumerState<AdvancedEngineeringScreen> createState()=>_AdvancedEngineeringScreenState();
}

class _AdvancedEngineeringScreenState extends ConsumerState<AdvancedEngineeringScreen> {
  final Map<String,TextEditingController> _controllers={};
  String _selectedKey='solar_resource';
  AdvancedEngineeringResult? _result;
  String? _error;
  bool _saving=false;
  _CalcSpec get _selected=>_calculators.firstWhere((c)=>c.key==_selectedKey);

  @override void initState(){super.initState();for(final calc in _calculators){for(final field in calc.fields){_controllers['${calc.key}.${field.key}']=TextEditingController(text:field.initial.toString());}}}
  @override void dispose(){for(final c in _controllers.values){c.dispose();}super.dispose();}

  Map<String,double> _values(_CalcSpec calc){final values=<String,double>{};for(final field in calc.fields){final raw=_controllers['${calc.key}.${field.key}']!.text.trim();final value=double.tryParse(raw);if(value==null||!value.isFinite)throw FormatException('${field.label}: enter a valid number.');if(field.integer && value!=value.roundToDouble()) throw FormatException('${field.label}: enter a whole number.');values[field.key]=value;}return values;}

  void _calculate(){setState((){_error=null;try{_result=_selected.calculate(_values(_selected));}on Object catch(e){_result=null;_error=e.toString().replaceFirst('Invalid argument(s): ','');}});}

  void _useProjectInputs() {
    final project = ref.read(activeProjectProvider).valueOrNull;
    if (project == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create or select a project first.')));
      return;
    }
    Map<String, Object?> section(String key) {
      final value = project.engineeringData[key];
      return value is Map ? Map<String, Object?>.from(value) : <String, Object?>{};
    }
    double? number(Object? value) => value is num ? value.toDouble() : double.tryParse((value?.toString() ?? '').replaceAll(',', '').replaceAll('₹', '').trim());
    final survey = section('survey');
    final pv = section('pv');
    final electrical = section('electrical');
    final yieldSection = section('yield');
    final surveyCurrent = survey['needsReview'] != true;
    final pvCurrent = pv['needsReview'] != true;
    final electricalCurrent = electrical['needsReview'] != true;
    final yieldCurrent = yieldSection['needsReview'] != true;
    final roofArea = surveyCurrent ? (number(survey['roofLengthM']) ?? 0) * (number(survey['roofWidthM']) ?? 0) : 0.0;
    final modules = pvCurrent ? (number(pv['moduleCount']) ?? number((pv['calculationResult'] is Map) ? (pv['calculationResult'] as Map)['moduleCount'] : null) ?? 0) : 0.0;
    final modulePower = number(pv['modulePowerW']) ?? 550;
    final dcKwp = modules > 0 ? modules * modulePower / 1000 : project.targetCapacityKw;
    final yieldResult = yieldSection['calculationResult'];
    double? annualGeneration;
    if (yieldCurrent && yieldResult is Map && yieldResult['metrics'] is List) {
      for (final item in yieldResult['metrics'] as List) {
        if (item is Map && item['label']?.toString().toLowerCase().contains('annual generation') == true) {
          annualGeneration = number(item['value']);
        }
      }
    }
    final mappings = <String, double>{
      if (dcKwp > 0) 'dcKwp': dcKwp,
      if (dcKwp > 0) 'dcCapacityKwp': dcKwp,
      if (roofArea > 0) 'effectiveAreaM2': roofArea,
      if (roofArea > 0) 'areaM2': roofArea,
      if (modules > 0) 'moduleCount': modules,
      if (electricalCurrent && number(electrical['cableCurrentA']) != null) 'currentA': number(electrical['cableCurrentA'])!,
      if (electricalCurrent && number(electrical['cableLengthM']) != null) 'lengthM': number(electrical['cableLengthM'])!,
      if (annualGeneration != null && annualGeneration > 0) 'annualGenerationKwh': annualGeneration,
    };
    var updated = 0;
    for (final entry in mappings.entries) {
      final controller = _controllers['${_selected.key}.${entry.key}'];
      if (controller != null) { controller.text = entry.value.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), ''); updated++; }
    }
    setState(() { _result = null; _error = null; });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(updated == 0 ? 'No matching saved values were available for this calculator. Confirm the displayed sample inputs.' : 'Applied $updated value(s) from ${project.name}. Verify every value and datasheet before calculating.')));
  }

  Future<void> _saveToProject() async {
    final active=ref.read(activeProjectProvider).valueOrNull;
    if(_result==null)return;
    if(active==null){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Select or create an active project before saving this calculation.')));return;}
    setState(()=>_saving=true);
    try{
      final data=Map<String,Object?>.from(active.engineeringData);
      final raw=data['advancedEngineering'];
      final advanced=raw is Map?Map<String,Object?>.from(raw):<String,Object?>{};
      final recordsRaw=advanced['calculations'];
      final records=recordsRaw is Map?Map<String,Object?>.from(recordsRaw):<String,Object?>{};
      records[_result!.key]=_result!.toJson();
      advanced['calculations']=records;
      advanced['lastUpdated']=DateTime.now().toUtc().toIso8601String();
      data['advancedEngineering']=advanced;
      final report=data['report'];
      if(report is Map){final next=Map<String,Object?>.from(report);next['needsReview']=true;next['reviewReason']='Advanced engineering calculation updated; regenerate the DPR snapshot.';data['report']=next;}
      await ref.read(projectRepositoryProvider).save(active.copyWith(engineeringData:data,updatedAt:DateTime.now()));
      ref.invalidate(projectsProvider);
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Calculation saved to the active project. DPR marked for review.')));
    }on Object catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not save calculation: $e')));}finally{if(mounted)setState(()=>_saving=false);}
  }

  @override Widget build(BuildContext context){
    final active=ref.watch(activeProjectProvider).valueOrNull;
    final groups=<String,List<_CalcSpec>>{};for(final c in _calculators){groups.putIfAbsent(c.group,()=>[]).add(c);}
    return Scaffold(
      appBar:AppBar(title:const Text('Advanced engineering library'),actions:[if(active!=null)Padding(padding:const EdgeInsets.only(right:12),child:Center(child:Chip(avatar:const Icon(Icons.folder_copy_outlined,size:16),label:Text(active.name,overflow:TextOverflow.ellipsis))))]),
      body:LayoutBuilder(builder:(context,constraints){final wide=constraints.maxWidth>=1000;return Row(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        if(wide)SizedBox(width:280,child:_catalog(groups)),
        Expanded(child:SingleChildScrollView(padding:EdgeInsets.all(wide?28:16),child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:920),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          if(!wide)_catalog(groups),
          _headline(active),
          const SizedBox(height:18),
          _calculatorForm(),
          const SizedBox(height:18),
          if(_error!=null)_errorCard(_error!),
          if(_result!=null)_resultPanel(_result!),
          const SizedBox(height:36),
        ]))))),
      ]);}),
    );
  }

  Widget _catalog(Map<String,List<_CalcSpec>> groups)=>Container(
    color:Theme.of(context).colorScheme.surfaceContainerLow,
    padding:const EdgeInsets.all(16),
    child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Text('Design tools',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)),
      const SizedBox(height:4),const Text('Choose a discipline and calculate with your project inputs.',style:TextStyle(fontSize:12)),
      const SizedBox(height:12),
      for(final entry in groups.entries)...[
        Padding(padding:const EdgeInsets.fromLTRB(6,12,6,6),child:Text(entry.key.toUpperCase(),style:Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing:1.1,fontWeight:FontWeight.w800,color:Theme.of(context).colorScheme.primary))),
        for(final calc in entry.value)ListTile(dense:true,selected:calc.key==_selectedKey,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)),leading:Icon(_iconFor(calc.group)),title:Text(calc.title,style:const TextStyle(fontSize:13,fontWeight:FontWeight.w700)),onTap:(){setState((){_selectedKey=calc.key;_result=null;_error=null;});}),
      ],
    ])),
  );

  IconData _iconFor(String group)=>switch(group){'Solar resource'=>Icons.wb_sunny_outlined,'PV equipment'=>Icons.solar_power_outlined,'Electrical'=>Icons.electrical_services_outlined,'Structural & mounting'=>Icons.architecture,'Civil & foundation'=>Icons.foundation_rounded,'Electrical safety'=>Icons.shield_outlined,'Battery & storage'=>Icons.battery_charging_full_rounded,'Solar applications'=>Icons.water_drop_outlined,_=>Icons.account_balance_outlined};

  Widget _headline(SolarProject? active)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(_selected.group.toUpperCase(),style:Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing:1.3,color:Theme.of(context).colorScheme.primary,fontWeight:FontWeight.w800)),
    const SizedBox(height:6),Text(_selected.title,style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w900)),
    const SizedBox(height:6),Text(_selected.description,style:Theme.of(context).textTheme.bodyMedium),
    const SizedBox(height:12),Wrap(spacing:8,runSpacing:8,children:[const Chip(avatar:Icon(Icons.offline_bolt_outlined,size:16),label:Text('Offline calculation')),Chip(avatar:Icon(Icons.folder_open_outlined,size:16),label:Text(active==null?'No active project':active.name))]),
  ]);

  Widget _calculatorForm()=>Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Row(children:[Expanded(child:Text('Calculation inputs',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800))),Text('${_selected.fields.length} parameters',style:Theme.of(context).textTheme.labelSmall)]),
    const SizedBox(height:14),
    LayoutBuilder(builder:(context,c){final columns=c.maxWidth>680?2:1;return GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:_selected.fields.length,gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:columns,childAspectRatio:columns==2?4.4:5.0,crossAxisSpacing:12,mainAxisSpacing:4),itemBuilder:(context,index){final f=_selected.fields[index];final controller=_controllers['${_selected.key}.${f.key}']!;if(f.toggle){return SwitchListTile(title:Text(f.label,style:const TextStyle(fontSize:13,fontWeight:FontWeight.w600)),subtitle:Text(f.unit,style:Theme.of(context).textTheme.labelSmall),value:(double.tryParse(controller.text)??0)>=.5,onChanged:(value)=>setState((){controller.text=value?'1':'0';_result=null;}),contentPadding:const EdgeInsets.symmetric(horizontal:8));}return TextField(controller:controller,keyboardType:const TextInputType.numberWithOptions(decimal:true,signed:false),decoration:InputDecoration(labelText:f.label,suffixText:f.unit.isEmpty?null:f.unit,border:const OutlineInputBorder(),isDense:true),onChanged:(_){if(_result!=null)setState(()=>_result=null);},onSubmitted:(_)=>_calculate());});}),
    const SizedBox(height:12),
    Wrap(spacing:10,runSpacing:10,children:[
      OutlinedButton.icon(onPressed:_useProjectInputs,icon:const Icon(Icons.sync_alt),label:const Text('Use project data')),
      OutlinedButton.icon(onPressed:(){setState((){for(final f in _selected.fields){_controllers['${_selected.key}.${f.key}']!.text=f.initial.toString();}_result=null;_error=null;});},icon:const Icon(Icons.restart_alt),label:const Text('Reset inputs')),
      FilledButton.icon(onPressed:_calculate,icon:const Icon(Icons.calculate_outlined),label:const Text('Calculate')),
    ]),
    const SizedBox(height:6),
    Text('Preset values are examples. Use project data where available, then verify each input against the survey, datasheet and design basis.',style:Theme.of(context).textTheme.bodySmall),
  ])));

  Widget _errorCard(String message)=>Card(color:Theme.of(context).colorScheme.errorContainer,child:Padding(padding:const EdgeInsets.all(14),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.error_outline,color:Theme.of(context).colorScheme.error),const SizedBox(width:10),Expanded(child:Text(message,style:TextStyle(color:Theme.of(context).colorScheme.onErrorContainer)))])));

  Widget _resultPanel(AdvancedEngineeringResult result){final okay=result.warnings.isEmpty;return Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Row(children:[Expanded(child:Text('Calculation result',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w900))),Chip(avatar:Icon(okay?Icons.info_outline:Icons.warning_amber_rounded,size:16),label:Text(result.status))]),
    const SizedBox(height:12),
    LayoutBuilder(builder:(context,c){final cols=c.maxWidth>650?3:2;return GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:cols,childAspectRatio:2.3,crossAxisSpacing:10,mainAxisSpacing:10,children:result.metrics.entries.map((e)=>Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Theme.of(context).colorScheme.surfaceContainerLow,borderRadius:BorderRadius.circular(14)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[Text(e.key,style:Theme.of(context).textTheme.labelSmall,maxLines:2,overflow:TextOverflow.ellipsis),const SizedBox(height:5),Text(e.value.display,style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w900),maxLines:2,overflow:TextOverflow.ellipsis)]))).toList());}),
    const SizedBox(height:16),Text('Formula',style:Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:4),SelectableText(result.formula),
    const SizedBox(height:12),Text('Assumptions',style:Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight:FontWeight.w800)),for(final note in result.assumptions)Padding(padding:const EdgeInsets.only(top:5),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[const Icon(Icons.check_circle_outline,size:16),const SizedBox(width:8),Expanded(child:Text(note,style:Theme.of(context).textTheme.bodySmall))])),
    if(result.warnings.isNotEmpty)...[const SizedBox(height:14),Text('Warnings and exclusions',style:Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight:FontWeight.w800,color:Theme.of(context).colorScheme.error)),for(final warning in result.warnings)Padding(padding:const EdgeInsets.only(top:5),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.warning_amber_rounded,size:16,color:Theme.of(context).colorScheme.error),const SizedBox(width:8),Expanded(child:Text(warning,style:Theme.of(context).textTheme.bodySmall))]))],
    const SizedBox(height:18),FilledButton.icon(onPressed:_saving?null:_saveToProject,icon:_saving?const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.save_outlined),label:Text(_saving?'Saving to project...':'Save calculation to active project')),
    const SizedBox(height:8),const Text('A calculation result is evidence for review, not an engineering approval or construction release.',style:TextStyle(fontSize:11,color:Colors.grey)),
  ])));}
}
