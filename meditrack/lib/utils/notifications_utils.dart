import 'package:flutter/material.dart';

int createUniqueId() {
  return DateTime.now().millisecondsSinceEpoch.remainder(100000);
}

class NotificationMultiSchedule {
  final List<int> daysOfTheWeek; // [1, 2, 3...] where 1 is Monday
  final TimeOfDay timeOfDay;

  NotificationMultiSchedule({
    required this.daysOfTheWeek,
    required this.timeOfDay,
  });
}

Future<NotificationMultiSchedule?> pickMultiSchedule(
    BuildContext context) async {
  List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  Set<int> selectedDays = {}; // Using a Set to handle multi-toggle easily
  TimeOfDay selectedTime = TimeOfDay.now();

  return showModalBottomSheet<NotificationMultiSchedule>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle Bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 24),
                const Text("Set Reminder Schedule",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Select the days and time for your medicine",
                    style: TextStyle(color: Colors.grey.shade500)),
                const SizedBox(height: 32),

                // Multi-Day Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (index) {
                    int dayValue = index + 1;
                    bool isSelected = selectedDays.contains(dayValue);
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          if (isSelected) {
                            selectedDays.remove(dayValue);
                          } else {
                            selectedDays.add(dayValue);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color:
                              isSelected ? Colors.teal : Colors.grey.shade100,
                          shape: BoxShape.circle,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                      color: Colors.teal.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4))
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          weekdays[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 40),

                // Time Picker Trigger
                InkWell(
                  onTap: () async {
                    final TimeOfDay? time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setModalState(() => selectedTime = time);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.teal.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.access_time_filled,
                            color: Colors.teal),
                        Text(
                          selectedTime.format(context),
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal),
                        ),
                        const Icon(Icons.edit, size: 18, color: Colors.teal),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: selectedDays.isEmpty
                        ? null
                        : () {
                            Navigator.pop(
                              context,
                              NotificationMultiSchedule(
                                daysOfTheWeek: selectedDays.toList(),
                                timeOfDay: selectedTime,
                              ),
                            );
                          },
                    child: const Text(
                      "Confirm Schedule",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      );
    },
  );
}
