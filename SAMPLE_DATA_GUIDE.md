# Malaysian Sample Data Population Guide

This guide explains how to populate your Flutter automotive workshop application with comprehensive Malaysian sample data for client demonstrations.

## Overview

The sample data generation system creates authentic Malaysian automotive workshop data including:

- **30 Customers** with Malaysian names, addresses, and phone numbers
- **60+ Vehicles** with Malaysian license plates and popular local car makes/models
- **200+ Service Records** with realistic Malaysian pricing (RM) and local automotive services
- **25 Job Appointments** with various statuses (scheduled, in-progress, completed)
- **20 Invoices** with proper Malaysian tax (6% SST) and payment terms
- **50 Inventory Items** with Malaysian automotive suppliers and parts
- **15 Order Requests** for low-stock inventory items

## Features

### Malaysian Localization
- **Names**: Mix of Malay, Chinese, Indian, and other Malaysian ethnicities
- **Addresses**: Authentic Malaysian street names, cities, and states
- **Phone Numbers**: Proper Malaysian mobile formats (+60 12-345-6789)
- **License Plates**: Malaysian formats (ABC 1234, WXY 123A, KL 5678 B)
- **Vehicle Makes**: Popular brands in Malaysia (Proton, Perodua, Honda, Toyota, etc.)
- **Currency**: All pricing in Malaysian Ringgit (RM)
- **Suppliers**: Malaysian automotive parts suppliers and distributors

### Data Relationships
- Customers linked to their vehicles
- Service records connected to specific vehicles and customers
- Invoices generated from service records
- Inventory items with realistic stock levels and supplier information
- Order requests for low-stock items

## Usage Methods

### Method 1: Using the UI Widget

Add the data population widget to your app (e.g., in an admin panel or debug menu):

```dart
import 'package:your_app/data/populate_sample_data.dart';

// Navigate to the data population screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const PopulateSampleDataWidget(),
  ),
);
```

### Method 2: Programmatic Population

Call the function directly from your code:

```dart
import 'package:your_app/data/populate_sample_data.dart';

// Populate data
await populateMalaysianSampleData();

// Or clear all data
await clearAllFirebaseData();
```

### Method 3: Custom Configuration

Use the FirebaseDataPopulator directly with custom parameters:

```dart
import 'package:your_app/data/firebase_data_populator.dart';

await FirebaseDataPopulator.populateAllData(
  customerCount: 50,           // Number of customers
  maxVehiclesPerCustomer: 2,   // Max vehicles per customer
  maxServiceRecordsPerVehicle: 3, // Max service records per vehicle
  appointmentCount: 30,        // Number of appointments
  invoiceCount: 25,           // Number of invoices
  inventoryItemCount: 75,     // Number of inventory items
  orderRequestCount: 20,      // Number of order requests
);
```

## Firebase Collections Structure

The data will be populated into these Firestore collections:

```
/customers
  /{customerId}
    - id, firstName, lastName, email, phone
    - address, city, state, zipCode
    - vehicleIds[], totalSpent, visitCount
    - preferences, communicationHistory[]

/vehicles
  /{vehicleId}
    - id, make, model, year, licensePlate, vin
    - color, mileage, customerId
    - lastServiceDate, photos[], notes

/service_records
  /{serviceRecordId}
    - id, customerId, vehicleId, serviceDate
    - serviceType, description, cost
    - mechanicName, status, partsReplaced[]

/appointments
  /{appointmentId}
    - id, vehicleInfo, customerName, mechanicName
    - startTime, endTime, serviceType, status
    - notes, partsNeeded[], estimatedCost

/invoices
  /{invoiceId}
    - id, customerId, customerName, vehicleId
    - issueDate, dueDate, items[], status
    - subtotal, taxTotal, total

/inventory
  /{inventoryItemId}
    - id, name, category, currentStock
    - minStock, maxStock, unitPrice
    - supplier, location, description

/order_requests
  /{orderRequestId}
    - id, itemId, itemName, supplier
    - quantity, unitPrice, totalAmount
    - status, requestDate, requestedBy
```

## Sample Data Examples

### Malaysian Customer Names
- Ahmad bin Abdullah
- Tan Mei Ling  
- Raj Kumar a/l Suresh
- Siti Nurhaliza binti Hassan
- Wong Ah Beng

### Malaysian Addresses
- No. 15, Jalan Bukit Bintang, Kuala Lumpur, Selangor 50200
- 23-1, Lorong Damansara, Petaling Jaya, Selangor 47400
- 45, Persiaran Raja Chulan, Shah Alam, Selangor 40000

### Vehicle Examples
- 2020 Proton Saga - WA 1234 A
- 2019 Perodua Myvi - KL 5678 B
- 2021 Honda City - JHR 9012 C

### Service Types
- Oil Change, Brake Service, Transmission Service
- Air Conditioning Service, Tire Rotation
- Engine Tune-up, Battery Replacement

## Important Notes

1. **Firebase Project**: Ensure you're connected to the correct Firebase project
2. **Data Backup**: Consider backing up existing data before population
3. **Clear Function**: Use the clear data function with caution as it deletes all data
4. **Batch Operations**: The system uses Firebase batch operations for efficiency
5. **Error Handling**: All operations include proper error handling and logging

## Troubleshooting

### Common Issues

1. **Firebase Connection**: Ensure Firebase is properly initialized
2. **Permissions**: Check Firestore security rules allow write operations
3. **Network**: Verify internet connection for Firebase operations
4. **Memory**: Large datasets may require device restart after population

### Debug Logging

The system provides detailed console logging:
- 🚀 Starting operations
- 📊 Data generation progress  
- 🔥 Firebase population status
- ✅ Success confirmations
- ❌ Error messages

## Client Demonstration Benefits

This comprehensive sample data enables you to showcase:

1. **Complete Customer Management** with realistic Malaysian customer profiles
2. **Vehicle Tracking** with authentic Malaysian license plates and car models
3. **Service History** with proper pricing and local automotive services
4. **Appointment Scheduling** with realistic time slots and mechanic assignments
5. **Invoice Generation** with Malaysian tax calculations and payment terms
6. **Inventory Management** with local supplier information and stock levels
7. **Order Processing** with realistic wholesale pricing and delivery terms

The data provides a realistic representation of a busy Malaysian automotive workshop, making your application demo more compelling and relatable to local clients.
