import 'package:sunil_medical_store/features/appointments/domain/doctor.dart';
import 'package:sunil_medical_store/features/appointments/domain/doctor_repository.dart';

/// In-memory mock of [DoctorRepository] used until the backend exists.
///
/// Returns a fixed roster of doctors after a short delay so the UI exercises
/// its loading state. Weekdays use `DateTime.monday`..`DateTime.sunday`.
class MockDoctorRepository implements DoctorRepository {
  @override
  Future<List<Doctor>> doctorsAvailableThisWeek() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return const [
      Doctor(
        id: 'doc-1',
        name: 'Dr. Ananya Sharma',
        specialization: 'General Physician',
        qualification: 'MBBS, MD (Internal Medicine)',
        experienceYears: 12,
        rating: 4.8,
        consultationFee: 400,
        availableWeekdays: [
          DateTime.monday,
          DateTime.wednesday,
          DateTime.friday,
        ],
        availableTime: '10:00 AM – 1:00 PM',
      ),
      Doctor(
        id: 'doc-2',
        name: 'Dr. Rahul Verma',
        specialization: 'Pediatrician',
        qualification: 'MBBS, DCH',
        experienceYears: 9,
        rating: 4.6,
        consultationFee: 500,
        availableWeekdays: [
          DateTime.tuesday,
          DateTime.thursday,
          DateTime.saturday,
        ],
        availableTime: '5:00 PM – 8:00 PM',
      ),
      Doctor(
        id: 'doc-3',
        name: 'Dr. Meera Iyer',
        specialization: 'Dermatologist',
        qualification: 'MBBS, MD (Dermatology)',
        experienceYears: 15,
        rating: 4.9,
        consultationFee: 700,
        availableWeekdays: [DateTime.monday, DateTime.thursday],
        availableTime: '11:00 AM – 2:00 PM',
      ),
      Doctor(
        id: 'doc-4',
        name: 'Dr. Sanjay Patel',
        specialization: 'Cardiologist',
        qualification: 'MBBS, MD, DM (Cardiology)',
        experienceYears: 20,
        rating: 4.7,
        consultationFee: 900,
        availableWeekdays: [DateTime.wednesday, DateTime.saturday],
        availableTime: '9:00 AM – 12:00 PM',
      ),
      Doctor(
        id: 'doc-5',
        name: 'Dr. Priya Nair',
        specialization: 'Gynecologist',
        qualification: 'MBBS, MS (Obstetrics & Gynaecology)',
        experienceYears: 11,
        rating: 4.8,
        consultationFee: 600,
        availableWeekdays: [
          DateTime.tuesday,
          DateTime.friday,
          DateTime.sunday,
        ],
        availableTime: '4:00 PM – 7:00 PM',
      ),
    ];
  }
}
