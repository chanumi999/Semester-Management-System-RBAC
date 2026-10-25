-- Rajarata University of Sri Lanka
-- Faculty of Applied Sciences
-- Department of Computing
-- Group Project - Binary Brains
-- Semester Management Database 

-- create database
create database rjt_as_sm_db;
use rjt_as_sm_db;

-- degree program
create table degree_program (
    degree_code varchar(20) primary key,
    degree_name varchar(120) not null,
    degree_type enum('general', 'honours') not null default 'honours',
    duration_years enum ('3','4') not null
) engine innodb;

-- semester
create table semester (
    semester_id varchar(20) primary key,
    degree_code varchar(20) not null,
    academic_year varchar(15) not null,
    semester_name varchar(50) not null,
    start_date date not null,
    end_date date not null,
    foreign key (degree_code) references degree_program(degree_code) on update cascade on delete restrict,
    check (end_date > start_date),
    unique (degree_code, academic_year, semester_name)
) engine innodb;

-- lecturer superclass and subclasses
create table lecturer (
    lecturer_id varchar(20) primary key,
    full_name varchar(150) not null,
    preferred_day enum ('monday', 'tuesday', 'thursday', 'friday') null,
    preferred_time varchar(50) null,
    is_pref_approved_by_hod boolean not null default false,
    lecturer_type enum ('internal', 'visiting') not null,
    is_active boolean not null default true
) engine innodb;

create table internal_lecturer (
    lecturer_id varchar(20) primary key,
    designation varchar(80) not null,
    office_room varchar(30) null,
    foreign key (lecturer_id) references lecturer (lecturer_id) on update cascade on delete cascade
) engine innodb;

create table visiting_lecturer (
    lecturer_id varchar(20) primary key,
    email varchar(50) not null unique,
    phone varchar(15) not null,
    home_address text null,
    main_workplace varchar(150) null,
    can_conduct_online boolean not null default true,
    foreign key (lecturer_id) references lecturer (lecturer_id) on update cascade on delete cascade
) engine innodb;

-- course
create table course (
    course_code varchar(20) primary key,
    course_title varchar(150) not null,
    degree_stream enum('it', 'cs') not null,
    credits int not null,
    ca_marks int not null default 40 check (ca_marks in (30, 40)),
    final_marks int not null default 60 check (final_marks in (60, 70)),
    semester_id varchar(20) not null,
    lecturer_id varchar(20) not null,
    foreign key (semester_id) references semester(semester_id) on update cascade on delete restrict,
    foreign key (lecturer_id) references lecturer (lecturer_id) on update cascade on delete restrict,
    check ((ca_marks + final_marks) = 100)
) engine innodb;

-- lecture halls
create table lecture_hall (
    hall_no varchar(20) primary key,
    hall_name varchar(100) not null,
    capacity int not null check (capacity > 0),
    check (hall_no in ('L8', 'L11', 'auditorium hall'))
) engine innodb;

-- laboratories
create table laboratory (
    lab_no varchar(20) primary key,
    lab_name varchar(100) not null,
    capacity int not null check (capacity > 0),
    designated_stream enum('it', 'cs') not null
) engine innodb;

-- demonstrator
create table demonstrator (
    demo_id varchar(20) primary key,
    full_name varchar(150) not null,
    email varchar(120) not null unique,
    phone varchar(20) not null
) engine innodb;

-- practical session
create table practical_session (
    course_code varchar(20) not null,
    session_no varchar(20) not null,
    session_title varchar(120) not null,
    lab_no varchar(20) not null,
    demo_id varchar(20) not null,
    session_day enum('monday', 'tuesday','wednesday','thursday', 'friday') not null ,
    start_time time not null,
    end_time time not null,
    primary key (course_code, session_no),
    foreign key (course_code) references course (course_code) on update cascade on delete cascade,
    foreign key (lab_no) references laboratory(lab_no) on update cascade on delete restrict,
    foreign key (demo_id) references demonstrator(demo_id) on update cascade on delete restrict,
    check (end_time > start_time)
) engine innodb;

