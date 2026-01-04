import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Seat {
  final int id;
  final String status; // available, male, female, disabled, booked

  Seat({required this.id, required this.status});
}

// Controller using GetX for state management
class BusSeatsController extends GetxController {
  // Observable variables
  final RxList<Seat> _seats = <Seat>[].obs;
  final RxList<Seat> _selectedSeats = <Seat>[].obs;
  final RxInt _totalPrice = 0.obs;

  Map<String, dynamic> busDetails = {};

  // Getters
  List<Seat> get seats => _seats;
  List<Seat> get selectedSeats => _selectedSeats;
  int get totalPrice => _totalPrice.value;

  void initBusDetails(Map<String, dynamic> details) {
    busDetails = details;
    _generateSeats();
    _calculateTotalPrice();
  }

  void _generateSeats() {
    _seats.clear();

    // Generate random seat statuses for demonstration
    final List<String> statuses = ['available', 'male', 'female', 'disabled', 'booked'];

    for (int i = 1; i <= 40; i++) {
      String status;

      // First few seats are disabled reserved
      if (i <= 2) {
        status = (i % 2 == 0) ? 'disabled' : 'available';
      } else {
        // Random status for other seats
        status = statuses[i % 5];
      }

      _seats.add(Seat(id: i, status: status));
    }
  }

  void toggleSeatSelection(Seat seat) {
    // Cannot select booked seats
    if (seat.status == 'booked') return;

    if (_selectedSeats.contains(seat)) {
      _selectedSeats.remove(seat);
    } else {
      _selectedSeats.add(seat);
    }

    _calculateTotalPrice();
  }

  void _calculateTotalPrice() {
    final int seatPrice = (busDetails['fare'] != null)
        ? int.parse(busDetails['fare'].toString())
        : 15;

    _totalPrice.value = _selectedSeats.length * seatPrice;
  }

  void proceedToBooking() {
    if (_selectedSeats.isEmpty) {
      Get.snackbar(
        'Error',
        'Please select at least one seat',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Navigate to payment or passenger details screen
    Get.toNamed('/passenger-details', arguments: {
      'busDetails': busDetails,
      'selectedSeats': _selectedSeats.map((seat) => seat.id).toList(),
      'totalPrice': _totalPrice.value,
    });
  }
}