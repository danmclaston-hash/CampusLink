import 'models.dart';

/// Demo-mode content. Mirrors supabase/seed.sql so both modes feel the same.
class SeedData {
  static final now = DateTime.now();

  static final offices = <HelpOffice>[
    const HelpOffice(
      id: 'off-registrar',
      name: "Registrar's Office",
      description: 'Registration, course add/drop, transcripts, ID cards, admission letters.',
      category: 'admin',
      location: 'Main Block, Ground Floor',
      building: 'Main Block',
      contactEmail: 'registrar@cavendish.ac.ug',
      openHours: 'Mon–Fri 8:00–17:00',
      keywords: ['registration', 'transcript', 'id card', 'admission letter', 'add', 'drop', 'enrol', 'defer', 'register'],
    ),
    const HelpOffice(
      id: 'off-finance',
      name: 'Finance Office',
      description: 'Tuition payments, fee statements, payment plans, bursaries.',
      category: 'finance',
      location: 'Main Block, 1st Floor',
      building: 'Main Block',
      contactEmail: 'finance@cavendish.ac.ug',
      openHours: 'Mon–Fri 8:30–16:30',
      keywords: ['fees', 'tuition', 'payment', 'receipt', 'bursary', 'scholarship', 'balance', 'installment', 'pay', 'money'],
    ),
    const HelpOffice(
      id: 'off-ict',
      name: 'ICT Help Desk',
      description: 'Student portal login, email, Wi‑Fi, e-learning platform issues.',
      category: 'it',
      location: 'Library Block, Room L04',
      building: 'Library Block',
      contactEmail: 'ict@cavendish.ac.ug',
      openHours: 'Mon–Sat 8:00–18:00',
      keywords: ['portal', 'password', 'wifi', 'email', 'elearning', 'moodle', 'login', 'laptop', 'internet', 'reset'],
    ),
    const HelpOffice(
      id: 'off-library',
      name: 'Library',
      description: 'Borrowing, e-resources, study spaces, printing.',
      category: 'library',
      location: 'Library Block',
      building: 'Library Block',
      contactEmail: 'library@cavendish.ac.ug',
      openHours: 'Mon–Sat 8:00–21:00',
      keywords: ['books', 'borrow', 'ebook', 'journal', 'print', 'study room', 'research', 'quiet'],
    ),
    const HelpOffice(
      id: 'off-dos',
      name: 'Dean of Students',
      description: 'Welfare, accommodation, discipline, clubs and societies.',
      category: 'welfare',
      location: "Students' Centre",
      building: "Students' Centre",
      contactEmail: 'dos@cavendish.ac.ug',
      openHours: 'Mon–Fri 8:00–17:00',
      keywords: ['hostel', 'accommodation', 'welfare', 'club', 'society', 'complaint', 'discipline', 'room'],
    ),
    const HelpOffice(
      id: 'off-wellness',
      name: 'Counselling & Wellness',
      description: 'Confidential counselling, mental health support, peer support.',
      category: 'health',
      location: "Students' Centre, Room S2",
      building: "Students' Centre",
      contactEmail: 'wellness@cavendish.ac.ug',
      openHours: 'Mon–Fri 9:00–16:00',
      keywords: ['counselling', 'counseling', 'stress', 'mental health', 'wellbeing', 'anxiety', 'talk', 'depressed', 'sad'],
    ),
    const HelpOffice(
      id: 'off-fst',
      name: 'Faculty of Science & Technology Office',
      description: 'Course advising, timetables, exam queries for FST programmes.',
      category: 'academic',
      location: 'FST Block, 2nd Floor',
      building: 'FST Block',
      contactEmail: 'fst@cavendish.ac.ug',
      openHours: 'Mon–Fri 8:00–17:00',
      keywords: ['timetable', 'exam', 'results', 'missing marks', 'lecturer', 'course unit', 'fst', 'computing', 'data science', 'advising'],
    ),
    const HelpOffice(
      id: 'off-exams',
      name: 'Examinations Office',
      description: 'Exam cards, results, remarking, missing marks.',
      category: 'academic',
      location: 'Main Block, 1st Floor',
      building: 'Main Block',
      contactEmail: 'exams@cavendish.ac.ug',
      openHours: 'Mon–Fri 8:00–17:00',
      keywords: ['exam card', 'results', 'remark', 'missing marks', 'supplementary', 'retake', 'grades'],
    ),
    const HelpOffice(
      id: 'off-careers',
      name: 'Careers & Internships',
      description: 'CV reviews, internship placement, job board.',
      category: 'academic',
      location: "Students' Centre, Room S5",
      building: "Students' Centre",
      contactEmail: 'careers@cavendish.ac.ug',
      openHours: 'Tue–Thu 9:00–16:00',
      keywords: ['internship', 'cv', 'job', 'career', 'placement', 'interview', 'work'],
    ),
  ];

