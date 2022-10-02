import 'package:booking_calendar/src/components/booking_dialog.dart';
import 'package:booking_calendar/src/components/booking_explanation.dart';
import 'package:booking_calendar/src/components/booking_slot.dart';
import 'package:booking_calendar/src/components/common_button.dart';
import 'package:booking_calendar/src/components/common_card.dart';
import 'package:booking_calendar/src/core/booking_controller.dart';
import 'package:booking_calendar/src/model/booking_service.dart';
import 'package:booking_calendar/src/model/enums.dart' as bc;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:table_calendar/table_calendar.dart' as tc
    show StartingDayOfWeek;
import 'package:booking_calendar/src/util/booking_util.dart';

class BookingCalendarMain extends StatefulWidget {
  const BookingCalendarMain({
    Key? key,
    required this.getBookingStream,
    required this.convertStreamResultToDateTimeRanges,
    required this.uploadBooking,
    this.bookingExplanation,
    this.bookingGridCrossAxisCount,
    this.bookingGridChildAspectRatio,
    this.formatDateTime,
    this.bookingButtonText,
    this.bookingButtonColor,
    this.bookedSlotColor,
    this.selectedSlotColor,
    this.availableSlotColor,
    this.bookedSlotText,
    this.selectedSlotText,
    this.availableSlotText,
    this.gridScrollPhysics,
    this.loadingWidget,
    this.errorWidget,
    this.uploadingWidget,
    this.pauseSlotColor,
    this.pauseSlotText,
    this.hideBreakTime = false,
    this.locale,
    this.startingDayOfWeek,
    this.disabledDays,
    this.onBookingIsPressed,
  }) : super(key: key);

  final Stream<dynamic>? Function(
      {required DateTime start, required DateTime end}) getBookingStream;
  final Future<dynamic> Function({required BookingService newBooking})
      uploadBooking;
  final List<DateTimeRange> Function({required dynamic streamResult})
      convertStreamResultToDateTimeRanges;

  ///Customizable
  final Widget? bookingExplanation;
  final int? bookingGridCrossAxisCount;
  final double? bookingGridChildAspectRatio;
  final String Function(DateTime dt)? formatDateTime;
  final String? bookingButtonText;
  final Color? bookingButtonColor;
  final Color? bookedSlotColor;
  final Color? selectedSlotColor;
  final Color? availableSlotColor;
  final Color? pauseSlotColor;

  final String? bookedSlotText;
  final String? selectedSlotText;
  final String? availableSlotText;
  final String? pauseSlotText;

  final ScrollPhysics? gridScrollPhysics;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Widget? uploadingWidget;

  final bool? hideBreakTime;

  final String? locale;
  final bc.StartingDayOfWeek? startingDayOfWeek;
  final List<int>? disabledDays;

  final void Function(DateTime)? onBookingIsPressed;

  @override
  State<BookingCalendarMain> createState() => _BookingCalendarMainState();
}

class _BookingCalendarMainState extends State<BookingCalendarMain> {
  late BookingController controller;
  final now = DateTime.now();

  @override
  void initState() {
    super.initState();
    controller = context.read<BookingController>();
    final firstDay = calculateFirstDay();

    startOfDay = firstDay.startOfDayService(controller.serviceOpening!);
    endOfDay = firstDay.endOfDayService(controller.serviceClosing!);
    _focusedDay = firstDay;
    _selectedDay = firstDay;
  }

  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;

  late DateTime _selectedDay;
  late DateTime _focusedDay;
  late DateTime startOfDay;
  late DateTime endOfDay;

  void selectNewDateRange() {
    startOfDay = _selectedDay.startOfDayService(controller.serviceOpening!);
    endOfDay = _selectedDay
        .add(const Duration(days: 1))
        .endOfDayService(controller.serviceClosing!);

    controller.base = startOfDay;
    controller.resetSelectedSlot();
  }

  DateTime calculateFirstDay() {
    final now = DateTime.now();
    if (widget.disabledDays != null) {
      return widget.disabledDays!.contains(now.weekday)
          ? now.add(Duration(days: getFirstMissingDay(now.weekday)))
          : now;
    } else {
      return DateTime.now();
    }
  }

