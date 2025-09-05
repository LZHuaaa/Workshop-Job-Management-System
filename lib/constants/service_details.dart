class ServiceDetails {
  static const Map<String, ServiceInfo> services = {
    'Oil Change': ServiceInfo(
      defaultPrice: 150.00,
      servicesToPerform: [
        'Engine oil replacement',
        'Oil filter replacement',
        'Oil level check',
        'Oil pressure check',
        'Fluid levels inspection'
      ],
      partsToReplace: [
        'Engine oil',
        'Oil filter',
        'Drain plug washer',
        'Oil pan gasket'
      ],
      nextServiceMonths: 6,
    ),
    'Brake Service': ServiceInfo(
      defaultPrice: 300.00,
      servicesToPerform: [
        'Brake pad inspection',
        'Rotor resurfacing',
        'Brake fluid check',
        'Brake line inspection',
        'Caliper inspection',
        'Brake bleeding'
      ],
      partsToReplace: [
        'Brake pads',
        'Brake rotors',
        'Brake fluid',
        'Brake caliper',
        'Brake lines'
      ],
      nextServiceMonths: 12,
    ),
    'Transmission Service': ServiceInfo(
      defaultPrice: 450.00,
      servicesToPerform: [
        'Transmission fluid change',
        'Filter replacement',
        'Pan gasket replacement',
        'Transmission inspection',
        'Clutch adjustment'
      ],
      partsToReplace: [
        'Transmission fluid',
        'Transmission filter',
        'Pan gasket',
        'Seals'
      ],
      nextServiceMonths: 24,
    ),
    'Engine Repair': ServiceInfo(
      defaultPrice: 800.00,
      servicesToPerform: [
        'Engine diagnostic',
        'Compression test',
        'Spark plug replacement',
        'Timing belt inspection',
        'Vacuum leak test'
      ],
      partsToReplace: [
        'Spark plugs',
        'Air filter',
        'Fuel filter',
        'Timing belt',
        'Gaskets'
      ],
      nextServiceMonths: 12,
    ),
    'Tire Replacement': ServiceInfo(
      defaultPrice: 600.00,
      servicesToPerform: [
        'Tire inspection',
        'Wheel balancing',
        'Tire rotation',
        'Alignment check',
        'TPMS reset'
      ],
      partsToReplace: [
        'Tires',
        'Valve stems',
        'Wheel weights',
        'TPMS sensors'
      ],
      nextServiceMonths: 6,
    ),
    'Battery Replacement': ServiceInfo(
      defaultPrice: 250.00,
      servicesToPerform: [
        'Battery load test',
        'Terminal cleaning',
        'Charging system check',
        'Alternator test',
        'Battery replacement'
      ],
      partsToReplace: [
        'Battery',
        'Terminal connectors',
        'Battery hold-down',
        'Terminal protectors'
      ],
      nextServiceMonths: 36,
    ),
    'Air Conditioning': ServiceInfo(
      defaultPrice: 350.00,
      servicesToPerform: [
        'AC performance test',
        'Refrigerant level check',
        'System leak test',
        'Belt inspection',
        'Compressor check'
      ],
      partsToReplace: [
        'Refrigerant',
        'Cabin air filter',
        'AC compressor',
        'Belt',
        'O-rings'
      ],
      nextServiceMonths: 12,
    ),
    'Electrical Repair': ServiceInfo(
      defaultPrice: 400.00,
      servicesToPerform: [
        'Electrical system diagnosis',
        'Circuit testing',
        'Component inspection',
        'Battery check',
        'Alternator test'
      ],
      partsToReplace: [
        'Fuses',
        'Relays',
        'Wiring harness',
        'Electrical components',
        'Connectors'
      ],
      nextServiceMonths: 12,
    ),
    'Suspension Repair': ServiceInfo(
      defaultPrice: 550.00,
      servicesToPerform: [
        'Suspension inspection',
        'Shock/strut testing',
        'Alignment check',
        'Ball joint inspection',
        'Steering test'
      ],
      partsToReplace: [
        'Shock absorbers',
        'Struts',
        'Ball joints',
        'Control arms',
        'Bushings'
      ],
      nextServiceMonths: 24,
    ),
    'General Inspection': ServiceInfo(
      defaultPrice: 180.00,
      servicesToPerform: [
        'Multi-point inspection',
        'Fluid level checks',
        'Belt and hose inspection',
        'Light and signal check',
        'Safety systems check'
      ],
      partsToReplace: [
        'Wiper blades',
        'Air filter',
        'Cabin filter',
        'Light bulbs'
      ],
      nextServiceMonths: 6,
    ),
  };
}

class ServiceInfo {
  final double defaultPrice;
  final List<String> servicesToPerform;
  final List<String> partsToReplace;
  final int nextServiceMonths;

  const ServiceInfo({
    required this.defaultPrice,
    required this.servicesToPerform,
    required this.partsToReplace,
    required this.nextServiceMonths,
  });
}