  static final announcements = <Announcement>[
    Announcement(
      id: 'ann-1',
      title: 'Innovation Challenge 2026 – live demos on 4 Nov',
      body: 'IEEE Cavendish & CUUCSA invite all students to the Innovation Challenge finals. Demos and 2‑minute pitches start at 10:00 in the Main Hall.',
      category: 'events',
      isPinned: true,
      createdAt: now.subtract(const Duration(hours: 5)),
    ),
    Announcement(
      id: 'ann-2',
      title: 'Semester 1 exam timetable released',
      body: 'The draft exam timetable is now on the student portal. Report clashes to the FST office before Friday.',
      category: 'academic',
      audience: 'faculty:FST',
      createdAt: now.subtract(const Duration(days: 1)),
    ),
    Announcement(
      id: 'ann-3',
      title: 'Fee payment deadline extended',
      body: 'The Finance Office has extended the 60% tuition deadline to 20 November. Visit Main Block, 1st Floor for payment plans.',
      category: 'finance',
      createdAt: now.subtract(const Duration(days: 2)),
    ),
    Announcement(
      id: 'ann-4',
      title: 'Library weekend hours',
      body: 'The library now opens Saturdays 8:00–21:00 during the exam period.',
      category: 'general',
      createdAt: now.subtract(const Duration(days: 4)),
    ),
    Announcement(
      id: 'ann-5',
      title: 'First-years: orientation follow-up session',
      body: 'Missed orientation? Join the catch-up session Thursday 14:00 at the Students\' Centre. Buddies will be there to help you settle in.',
      category: 'welfare',
      audience: 'year:1',
      createdAt: now.subtract(const Duration(days: 5)),
    ),
  ];

  static final tutors = <Profile>[
    const Profile(id: 'u-tutor-1', fullName: 'Amina Nakato', programme: 'BDSAI', yearOfStudy: 3, isTutor: true, tutorSubjects: ['Statistics', 'Python', 'Data Analysis'], isBuddyMentor: true),
    const Profile(id: 'u-tutor-2', fullName: 'Brian Okello', programme: 'BSc Computer Science', yearOfStudy: 4, isTutor: true, tutorSubjects: ['Java', 'Databases', 'Networks']),
    const Profile(id: 'u-tutor-3', fullName: 'Grace Achieng', programme: 'BIT', yearOfStudy: 3, isTutor: true, tutorSubjects: ['Web Development', 'UI/UX'], isBuddyMentor: true),
    const Profile(id: 'u-tutor-4', fullName: 'Samuel Mugisha', programme: 'BDSAI', yearOfStudy: 2, isTutor: true, tutorSubjects: ['Calculus', 'Linear Algebra']),
  ];

  static final studyGroups = <StudyGroup>[
    const StudyGroup(id: 'sg-1', name: 'BDA2207 Visualisation crew', courseCode: 'BDA2207', description: 'Weekly practice with pandas and matplotlib for the CATs.', meetingTime: 'Tue 16:00', location: 'Library Room 3', ownerId: 'u-tutor-1', memberIds: ['u-tutor-1', 'u-tutor-4']),
    const StudyGroup(id: 'sg-2', name: 'Research Methods proposal clinic', courseCode: 'RMC2101', description: 'Peer review each other\'s problem statements and objectives.', meetingTime: 'Thu 14:00', location: 'FST Block Lab 2', ownerId: 'u-tutor-3', memberIds: ['u-tutor-3']),
    const StudyGroup(id: 'sg-3', name: 'Java fundamentals', courseCode: 'CSC1203', description: 'OOP, collections and exam past papers.', meetingTime: 'Sat 10:00', location: 'Online (Meet)', ownerId: 'u-tutor-2', memberIds: ['u-tutor-2']),
  ];

