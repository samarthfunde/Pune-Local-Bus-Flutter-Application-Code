// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:pmpml_app/screens/buse_model.dart';


// // Main Bus Seats Screen that shows after search
// class BusSeatsScreen extends StatefulWidget {
//   final Map<String, dynamic> busDetails;

//   const BusSeatsScreen({Key? key, required this.busDetails}) : super(key: key);

//   @override
//   State<BusSeatsScreen> createState() => _BusSeatsScreenState();
// }

// class _BusSeatsScreenState extends State<BusSeatsScreen> {
//   // Controller to manage state
//   final BusSeatsController controller = Get.put(BusSeatsController());

//   @override
//   void initState() {
//     super.initState();
//     // Initialize controller with bus details
//     controller.initBusDetails(widget.busDetails);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(60),
//         child: AppBar(
//           flexibleSpace: Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Colors.blue, Colors.lightBlueAccent],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//             child: AppBar(
//               centerTitle: true,
//               backgroundColor: Colors.transparent.withOpacity(0.8),
//               elevation: 0,
//               title: const Text(
//                 'Select Seats',
//                 style: TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//               leading: IconButton(
//                 icon: const Icon(Icons.arrow_back, color: Colors.white),
//                 onPressed: () => Get.back(),
//               ),
//             ),
//           ),
//         ),
//       ),
//       body: Column(
//         children: [
//           // Bus info section
//           _buildBusInfoSection(),
//           // Seat legend
//           _buildSeatLegend(),
//           // Seats layout
//           Expanded(
//             child: _buildSeatsLayout(),
//           ),
//           // Bottom booking bar
//           _buildBottomBar(),
//         ],
//       ),
//     );
//   }

//   Widget _buildBusInfoSection() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.2),
//             blurRadius: 5,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             widget.busDetails['route_name'] ?? 'Bus Route',
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 '${widget.busDetails['departureTime'] ?? '10:00'} - ${widget.busDetails['arrivalTime'] ?? '11:00'}',
//                 style: const TextStyle(
//                   fontSize: 16,
//                   color: Colors.black87,
//                 ),
//               ),
//               Text(
//                 '₹${widget.busDetails['fare'] ?? '15'}',
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.red,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSeatLegend() {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade100,
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: [
//           _legendItem(Colors.grey.shade300, 'Available'),
//           _legendItem(Colors.blue.shade300, 'Male'),
//           _legendItem(Colors.pink.shade300, 'Female'),
//           _legendItem(Colors.purple.shade300, 'Disabled'),
//           _legendItem(Colors.grey.shade700, 'Booked'),
//         ],
//       ),
//     );
//   }

//   Widget _legendItem(Color color, String label) {
//     return Row(
//       children: [
//         Container(
//           width: 16,
//           height: 16,
//           decoration: BoxDecoration(
//             color: color,
//             borderRadius: BorderRadius.circular(2),
//           ),
//         ),
//         const SizedBox(width: 4),
//         Text(
//           label,
//           style: const TextStyle(fontSize: 12),
//         ),
//       ],
//     );
//   }

//   Widget _buildSeatsLayout() {
//     return Obx(() {
//       return SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             // Driver section
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.grey),
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                   child: const Row(
//                     children: [
//                       Icon(Icons.airline_seat_recline_normal),
//                       SizedBox(width: 4),
//                       Text('Driver'),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             // Bus seats layout
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.grey.shade300),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Column(
//                 children: [
//                   // First row with 10 seats
//                   _buildSeatRow(0, 10),
//                   const SizedBox(height: 16), // Aisle
//                   // Second row with 10 seats
//                   _buildSeatRow(10, 20),
//                   const SizedBox(height: 16), // Aisle
//                   // Third row with 10 seats
//                   _buildSeatRow(20, 30),
//                   const SizedBox(height: 16), // Aisle
//                   // Fourth row with 10 seats
//                   _buildSeatRow(30, 40),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       );
//     });
//   }

//   Widget _buildSeatRow(int start, int end) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: List.generate(
//         end - start,
//         (index) {
//           final seatIndex = start + index;
//           final seat = controller.seats[seatIndex];

//           // Determine seat color based on status
//           Color seatColor;
//           switch (seat.status) {
//             case 'male':
//               seatColor = Colors.blue.shade300;
//               break;
//             case 'female':
//               seatColor = Colors.pink.shade300;
//               break;
//             case 'disabled':
//               seatColor = Colors.purple.shade300;
//               break;
//             case 'booked':
//               seatColor = Colors.grey.shade700;
//               break;
//             default:
//               seatColor = Colors.grey.shade300;
//           }

//           // Border for selected seat
//           Border? border;
//           if (controller.selectedSeats.contains(seat)) {
//             border = Border.all(color: Colors.green, width: 2);
//           }

//           return GestureDetector(
//             onTap: () => controller.toggleSeatSelection(seat),
//             child: Container(
//               width: 30,
//               height: 30,
//               margin: const EdgeInsets.all(2),
//               decoration: BoxDecoration(
//                 color: seatColor,
//                 borderRadius: BorderRadius.circular(4),
//                 border: border,
//               ),
//               child: Center(
//                 child: Text(
//                   '${seat.id}',
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: seat.status == 'booked' ? Colors.white : Colors.black87,
//                   ),
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildBottomBar() {
//     return Obx(() {
//       return Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.3),
//               blurRadius: 10,
//               offset: const Offset(0, -2),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             Expanded(
//               flex: 3,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     '${controller.selectedSeats.length} Seats Selected',
//                     style: const TextStyle(fontSize: 16),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     '₹${controller.totalPrice}',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.red,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Expanded(
//               flex: 2,
//               child: ElevatedButton(
//                 onPressed: controller.selectedSeats.isEmpty
//                     ? null
//                     : () => controller.proceedToBooking(),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.red,
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 child: const Text(
//                   'Continue',
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     });
//   }
// }