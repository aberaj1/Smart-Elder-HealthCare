import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'medicine_scan_screen.dart';
import 'doctor_appointment_screen.dart';
import 'emergency_screen.dart';
import 'medicine_reminder_screen.dart';
import 'medicine_stock_screen.dart';
import 'caregiver_elder_link_screen.dart';

class ElderDashboardScreen extends StatefulWidget {
  const ElderDashboardScreen({super.key});

  @override
  State<ElderDashboardScreen> createState() =>
      _ElderDashboardScreenState();
}

class _ElderDashboardScreenState
    extends State<ElderDashboardScreen> {
  User? get currentUser =>
      FirebaseAuth.instance.currentUser;

  List<Map<String, dynamic>> todayMedicines = [];
  List<Map<String, dynamic>> todayAppointments = [];

  bool isLoadingToday = true;

  @override
  void initState() {
    super.initState();
    loadTodayData();
  }

  // ============================================================
  // OPEN SCREEN
  // ============================================================

  void openScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => screen,
      ),
    ).then((_) {
      // Refresh dashboard when coming back
      loadTodayData();
    });
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  // ============================================================
  // TODAY KEY
  // ============================================================

  String getTodayKey() {
    final now = DateTime.now();

    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // LOAD TODAY'S MEDICINES + APPOINTMENTS
  // ============================================================

  Future<void> loadTodayData() async {
    final user = currentUser;

    if (user == null) {
      return;
    }

    try {
      setState(() {
        isLoadingToday = true;
      });

      // ========================================================
      // LOAD MEDICINES
      // ========================================================

      final medicineSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('medicine_reminders')
              .get();

      final medicines = <Map<String, dynamic>>[];

      final todayKey = getTodayKey();

      for (final doc in medicineSnapshot.docs) {
        final data = doc.data();

        int? hour;
        int? minute;

        if (data['hour'] != null) {
          hour = int.tryParse(
            data['hour'].toString(),
          );
        }

        if (data['minute'] != null) {
          minute = int.tryParse(
            data['minute'].toString(),
          );
        }

        // --------------------------------------------------------
        // Support old reminders using time string
        // --------------------------------------------------------

        if ((hour == null || minute == null) &&
            data['time'] != null) {
          final parsed =
              parseTimeString(
            data['time'].toString(),
          );

          if (parsed != null) {
            hour = parsed.hour;
            minute = parsed.minute;
          }
        }

        if (hour == null || minute == null) {
          continue;
        }

        String status =
            data['status']?.toString() ??
                'Pending';

        final savedStatusDate =
            data['statusDate']?.toString() ??
                '';

        // --------------------------------------------------------
        // If old status belongs to another day,
        // show Pending for today.
        // --------------------------------------------------------

        if (savedStatusDate != todayKey) {
          status = 'Pending';

          await doc.reference.update({
            'status': 'Pending',
            'statusDate': todayKey,
          });
        }

        medicines.add({
          'id': doc.id,
          'medicine':
              data['medicine']?.toString() ??
                  '',
          'foodTiming':
              data['foodTiming']?.toString() ??
                  'Before Food',
          'time':
              data['time']?.toString() ??
                  '',
          'hour': hour,
          'minute': minute,
          'status': status,
        });
      }

      // Sort medicines by time
      medicines.sort((a, b) {
        final aMinutes =
            (a['hour'] as int) * 60 +
                (a['minute'] as int);

        final bMinutes =
            (b['hour'] as int) * 60 +
                (b['minute'] as int);

        return aMinutes.compareTo(
          bMinutes,
        );
      });

      // ========================================================
      // LOAD TODAY'S DOCTOR APPOINTMENTS
      // ========================================================

      final appointmentSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('appointments')
              .get();

      final appointments =
          <Map<String, dynamic>>[];

      final now = DateTime.now();

      for (final doc
          in appointmentSnapshot.docs) {
        final data = doc.data();

        DateTime? appointmentDate;

        // Date is stored as Timestamp
        if (data['date'] is Timestamp) {
          appointmentDate =
              (data['date'] as Timestamp)
                  .toDate();
        }

        if (appointmentDate == null) {
          continue;
        }

        // Check whether appointment is today
        final isToday =
            appointmentDate.year ==
                now.year &&
            appointmentDate.month ==
                now.month &&
            appointmentDate.day ==
                now.day;

        if (!isToday) {
          continue;
        }

        appointments.add({
          'id': doc.id,
          'doctor':
              data['doctor']?.toString() ??
                  '',
          'specialization':
              data['specialization']
                      ?.toString() ??
                  '',
          'time':
              data['time']?.toString() ??
                  '',
          'timeHour':
              data['timeHour'] ?? 0,
          'timeMinute':
              data['timeMinute'] ?? 0,
        });
      }

      // Sort appointments by time
      appointments.sort((a, b) {
        final aMinutes =
            ((a['timeHour'] ?? 0) as int) *
                    60 +
                ((a['timeMinute'] ?? 0) as int);

        final bMinutes =
            ((b['timeHour'] ?? 0) as int) *
                    60 +
                ((b['timeMinute'] ?? 0) as int);

        return aMinutes.compareTo(
          bMinutes,
        );
      });

      if (!mounted) return;

      setState(() {
        todayMedicines = medicines;
        todayAppointments = appointments;
        isLoadingToday = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingToday = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load today\'s data: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // PARSE OLD TIME STRING
  // ============================================================

  TimeOfDay? parseTimeString(
    String time,
  ) {
    try {
      final parts =
          time.trim().split(' ');

      if (parts.length != 2) {
        return null;
      }

      final timePart =
          parts[0].split(':');

      if (timePart.length != 2) {
        return null;
      }

      int hour =
          int.parse(timePart[0]);

      final minute =
          int.parse(timePart[1]);

      final period =
          parts[1].toUpperCase();

      if (period == 'PM' &&
          hour != 12) {
        hour += 12;
      }

      if (period == 'AM' &&
          hour == 12) {
        hour = 0;
      }

      if (hour < 0 ||
          hour > 23 ||
          minute < 0 ||
          minute > 59) {
        return null;
      }

      return TimeOfDay(
        hour: hour,
        minute: minute,
      );
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // FORMAT TIME
  // ============================================================

  String formatMedicineTime(
    Map<String, dynamic> medicine,
  ) {
    final hour =
        medicine['hour'] as int;

    final minute =
        medicine['minute'] as int;

    final time =
        TimeOfDay(
      hour: hour,
      minute: minute,
    );

    return time.format(context);
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color getStatusColor(
    String status,
  ) {
    if (status == 'Taken') {
      return Colors.green;
    }

    if (status == 'Missed') {
      return Colors.red;
    }

    return Colors.orange;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Elder Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:
            Colors.green,
        foregroundColor:
            Colors.white,
        actions: [
          IconButton(
            onPressed: logout,
            icon:
                const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: loadTodayData,
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              // ==================================================
              // WELCOME
              // ==================================================

              const Text(
                'Welcome Elder',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Smart Elder Healthcare',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // QUICK ACCESS
              // ==================================================

              const Text(
                'Quick Access',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              // Row 1
              Row(
                children: [

                  Expanded(
                    child:
                        buildFeatureCard(
                      title:
                          'Medicine Reminder',
                      icon: Icons.alarm,
                      color:
                          Colors.blue,
                      onTap: () {
                        openScreen(
                          const MedicineReminderScreen(),
                        );
                      },
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child:
                        buildFeatureCard(
                      title:
                          'Medicine Stock',
                      icon:
                          Icons.inventory_2,
                      color:
                          Colors.orange,
                      onTap: () {
                        openScreen(
                          const MedicineStockScreen(),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Row 2
              Row(
                children: [

                  Expanded(
                    child:
                        buildFeatureCard(
                      title:
                          'Doctor Appointment',
                      icon:
                          Icons.local_hospital,
                      color:
                          Colors.green,
                      onTap: () {
                        openScreen(
                          const DoctorAppointmentScreen(),
                        );
                      },
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child:
                        buildFeatureCard(
                      title:
                          'Emergency SOS',
                      icon:
                          Icons.emergency,
                      color:
                          Colors.red,
                      onTap: () {
                        openScreen(
                          const EmergencyScreen(),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Row 3
              Row(
                children: [

                  Expanded(
                    child:
                        buildFeatureCard(
                      title:
                          'Medicine Scan',
                      icon:
                          Icons.camera_alt,
                      color:
                          Colors.purple,
                      onTap: () {
                        openScreen(
                          const MedicineScanScreen(),
                        );
                      },
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child:
                        buildFeatureCard(
                      title:
                          'Caretaker Link',
                      icon:
                          Icons.family_restroom,
                      color:
                          Colors.teal,
                      onTap: () {
                        openScreen(
                          const CaregiverElderLinkScreen(),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // ==================================================
              // TODAY'S MEDICINES
              // ==================================================

              const Text(
                'Today\'s Medicines',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              if (isLoadingToday)
                const Card(
                  child: Padding(
                    padding:
                        EdgeInsets.all(20),
                    child: Center(
                      child:
                          CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (todayMedicines.isEmpty)
                Card(
                  elevation: 2,
                  child: ListTile(
                    leading:
                        const CircleAvatar(
                      backgroundColor:
                          Colors.blue,
                      child: Icon(
                        Icons.medication,
                        color:
                            Colors.white,
                      ),
                    ),
                    title: const Text(
                      'No medicines scheduled today',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    subtitle:
                        const Text(
                      'You have no medicine reminders for today.',
                    ),
                    onTap: () {
                      openScreen(
                        const MedicineReminderScreen(),
                      );
                    },
                  ),
                )
              else
                ...todayMedicines.map(
                  (medicine) {
                    final status =
                        medicine['status']
                                ?.toString() ??
                            'Pending';

                    final statusColor =
                        getStatusColor(
                      status,
                    );

                    return Card(
                      elevation: 2,
                      margin:
                          const EdgeInsets.only(
                        bottom: 10,
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(
                          12,
                        ),
                        child: Column(
                          children: [

                            Row(
                              children: [

                                CircleAvatar(
                                  backgroundColor:
                                      Colors.blue
                                          .withOpacity(
                                    0.12,
                                  ),
                                  child:
                                      const Icon(
                                    Icons.medication,
                                    color:
                                        Colors.blue,
                                  ),
                                ),

                                const SizedBox(
                                  width: 12,
                                ),

                                Expanded(
                                  child:
                                      Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [

                                      Text(
                                        medicine[
                                                'medicine'] ??
                                            '',
                                        style:
                                            const TextStyle(
                                          fontSize:
                                              17,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 4,
                                      ),

                                      Text(
                                        'Time: ${formatMedicineTime(medicine)}',
                                      ),

                                      Text(
                                        'Timing: ${medicine['foodTiming'] ?? 'Before Food'}',
                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Container(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal:
                                        10,
                                    vertical:
                                        5,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        statusColor
                                            .withOpacity(
                                      0.1,
                                    ),
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      20,
                                    ),
                                  ),
                                  child:
                                      Text(
                                    status,
                                    style:
                                        TextStyle(
                                      color:
                                          statusColor,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 10,
                            ),

                            // Open medicine reminder
                            SizedBox(
                              width:
                                  double.infinity,
                              child:
                                  OutlinedButton
                                      .icon(
                                onPressed: () {
                                  openScreen(
                                    const MedicineReminderScreen(),
                                  );
                                },
                                icon:
                                    const Icon(
                                  Icons.alarm,
                                ),
                                label:
                                    const Text(
                                  'Open Medicine Reminder',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 15),

              // ==================================================
              // TODAY'S DOCTOR APPOINTMENTS
              // ==================================================

              const Text(
                'Today\'s Doctor Appointment',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              if (isLoadingToday)
                const SizedBox.shrink()
              else if (todayAppointments.isEmpty)
                Card(
                  elevation: 2,
                  child: ListTile(
                    leading:
                        const CircleAvatar(
                      backgroundColor:
                          Colors.green,
                      child: Icon(
                        Icons
                            .local_hospital,
                        color:
                            Colors.white,
                      ),
                    ),
                    title: const Text(
                      'No doctor appointment today',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    subtitle:
                        const Text(
                      'You have no doctor appointment scheduled for today.',
                    ),
                    onTap: () {
                      openScreen(
                        const DoctorAppointmentScreen(),
                      );
                    },
                  ),
                )
              else
                ...todayAppointments.map(
                  (appointment) {
                    return Card(
                      elevation: 2,
                      margin:
                          const EdgeInsets.only(
                        bottom: 10,
                      ),
                      child: ListTile(
                        leading:
                            const CircleAvatar(
                          backgroundColor:
                              Colors.green,
                          child: Icon(
                            Icons
                                .local_hospital,
                            color:
                                Colors.white,
                          ),
                        ),

                        title: Text(
                          'Dr. ${appointment['doctor']}',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),

                        subtitle:
                            Text(
                          '${appointment['specialization']}\n'
                          'Time: ${appointment['time']}',
                        ),

                        isThreeLine:
                            true,

                        trailing:
                            const Icon(
                          Icons
                              .arrow_forward_ios,
                          size: 16,
                        ),

                        onTap: () {
                          openScreen(
                            const DoctorAppointmentScreen(),
                          );
                        },
                      ),
                    );
                  },
                ),

              const SizedBox(height: 20),

            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FEATURE CARD
  // ============================================================

  Widget buildFeatureCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(10),
        child: SizedBox(
          height: 105,
          child: Padding(
            padding:
                const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [

                Icon(
                  icon,
                  color: color,
                  size: 32,
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  title,
                  textAlign:
                      TextAlign.center,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}