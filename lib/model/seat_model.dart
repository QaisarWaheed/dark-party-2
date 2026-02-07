

// lib/models/seat_model.dart
class Seat {
  final int seatNumber;
  final bool isOccupied;
  final bool isReserved;
  final String? userId;
  final String? username;
  final String? userName;
  final String? profileUrl;
  final String? country; // ✅ Country name for flag display

  Seat({
    required this.seatNumber,
    required this.isOccupied,
    required this.isReserved,
    this.userId,
    this.username,
    this.userName,
    this.profileUrl,
    this.country,
  });

  factory Seat.fromJson(Map<String, dynamic> json) {
    return Seat(
      seatNumber: json['seat_number'] ?? 0,
      // ✅ FIX: Convert integer (0/1) to boolean
      isOccupied: (json['is_occupied'] == 1 || json['is_occupied'] == true),
      isReserved: (json['is_reserved'] == 1 || json['is_reserved'] == true),
      userId: json['user_id']?.toString(),
      username: json['username'],
      userName: json['user_name'],
      profileUrl: json['profile_url'],
      country: json['country'], // ✅ Get country from backend
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seat_number': seatNumber,
      'is_occupied': isOccupied,
      'is_reserved': isReserved,
      'user_id': userId,
      'username': username,
      'user_name': userName,
      'profile_url': profileUrl,
    };
  }
}

class SeatsResponse {
  final String status;
  final String message;
  final SeatsData data;

  SeatsResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory SeatsResponse.fromJson(Map<String, dynamic> json) {
    return SeatsResponse(
      status: json['status'] ?? 'error',
      message: json['message'] ?? '',
      data: SeatsData.fromJson(json['data'] ?? {}),
    );
  }
}

class SeatsData {
  final int roomId;
  final int totalSeats;
  final int occupiedSeats;
  final int availableSeats;
  final List<Seat> seats;

  SeatsData({
    required this.roomId,
    required this.totalSeats,
    required this.occupiedSeats,
    required this.availableSeats,
    required this.seats,
  });

  factory SeatsData.fromJson(Map<String, dynamic> json) {
    List<dynamic> seatsData = json['seats'] ?? [];
    return SeatsData(
      roomId: json['room_id'] ?? 0,
      totalSeats: json['total_seats'] ?? 0,
      occupiedSeats: json['occupied_seats'] ?? 0,
      availableSeats: json['available_seats'] ?? 0,
      seats: seatsData.map((seat) => Seat.fromJson(seat)).toList(),
    );
  }
}