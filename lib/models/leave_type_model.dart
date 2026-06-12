class LeaveType {
  final int id;
  final String name;
  final int balance;
  final List<String> requirements;

  LeaveType({
    required this.id,
    required this.name,
    required this.balance,
    required this.requirements,
  });
}


class EventItem {
  final String title;
  final String subtitle;
  final String imageUrl;

  EventItem({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });

  factory EventItem.fromJson(Map<String, dynamic> json) {
    return EventItem(
      title: json["title"] ?? "",
      subtitle: json["subtitle"] ?? "",
      imageUrl: json["imageUrl"] ?? "",
    );
  }
}

class LeaveBalance {
  final int id;
  final int staffId;
  final String staffName;

  final double vacationLeave;
  final double sickLeave;
  final double specialPrivilegeLeave;
  final double forceLeave;
  final double maternityLeave;
  final double paternityLeave;
  final double soloParentLeave;
  final double studyLeave;
  final double vawcLeave;
  final double rehabilitationLeave;
  final double specialLeaveWomen;
  final double calamityLeave;
  final double monetization;
  final double terminalLeave;
  final double adoptionLeave;
  final double emergencyLeave;

  final double vacationLeaveUsed;
  final double sickLeaveUsed;
  final double specialPrivilegeLeaveUsed;
  final double forceLeaveUsed;
  final double maternityLeaveUsed;
  final double paternityLeaveUsed;
  final double soloParentLeaveUsed;
  final double studyLeaveUsed;
  final double vawcLeaveUsed;
  final double rehabilitationLeaveUsed;
  final double specialLeaveWomenUsed;
  final double calamityLeaveUsed;
  final double monetizationUsed;
  final double terminalLeaveUsed;
  final double adoptionLeaveUsed;
  final double emergencyLeaveUsed;

  LeaveBalance({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.vacationLeave,
    required this.sickLeave,
    required this.specialPrivilegeLeave,
    required this.forceLeave,
    required this.maternityLeave,
    required this.paternityLeave,
    required this.soloParentLeave,
    required this.studyLeave,
    required this.vawcLeave,
    required this.rehabilitationLeave,
    required this.specialLeaveWomen,
    required this.calamityLeave,
    required this.monetization,
    required this.terminalLeave,
    required this.adoptionLeave,
    required this.emergencyLeave,
    required this.vacationLeaveUsed,
    required this.sickLeaveUsed,
    required this.specialPrivilegeLeaveUsed,
    required this.forceLeaveUsed,
    required this.maternityLeaveUsed,
    required this.paternityLeaveUsed,
    required this.soloParentLeaveUsed,
    required this.studyLeaveUsed,
    required this.vawcLeaveUsed,
    required this.rehabilitationLeaveUsed,
    required this.specialLeaveWomenUsed,
    required this.calamityLeaveUsed,
    required this.monetizationUsed,
    required this.terminalLeaveUsed,
    required this.adoptionLeaveUsed,
    required this.emergencyLeaveUsed,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    double parse(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return LeaveBalance(
      id: json["id"] ?? 0,
      staffId: json["staff_id"] ?? 0,
      staffName: json["staff_name"] ?? '',

      vacationLeave: parse(json["vacation_leave"]),
      sickLeave: parse(json["sick_leave"]),
      specialPrivilegeLeave: parse(json["special_privilege_leave"]),
      forceLeave: parse(json["force_leave"]),
      maternityLeave: parse(json["maternity_leave"]),
      paternityLeave: parse(json["paternity_leave"]),
      soloParentLeave: parse(json["solo_parent_leave"]),
      studyLeave: parse(json["study_leave"]),
      vawcLeave: parse(json["vawc_leave"]),
      rehabilitationLeave: parse(json["rehabilitation_leave"]),
      specialLeaveWomen: parse(json["special_leave_women"]),
      calamityLeave: parse(json["calamity_leave"]),
      monetization: parse(json["monetization"]),
      terminalLeave: parse(json["terminal_leave"]),
      adoptionLeave: parse(json["adoption_leave"]),
      emergencyLeave: parse(json["emergency_leave"]),

      vacationLeaveUsed: parse(json["vacation_leave_used"]),
      sickLeaveUsed: parse(json["sick_leave_used"]),
      specialPrivilegeLeaveUsed: parse(json["special_privilege_leave_used"]),
      forceLeaveUsed: parse(json["force_leave_used"]),
      maternityLeaveUsed: parse(json["maternity_leave_used"]),
      paternityLeaveUsed: parse(json["paternity_leave_used"]),
      soloParentLeaveUsed: parse(json["solo_parent_leave_used"]),
      studyLeaveUsed: parse(json["study_leave_used"]),
      vawcLeaveUsed: parse(json["vawc_leave_used"]),
      rehabilitationLeaveUsed: parse(json["rehabilitation_leave_used"]),
      specialLeaveWomenUsed: parse(json["special_leave_women_used"]),
      calamityLeaveUsed: parse(json["calamity_leave_used"]),
      monetizationUsed: parse(json["monetization_used"]),
      terminalLeaveUsed: parse(json["terminal_leave_used"]),
      adoptionLeaveUsed: parse(json["adoption_leave_used"]),
      emergencyLeaveUsed: parse(json["emergency_leave_used"]),
    );
  }

  toJson() {}
}

