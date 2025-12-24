import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:meditrack/features/home/data/medi_schedule_service.dart';
import 'package:meditrack/services/get_current_user.dart';

import '../../../../common_modules/notification_model.dart';
import '../../../../services/notification_services.dart';
import '../../domain/med_user_data.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeInitial()) {
    on<AddUserSchedulesEvent>(_addUserSchedulesEvent);
    on<FetchUserSchedulesEvent>(_fetchUserSchedulesEvent);
  }

  FutureOr<void> _fetchUserSchedulesEvent(
      FetchUserSchedulesEvent event, Emitter<HomeState> emit) async {
    emit(HomeLoadingState()); // Optional: Show loading while processing

    try {
      // 1. Get the UUID from your UserProvider or SharedPreferences
      final String? uuid = await UserProvider().getUuid();

      if (uuid == null) {
        emit(HomeFailureState(msgFailure: "User session not found"));
        return;
      }

      // 2. Fetch real data from Firestore
      final List<MedicationModel> fetchedData =
          await MedicationService().fetchUserSchedules(uuid);

      // 3. Sync Notifications (Cancel old and create new based on Firestore data)
      await NotificationService.cancelAll();

      for (var med in fetchedData) {
        // 3. Loop through every medication and schedule notifications
        for (var med in fetchedData) {
          if (med.reminderHour != null && med.reminderMinute != null) {
            GeneralNotificationModel medicineNotice = GeneralNotificationModel(
              msgTitle: med.name,
              msgBody: "${med.dosage} - ${med.instructions}",
              date: DateTime.parse(med.createdAt),
            );

            // This function loops through reminderDays internally
            await NotificationService.createScheduledNotification(
              medicineId: med.id,
              noObj: medicineNotice,
              daysToRepeat: med.reminderDays,
              time: TimeOfDay(
                  hour: med.reminderHour!, minute: med.reminderMinute!),
            );
          }
        }
      }

      emit(HomeSuccessState(medications: fetchedData));
    } catch (e) {
      emit(HomeFailureState(msgFailure: e.toString()));
    }
  }

  FutureOr<void> _addUserSchedulesEvent(
      AddUserSchedulesEvent event, Emitter<HomeState> emit) async {
    print("--- BLOC: AddUserSchedulesEvent Started ---");

    // 1. Validation (Added check for time)
    if (event.medInfo.name.isEmpty ||
        event.medInfo.reminderDays.isEmpty ||
        event.medInfo.reminderHour == null) {
      print("--- BLOC: Validation Failed ---");
      emit(HomeFailureState(
          msgFailure: "Please provide a name, days, and time."));
      return;
    }

    try {
      emit(HomeLoadingState());
      print("--- BLOC: Loading Emitted ---");

      final String? uuid = await UserProvider().getUuid();
      print("--- BLOC: UUID found: $uuid ---");

      if (uuid == null || uuid.isEmpty) {
        print("--- BLOC: UUID is NULL/Empty ---");
        emit(HomeFailureState(msgFailure: "User session expired."));
        return;
      }

      // 2. Call Service (Use a local variable for clarity)
      final medService = MedicationService();
      print("--- BLOC: Calling MedicationService.addUserSchedule ---");
      await medService.addUserSchedule(uuid, event.medInfo);
      print("--- BLOC: MedicationService Call Finished ---");

      // 3. Schedule Notifications
      print("--- BLOC: Scheduling Notifications ---");
      GeneralNotificationModel medicineNotice = GeneralNotificationModel(
        msgTitle: event.medInfo.name,
        msgBody: "${event.medInfo.dosage} - ${event.medInfo.instructions}",
        date: DateTime.now(),
      );

      await NotificationService.createScheduledNotification(
        noObj: medicineNotice,
        daysToRepeat: List<int>.from(event.medInfo.reminderDays),
        time: TimeOfDay(
            hour: event.medInfo.reminderHour!,
            minute: event.medInfo.reminderMinute!),
        medicineId: event.medInfo.id,
      );
      print("--- BLOC: Notifications Scheduled ---");

      // 4. Update State
      // Logic: If you want the Home Page to refresh properly,
      // it's better to add the new med to the existing list or trigger a Fetch event.
      emit(HomeSuccessState(medications: [event.medInfo]));
      print("--- BLOC: Success Emitted ---");
    } catch (e, stacktrace) {
      print("--- BLOC ERROR: $e ---");
      print("--- STACKTRACE: $stacktrace ---");
      emit(HomeFailureState(
          msgFailure: "Failed to add medication: ${e.toString()}"));
    }
  }
}