  int getFirstMissingDay(int now) {
    for (var i = 1; i <= 7; i++) {
      if (!widget.disabledDays!.contains(now + i)) {
        return i;
      }
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    controller = context.watch<BookingController>();

    return Consumer<BookingController>(
      builder: (_, controller, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: (controller.isUploading)
            ? widget.uploadingWidget ?? const BookingDialog()
            : Column(
                children: [
                  CommonCard(
                    child: TableCalendar(
                      startingDayOfWeek: widget.startingDayOfWeek?.toTC() ??
                          tc.StartingDayOfWeek.monday,
                      enabledDayPredicate: (day) {
                        if (widget.disabledDays == null) return true;
                        return !widget.disabledDays!.contains(day.weekday);
                      },
                      locale: widget.locale,
                      firstDay: calculateFirstDay(),
                      lastDay: DateTime.now().add(const Duration(days: 1000)),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      calendarStyle:
                          const CalendarStyle(isTodayHighlighted: true),
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        if (!isSameDay(_selectedDay, selectedDay)) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                          selectNewDateRange();
                        }
                      },
                      onFormatChanged: (format) {
                        if (_calendarFormat != format) {
                          setState(() {
                            _calendarFormat = format;
                          });
                        }
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  widget.bookingExplanation ??
                      Wrap(
                        alignment: WrapAlignment.spaceAround,
                        spacing: 8.0,
                        runSpacing: 8.0,
                        direction: Axis.horizontal,
                        children: [
                          BookingExplanation(
                              color: widget.availableSlotColor ??
                                  Colors.greenAccent,
                              text: widget.availableSlotText ?? "Available"),
                          BookingExplanation(
                              color: widget.selectedSlotColor ??
                                  Colors.orangeAccent,
                              text: widget.selectedSlotText ?? "Selected"),
                          BookingExplanation(
                              color: widget.bookedSlotColor ?? Colors.redAccent,
                              text: widget.bookedSlotText ?? "Booked"),
                          if (widget.hideBreakTime != null &&
                              widget.hideBreakTime == false)
                            BookingExplanation(
                                color: widget.pauseSlotColor ?? Colors.grey,
                                text: widget.pauseSlotText ?? "Break"),
                        ],
                      ),
                  const SizedBox(height: 8),
                  StreamBuilder<dynamic>(
                    stream: widget.getBookingStream(
                        start: startOfDay, end: endOfDay),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return widget.errorWidget ??
                            Center(
                              child: Text(snapshot.error.toString()),
                            );
                      }

                      if (!snapshot.hasData) {
                        return widget.loadingWidget ??
                            const Center(child: CircularProgressIndicator());
                      }

                      ///this snapshot should be converted to List<DateTimeRange>
                      final data = snapshot.requireData;
                      controller.generateBookedSlots(
                          widget.convertStreamResultToDateTimeRanges(
                              streamResult: data));

                      return Expanded(
                        child: GridView.builder(
                          physics: widget.gridScrollPhysics ??
                              const BouncingScrollPhysics(),
                          itemCount: controller.allBookingSlots.length,
                          itemBuilder: (context, index) {
                            final slot =
                                controller.allBookingSlots.elementAt(index);
                            return GestureDetector(
                              onTap: () {
                                print("tapped slot");
                                if (controller.isSlotBooked(index)) {
                                  //Blocked
                                  if (widget.onBookingIsPressed != null) {
                                    widget.onBookingIsPressed!(slot);
                                  }
                                }
                              },
                              child: BookingSlot(
                                hideBreakSlot: widget.hideBreakTime,
                                pauseSlotColor: widget.pauseSlotColor,
                                availableSlotColor: widget.availableSlotColor,
                                bookedSlotColor: widget.bookedSlotColor,
                                selectedSlotColor: widget.selectedSlotColor,
                                isPauseTime: controller.isSlotInPauseTime(slot),
                                isBooked: controller.isSlotBooked(index),
                                isSelected: index == controller.selectedSlot,
                                onTap: () => controller.selectSlot(index),
                                child: Center(
                                  child: Text(
                                    widget.formatDateTime?.call(slot) ??
                                        BookingUtil.formatDateTime(slot),
                                  ),
                                ),
                              ),
                            );
                          },
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                widget.bookingGridCrossAxisCount ?? 3,
                            childAspectRatio:
                                widget.bookingGridChildAspectRatio ?? 1.5,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  CommonButton(
                    text: widget.bookingButtonText ?? 'BOOK',
                    onTap: () async {
                      controller.toggleUploading();
                      await widget.uploadBooking(
                          newBooking:
                              controller.generateNewBookingForUploading());
                      controller.toggleUploading();
                      controller.resetSelectedSlot();
                    },
                    isDisabled: controller.selectedSlot == -1,
                    buttonActiveColor: widget.bookingButtonColor,
                  ),
                ],
              ),
      ),
    );
  }
}
