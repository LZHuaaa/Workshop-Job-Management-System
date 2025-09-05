class ServiceInfo {
  final double defaultPrice;
  final List<String> servicesToPerform;
  final List<String> partsToReplace;
  final int nextServiceMonths;

  ServiceInfo({
    required this.defaultPrice,
    required this.servicesToPerform,
    required this.partsToReplace,
    required this.nextServiceMonths,
  });
}

class ServiceMappings {
  static final Map<String, ServiceInfo> services = {
    'Oil Change': ServiceInfo(
      defaultPrice: 50.0,
      servicesToPerform: [
        'Oil and filter change',
        'Fluid level check',
        'Basic inspection'
      ],
      partsToReplace: [
        'Oil filter',
        'Engine oil'
      ],
      nextServiceMonths: 6,
    ),
    'Brake Service': ServiceInfo(
      defaultPrice: 150.0,
      servicesToPerform: [
        'Brake pad replacement',
        'Rotor inspection',
        'Brake fluid check'
      ],
      partsToReplace: [
        'Brake pads',
        'Brake fluid'
      ],
      nextServiceMonths: 12,
    ),
    'Tire Service': ServiceInfo(
      defaultPrice: 80.0,
      servicesToPerform: [
        'Tire rotation',
        'Tire pressure check',
        'Tire balance'
      ],
      partsToReplace: [
        'Valve stems',
        'Balance weights'
      ],
      nextServiceMonths: 6,
    ),
    'General Service': ServiceInfo(
      defaultPrice: 100.0,
      servicesToPerform: [
        'Visual inspection',
        'Fluid checks',
        'Basic diagnostics'
      ],
      partsToReplace: [],
      nextServiceMonths: 6,
    ),
  };
}
