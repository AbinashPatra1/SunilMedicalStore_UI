/// Fixed home-collection time windows a customer can choose from when
/// scheduling a lab test — the store doesn't do live slot-availability
/// checking, just a stated preference that's threaded through to the
/// backend and used in the "your lab test is due today" reminder.
const List<String> kLabTestTimeSlots = [
  '7:00 AM – 10:00 AM',
  '10:00 AM – 1:00 PM',
  '1:00 PM – 4:00 PM',
  '4:00 PM – 7:00 PM',
];
