class AgencyInfo {
  final bool hasAgency;
  final bool isMember;
  final OwnedAgency? ownedAgency;
  final List<Agency> agencies;

  AgencyInfo({
    required this.hasAgency,
    required this.isMember,
    this.ownedAgency,
    required this.agencies,
  });

  factory AgencyInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return AgencyInfo(
        hasAgency: false,
        isMember: false,
        agencies: [],
      );
    }

    // ✅ Parse agency_details (NEW: only populated if user owns an agency)
    OwnedAgency? ownedAgency;
    if (json['agency_details'] != null) {
      ownedAgency = OwnedAgency.fromJson(json['agency_details']);
    }
    // ✅ Backward compatibility: also check for old 'owned_agency' field
    else if (json['owned_agency'] != null) {
      ownedAgency = OwnedAgency.fromJson(json['owned_agency']);
    }

    // ✅ Parse member_agencies (NEW: array if user is a member of agencies)
    List<Agency> agenciesList = [];
    if (json['member_agencies'] != null && json['member_agencies'] is List) {
      agenciesList = (json['member_agencies'] as List)
          .map((item) => Agency.fromJson(item))
          .toList();
    }
    // ✅ Backward compatibility: also check for old 'agencies' field
    else if (json['agencies'] != null && json['agencies'] is List) {
      agenciesList = (json['agencies'] as List)
          .map((item) => Agency.fromJson(item))
          .toList();
    }

    // ✅ Parse is_member_of_agency (NEW: 0 or 1 boolean integer)
    bool isMemberValue = false;
    if (json.containsKey('is_member_of_agency')) {
      isMemberValue = json['is_member_of_agency'] == true || json['is_member_of_agency'] == 1;
    }
    // ✅ Backward compatibility: also check for old 'is_member' field
    else if (json.containsKey('is_member')) {
      isMemberValue = json['is_member'] == true || json['is_member'] == 1;
    }

    return AgencyInfo(
      hasAgency: json['has_agency'] == true || json['has_agency'] == 1,
      isMember: isMemberValue,
      ownedAgency: ownedAgency,
      agencies: agenciesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'has_agency': hasAgency,
      'is_member': isMember,
      'owned_agency': ownedAgency?.toJson(),
      'agencies': agencies.map((a) => a.toJson()).toList(),
    };
  }
}

class OwnedAgency {
  final int id;
  final int userId;
  final String agencyName;
  final String agencyCode;
  final String createdAt;

  OwnedAgency({
    required this.id,
    required this.userId,
    required this.agencyName,
    required this.agencyCode,
    required this.createdAt,
  });

  factory OwnedAgency.fromJson(Map<String, dynamic> json) {
    // ✅ NEW: agency_details uses 'agency_id' instead of 'id'
    // ✅ Backward compatibility: also check for 'id' field
    int agencyId = 0;
    if (json.containsKey('agency_id')) {
      agencyId = json['agency_id'] is int 
          ? json['agency_id'] 
          : int.tryParse(json['agency_id'].toString()) ?? 0;
    } else if (json.containsKey('id')) {
      agencyId = json['id'] is int 
          ? json['id'] 
          : int.tryParse(json['id'].toString()) ?? 0;
    }

    // ✅ NEW: agency_details may not have 'user_id', use 0 as default
    // ✅ Backward compatibility: check for 'user_id' if present
    int userIdValue = 0;
    if (json.containsKey('user_id')) {
      userIdValue = json['user_id'] is int 
          ? json['user_id'] 
          : int.tryParse(json['user_id'].toString()) ?? 0;
    }

    return OwnedAgency(
      id: agencyId,
      userId: userIdValue,
      agencyName: json['agency_name']?.toString() ?? '',
      agencyCode: json['agency_code']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'agency_name': agencyName,
      'agency_code': agencyCode,
      'created_at': createdAt,
    };
  }
}

class Agency {
  final int id;
  final int userId;
  final String agencyName;
  final String agencyCode;
  final String createdAt;
  final String? joinedAt;

  Agency({
    required this.id,
    required this.userId,
    required this.agencyName,
    required this.agencyCode,
    required this.createdAt,
    this.joinedAt,
  });

  factory Agency.fromJson(Map<String, dynamic> json) {
    // ✅ NEW: member_agencies uses 'agency_id' instead of 'id'
    // ✅ Backward compatibility: also check for 'id' field
    int agencyId = 0;
    if (json.containsKey('agency_id')) {
      agencyId = json['agency_id'] is int 
          ? json['agency_id'] 
          : int.tryParse(json['agency_id'].toString()) ?? 0;
    } else if (json.containsKey('id')) {
      agencyId = json['id'] is int 
          ? json['id'] 
          : int.tryParse(json['id'].toString()) ?? 0;
    }

    // ✅ NEW: member_agencies may not have 'user_id', use 0 as default
    // ✅ Backward compatibility: check for 'user_id' if present
    int userIdValue = 0;
    if (json.containsKey('user_id')) {
      userIdValue = json['user_id'] is int 
          ? json['user_id'] 
          : int.tryParse(json['user_id'].toString()) ?? 0;
    }

    // ✅ NEW: member_agencies uses 'joined_at' instead of 'created_at' for when user joined
    // ✅ Backward compatibility: check for 'created_at' if 'joined_at' is not present
    String createdAtValue = '';
    if (json.containsKey('created_at')) {
      createdAtValue = json['created_at']?.toString() ?? '';
    } else if (json.containsKey('joined_at')) {
      // If only joined_at exists, use it for createdAt
      createdAtValue = json['joined_at']?.toString() ?? '';
    }

    return Agency(
      id: agencyId,
      userId: userIdValue,
      agencyName: json['agency_name']?.toString() ?? '',
      agencyCode: json['agency_code']?.toString() ?? '',
      createdAt: createdAtValue,
      joinedAt: json['joined_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'agency_name': agencyName,
      'agency_code': agencyCode,
      'created_at': createdAt,
      'joined_at': joinedAt,
    };
  }
}

