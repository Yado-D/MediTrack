import 'dart:collection';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meditrack/config/routes/name.dart';
import 'package:meditrack/features/home/domain/med_user_data.dart';
import 'package:meditrack/features/home/presentation/bloc/home_bloc.dart';
import 'package:meditrack/features/home/presentation/widget/home_widget.dart';
import 'package:meditrack/services/get_current_user.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    UserProvider().initUser();
    context.read<HomeBloc>().add(FetchUserSchedulesEvent());
  }

  fetchUserMed() async {
    if (mounted) {
      context.read<HomeBloc>().add(FetchUserSchedulesEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    print("...............................user - > $user");
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocConsumer<HomeBloc, HomeState>(
          listener: (context, state) {
            if (state is HomeFailureState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.msgFailure ?? "An error occurred"),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            List<MedicationModel> meds = [];
            if (state is HomeSuccessState) {
              meds = state.medications;
            }

            double totalScheduled =
                meds.fold(0, (sum, item) => sum + item.reminderDays.length);
            double totalTaken =
                meds.fold(0, (sum, item) => sum + (item.pillsTaken ?? 0));
            double percentage = totalScheduled > 0
                ? (totalTaken / totalScheduled).clamp(0.0, 1.0)
                : 0.0;

            final groupedMeds = SplayTreeMap<String, List<MedicationModel>>();
            for (var med in meds) {
              String hour = med.reminderHour.toString().padLeft(2, '0');
              String minute = med.reminderMinute.toString().padLeft(2, '0');
              String timeKey = "$hour:$minute";
              groupedMeds.putIfAbsent(timeKey, () => []).add(med);
            }

            return Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () async => fetchUserMed(),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Consumer<UserProvider>(
                        builder: (BuildContext context, UserProvider value,
                            Widget? child) {
                          final username = context.select<UserProvider, String>(
                              (provider) =>
                                  provider.user?.username ?? "Member");
                          return _buildHeader(username);
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildDateSelector(),
                      const SizedBox(height: 10),
                      _buildNotificationWarning(),
                      _buildProgressCard(percentage),
                      const SizedBox(height: 20),
                      _buildVaccinePromo(),
                      const SizedBox(height: 30),
                      if (meds.isEmpty && state is! HomeLoadingState)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 50),
                            child: Text("No medications scheduled yet."),
                          ),
                        )
                      else
                        ...groupedMeds.entries.map((entry) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(entry.key,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 15),
                                ...entry.value.map((med) => MedicationCard(
                                      name: med.name,
                                      dose:
                                          "${med.dosage} - ${med.instructions}",
                                      days:
                                          "${med.reminderDays.length} days/week",
                                      icon: Icon(Icons.medication,
                                          color:
                                              Color(int.parse(med.typeColor))),
                                    )),
                                const SizedBox(height: 20),
                              ],
                            )),
                    ],
                  ),
                ),
                if (state is HomeLoadingState)
                  Container(
                    color: Colors.white.withOpacity(0.5),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.pushNamed(context, NamedRoutes.AddMedicinePage),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildNotificationWarning() {
    return FutureBuilder<bool>(
      future: AwesomeNotifications().isNotificationAllowed(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == false) {
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.orange.shade100),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.orange),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Reminders are off. Tap to enable.",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await AwesomeNotifications()
                        .requestPermissionToSendNotifications();
                    setState(() {});
                  },
                  child: const Text("Enable",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildProgressCard(double percent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Your plan\nis in progress!",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("${(percent * 100).toInt()}% of weekly doses taken",
                    style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          ),
          CircularPercentIndicator(
            radius: 45.0,
            lineWidth: 8.0,
            percent: percent,
            center: Text("${(percent * 100).toInt()}%",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            progressColor: Colors.greenAccent.shade400,
            backgroundColor: Colors.grey.shade100,
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
          )
        ],
      ),
    );
  }

  Widget _buildHeader(String username) {
    return Row(
      children: [
        Text("Hey, ${username}!",
            style: TextStyle(color: Colors.grey.shade500)),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () {},
        ),
        const SizedBox(width: 10),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          onSelected: (value) {
            if (value == 'logout') {
              showLogoutDialog(context);
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 20, color: Colors.black),
                  SizedBox(width: 10),
                  Text("Settings"),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20, color: Colors.red),
                  SizedBox(width: 10),
                  Text("Logout", style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Row(
      children: [
        const Text("Wednesday",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        Icon(Icons.keyboard_arrow_down, size: 32, color: Colors.grey.shade700),
      ],
    );
  }

  Widget _buildVaccinePromo() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFA8E6CF), Color(0xFFDCEDC1)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const ListTile(
        leading: Icon(Icons.vaccines, color: Colors.blue, size: 40),
        title: Text("Get vaccinated",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text("Nearest vaccination center",
            style: TextStyle(color: Colors.white70)),
        trailing: Icon(Icons.close, color: Colors.white, size: 18),
      ),
    );
  }
}
