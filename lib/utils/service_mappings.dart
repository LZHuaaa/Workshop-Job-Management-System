class ServiceMappings {
  static const Map<String, ServiceDetails> serviceTypeMap = {
    'Oil Change': ServiceDetails(
      defaultServices: [
        'Oil filter replacement',
        'Engine oil replacement',
        'Oil level check',
        'Oil pressure check',
      ],
      commonParts: [
        'Oil filter',
        'Engine oil',
        'Drain plug washer',
      ],
      nextServiceMonths: 6,
    ),
    'Brake Service': ServiceDetails(
      defaultServices: [
        'Brake pad inspection',
        'Rotor resurfacing',
        'Brake fluid check',
        'Brake line inspection',
        'Caliper inspection',
      ],
      commonParts: [
        'Brake pads',
        'Brake rotors',
        'Brake fluid',
        'Brake calipers',
      ],
      nextServiceMonths: 12,
    ),
    'Transmission Service': ServiceDetails(
      defaultServices: [
        'Transmission fluid change',
        'Filter replacement',
        'Pan gasket replacement',
        'Transmission inspection',
      ],
      commonParts: [
        'Transmission fluid',
        'Transmission filter',
        'Pan gasket',
      ],
      nextServiceMonths: 24,
    ),
    'Engine Repair': ServiceDetails(
      defaultServices: [
        'Engine diagnosis',
        'Component inspection',
        'Performance testing',
        'Compression test',
      ],
      commonParts: [
        'Spark plugs',
        'Air filter',
        'Fuel filter',
        'Gaskets',
      ],
      nextServiceMonths: 12,
    ),
    'Tire Replacement': ServiceDetails(
      defaultServices: [
        'Tire inspection',
        'Wheel balancing',
        'Tire rotation',
        'Alignment check',
      ],
      commonParts: [
        'Tires',
        'Valve stems',
        'Wheel weights',
      ],
      nextServiceMonths: 6,
    ),
    'Battery Replacement': ServiceDetails(
      defaultServices: [
        'Battery load test',
        'Terminal cleaning',
        'Charging system check',
        'Battery replacement',
      ],
      commonParts: [
        'Battery',
        'Terminal connectors',
        'Battery hold-down',
      ],
      nextServiceMonths: 36,
    ),
    'Air Conditioning': ServiceDetails(
      defaultServices: [
        'AC performance test',
        'Refrigerant level check',
        'System leak test',
        'Belt inspection',
      ],
      commonParts: [
        'Refrigerant',
        'Cabin air filter',
        'AC compressor',
        'Belt',
      ],
      nextServiceMonths: 12,
    ),
    'Electrical Repair': ServiceDetails(
      defaultServices: [
        'Electrical system diagnosis',
        'Circuit testing',
        'Component inspection',
        'Wiring check',
      ],
      commonParts: [
        'Fuses',
        'Relays',
        'Wiring harness',
        'Electrical components',
      ],
      nextServiceMonths: 12,
    ),
    'Suspension Repair': ServiceDetails(
      defaultServices: [
        'Suspension inspection',
        'Shock/strut testing',
        'Alignment check',
        'Ball joint inspection',
      ],
      commonParts: [
        'Shock absorbers',
        'Struts',
        'Ball joints',
        'Control arms',
      ],
      nextServiceMonths: 24,
    ),
    'General Inspection': ServiceDetails(
      defaultServices: [
        'Multi-point inspection',
        'Fluid level checks',
        'Belt and hose inspection',
        'Light and signal check',
      ],
      commonParts: [
        'Wiper blades',
        'Light bulbs',
        'Fluids',
        'Filters',
      ],
      nextServiceMonths: 6,
    ),
  };
}

class ServiceDetails {
  final List<String> defaultServices;
  final List<String> commonParts;
  final int nextServiceMonths;

  const ServiceDetails({
    required this.defaultServices,
    required this.commonParts,
    required this.nextServiceMonths,
  });
}
