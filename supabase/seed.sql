-- Seed data for CampusLink (Cavendish University Uganda). Safe to re-run.
insert into public.help_offices (name, description, category, location, building, contact_email, open_hours, keywords) values
('Registrar''s Office', 'Registration, course add/drop, transcripts, ID cards, letters of admission.', 'admin', 'Main Block, Ground Floor', 'Main Block', 'registrar@cavendish.ac.ug', 'Mon–Fri 8:00–17:00', '{registration,transcript,id card,admission letter,add,drop,enrol,enroll,defer}'),
('Finance Office', 'Tuition payments, fee statements, payment plans, bursaries.', 'finance', 'Main Block, 1st Floor', 'Main Block', 'finance@cavendish.ac.ug', 'Mon–Fri 8:30–16:30', '{fees,tuition,payment,receipt,bursary,scholarship,balance,installment}'),
('ICT Help Desk', 'Student portal login, email, Wi‑Fi, e-learning platform issues.', 'it', 'Library Block, Room L04', 'Library Block', 'ict@cavendish.ac.ug', 'Mon–Sat 8:00–18:00', '{portal,password,wifi,email,elearning,moodle,login,laptop}'),
('Library', 'Borrowing, e-resources, study spaces, printing.', 'library', 'Library Block', 'Library Block', 'library@cavendish.ac.ug', 'Mon–Sat 8:00–21:00', '{books,borrow,ebook,journal,print,study room,research}'),
('Dean of Students', 'Welfare, accommodation, discipline, clubs and societies.', 'welfare', 'Students'' Centre', 'Students'' Centre', 'dos@cavendish.ac.ug', 'Mon–Fri 8:00–17:00', '{hostel,accommodation,welfare,club,society,complaint,discipline}'),
('Counselling & Wellness', 'Confidential counselling, mental health support, peer support.', 'health', 'Students'' Centre, Room S2', 'Students'' Centre', 'wellness@cavendish.ac.ug', 'Mon–Fri 9:00–16:00', '{counselling,counseling,stress,mental health,wellbeing,anxiety,talk}'),
('Faculty of Science & Technology Office', 'Course advising, timetables, exam queries for FST programmes.', 'academic', 'FST Block, 2nd Floor', 'FST Block', 'fst@cavendish.ac.ug', 'Mon–Fri 8:00–17:00', '{timetable,exam,results,missing marks,lecturer,course unit,fst,computing,data science}'),
('Examinations Office', 'Exam cards, results, remarking, missing marks.', 'academic', 'Main Block, 1st Floor', 'Main Block', 'exams@cavendish.ac.ug', 'Mon–Fri 8:00–17:00', '{exam card,results,remark,missing marks,supplementary,retake}'),
('Careers & Internships', 'CV reviews, internship placement, job board.', 'academic', 'Students'' Centre, Room S5', 'Students'' Centre', 'careers@cavendish.ac.ug', 'Tue–Thu 9:00–16:00', '{internship,cv,job,career,placement,interview}')
on conflict do nothing;

insert into public.clubs (name, description, contact) values
('IEEE Cavendish Student Branch', 'Tech talks, hackathons, innovation challenges.', 'ieee@cavendish.ac.ug'),
('CUUCSA', 'Cavendish University Uganda Computer Science Association.', 'cuucsa@cavendish.ac.ug'),
('Debate Society', 'Weekly debates and public speaking practice.', null),
('Drama & Arts', 'Theatre, music and visual arts.', null)
on conflict do nothing;

insert into public.pulse_polls (question, options) values
('How is your week going?', '{Great,Okay,Stressed,Overwhelmed}'),
('Which support do you need most right now?', '{Academic help,Fees/finance,Accommodation,Mental wellness}')
on conflict do nothing;
