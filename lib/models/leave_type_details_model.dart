// lib/models/leave_type.dart

class LeaveTypeDetailsModel {
  final String id;
  final String name;
  final String imageAsset;
  final String requirement;
  final int balanceDays;

  LeaveTypeDetailsModel({
    required this.id,
    required this.name,
    required this.imageAsset,
    required this.requirement,
    required this.balanceDays,
  });
}