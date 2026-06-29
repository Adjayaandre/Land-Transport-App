class TripModel {
  final String? id;
  final String customerId;
  final String vesselId;
  final String vehicleId;
  final String driverId;
  final String pickupLocation;
  final String destination;
  final String tripType;       // incoming | outgoing
  final DateTime tripDate;
  final DateTime pickupTime;
  final DateTime? arrivalTime;
  final String status;         // preparation | ongoing | completed | cancelled
  final double odometerStart;
  final double? odometerEnd;
  final List<String> passengers;
  final String? photoOdometerBefore;
  final String? photoOdometerAfter;
  final String? signatureImageUrl;
  final bool isSynced;

  const TripModel({
    this.id, required this.customerId, required this.vesselId, required this.vehicleId,
    required this.driverId, required this.pickupLocation, required this.destination,
    required this.tripType, required this.tripDate, required this.pickupTime,
    this.arrivalTime, required this.status, required this.odometerStart,
    this.odometerEnd, required this.passengers, this.photoOdometerBefore,
    this.photoOdometerAfter, this.signatureImageUrl, this.isSynced = false,
  });
}