-- combined session
create table combined_session (
    combined_session_id varchar(20) primary key,
    session_name varchar(150) not null,
    hall_no varchar(20) not null,
    lecturer_id varchar(20) not null,
    day_of_week enum('monday', 'tuesday', 'thursday', 'friday') not null,
    start_time time not null,
    end_time time not null,
    duration_hours decimal (3,1) not null default 2.0,
    is_online boolean not null default true,
    foreign key (hall_no) references lecture_hall(hall_no) on update cascade on delete restrict,
    foreign key (lecturer_id) references lecturer (lecturer_id) on update cascade on delete restrict,
    check (end_time > start_time)
) engine innodb;

create table combined_session_course (
    combined_session_id varchar(20) not null,
    course_code varchar(20) not null,
    primary key (combined_session_id, course_code),
    foreign key (combined_session_id) references combined_session(combined_session_id) on update cascade on delete cascade,
    foreign key (course_code) references course (course_code) on update cascade on delete cascade
) engine innodb;

-- timetable and timetable_entry
create table timetable (
    timetable_id varchar(20) primary key,
    semester_id varchar(20) not null,
    academic_year varchar(15) not null,
    revision_iteration int not null default 1 check (revision_iteration between 1 and 10),
    status enum('draft', 'in_revision', 'approved', 'published') not null default 'draft',
    published_date date null,
    foreign key (semester_id) references semester (semester_id) on update cascade on delete restrict
) engine innodb;

create table timetable_entry (
    entry_id varchar(20) primary key,
    timetable_id varchar(20) not null,
    course_code varchar(20) not null,
    hall_no varchar(20) not null,
    session_day enum('monday', 'tuesday', 'wednesday', 'thursday', 'friday') not null,
    start_time time not null,
    end_time time not null,
    is_online boolean not null default false,
    foreign key (timetable_id) references timetable(timetable_id) on update cascade on delete cascade,
    foreign key (course_code) references course (course_code) on update cascade on delete cascade,
    foreign key (hall_no) references lecture_hall (hall_no) on update cascade on delete restrict,
    check (end_time > start_time),
    check (session_day <> 'wednesday')
) engine innodb;

-- student and online attendance
create table student (
    student_reg_no varchar(25) primary key,
    full_name varchar(150) not null,
    degree_stream enum('it', 'cs') not null,
    year varchar (10) not null
) engine innodb;

create table online_attendance (
    attendance_id varchar(20) primary key,
    student_reg_no varchar(25) not null,
    course_code varchar(20) not null,
    session_date date not null,
    duration_minutes int not null check (duration_minutes >= 0),
    is_attended boolean generated always as (duration_minutes >= 40) stored,
    foreign key (student_reg_no) references student (student_reg_no) on update cascade on delete cascade,
    foreign key (course_code) references course(course_code) on update cascade on delete cascade
) engine innodb;

-- indexes
create unique index idx_hall_clash_prevention on timetable_entry (hall_no, session_day, start_time, end_time);
create index idx_practical_wednesday on practical_session (lab_no, session_day, start_time);

-- security
create role if not exists role_dean;
create role if not exists role_ar_officer;
create role if not exists role_hod;
create role if not exists role_clerk;

grant select on rjt_as_sm_db.* to role_dean;
grant select on rjt_as_sm_db.* to role_ar_officer;
grant insert, update on rjt_as_sm_db.timetable to role_ar_officer;
grant insert, update on rjt_as_sm_db.timetable_entry to role_ar_officer;

grant select, insert, update, delete on rjt_as_sm_db.* to role_hod;
grant select, insert, update, delete on rjt_as_sm_db.student to role_clerk;
grant select, insert, update, delete on rjt_as_sm_db.lecturer to role_clerk;
grant select, insert, update, delete on rjt_as_sm_db.course to role_clerk;

create user if not exists 'dean_fas'@'localhost' identified by 'Dean@RJT2026';
grant role_dean to 'dean_fas'@'localhost';

create user if not exists 'hod_comp'@'localhost' identified by 'HodComp!2026';
grant role_hod to 'hod_comp'@'localhost';

create user if not exists 'ar_office'@'localhost' identified by 'Aroffice#987';
grant role_ar_officer to 'ar_office'@'localhost';

create user if not exists 'clerk_comp'@'localhost' identified by 'ClerkComp$432';
grant role_clerk to 'clerk_comp'@'localhost';

flush privileges;