  static final polls = <PulsePoll>[
    const PulsePoll(id: 'poll-1', question: 'How is your week going?', options: ['Great', 'Okay', 'Stressed', 'Overwhelmed'], counts: [14, 31, 22, 7]),
    const PulsePoll(id: 'poll-2', question: 'Which support do you need most right now?', options: ['Academic help', 'Fees / finance', 'Accommodation', 'Mental wellness'], counts: [26, 19, 8, 12]),
  ];

  static final events = <CampusEvent>[
    CampusEvent(id: 'ev-1', title: 'Innovation Challenge Finals', description: 'Live demos and pitches. Come support your classmates!', startsAt: DateTime(now.year, now.month, now.day + 1, 10), location: 'Main Hall', organiser: 'IEEE Cavendish'),
    CampusEvent(id: 'ev-2', title: 'CUUCSA Hack Night', description: 'Bring a laptop, build something, pizza included.', startsAt: DateTime(now.year, now.month, now.day + 3, 17), location: 'FST Lab 1', organiser: 'CUUCSA'),
    CampusEvent(id: 'ev-3', title: 'Careers Fair', description: 'Meet 20+ employers hiring interns and graduates.', startsAt: DateTime(now.year, now.month, now.day + 8, 9), location: "Students' Centre", organiser: 'Careers Office'),
    CampusEvent(id: 'ev-4', title: 'Wellness Wednesday: Exam stress workshop', description: 'Practical techniques for staying calm during exams.', startsAt: DateTime(now.year, now.month, now.day + 5, 13), location: "Students' Centre S2", organiser: 'Counselling & Wellness'),
  ];

  static final clubs = <Club>[
    const Club(id: 'club-1', name: 'IEEE Cavendish Student Branch', description: 'Tech talks, hackathons, innovation challenges.', contact: 'ieee@cavendish.ac.ug', memberCount: 86),
    const Club(id: 'club-2', name: 'CUUCSA', description: 'Cavendish University Uganda Computer Science Association.', contact: 'cuucsa@cavendish.ac.ug', memberCount: 140),
    const Club(id: 'club-3', name: 'Debate Society', description: 'Weekly debates and public speaking practice.', memberCount: 42),
    const Club(id: 'club-4', name: 'Drama & Arts', description: 'Theatre, music and visual arts.', memberCount: 35),
    const Club(id: 'club-5', name: 'Football Club', description: 'Training Tue/Thu 17:00 at the pitch.', memberCount: 60),
  ];

  static final timetable = <TimetableEntry>[
    const TimetableEntry(id: 'tt-1', courseCode: 'BDA2207', courseName: 'Data Analysis & Visualization', dayOfWeek: 1, startTime: '08:00', endTime: '11:00', room: 'FST Lab 2', lecturer: 'Dr. K. Ssemakula'),
    const TimetableEntry(id: 'tt-2', courseCode: 'RMC2101', courseName: 'Research Methodology in Computing', dayOfWeek: 2, startTime: '14:00', endTime: '17:00', room: 'LT 1', lecturer: 'Ms. R. Namara'),
    const TimetableEntry(id: 'tt-3', courseCode: 'BDA2205', courseName: 'Machine Learning I', dayOfWeek: 3, startTime: '09:00', endTime: '12:00', room: 'FST Lab 1', lecturer: 'Mr. J. Odongo'),
    const TimetableEntry(id: 'tt-4', courseCode: 'BDA2203', courseName: 'Statistics for Data Science', dayOfWeek: 4, startTime: '11:00', endTime: '13:00', room: 'LT 3', lecturer: 'Dr. P. Kiiza'),
  ];
}
