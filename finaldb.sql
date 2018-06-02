-- phpMyAdmin SQL Dump
-- version 4.0.10deb1
-- http://www.phpmyadmin.net
--
-- Host: 127.0.0.1
-- Generation Time: Dec 06, 2017 at 02:07 AM
-- Server version: 5.5.57-0ubuntu0.14.04.1
-- PHP Version: 5.5.9-1ubuntu4.22

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `sprint3demo1`
--

DELIMITER $$
--
-- Procedures
--
CREATE  PROCEDURE `addcourse`( IN courseName varchar( 255 ) ,IN  courseNumberCode int(50), IN credits
INT(10),IN courseDescription VARCHAR(500))
BEGIN 
if not exists(select * from Course where course_number=courseNumberCode)
then
Insert into Course(name,course_number,credits,description)
values(courseName,courseNumberCode,credits,courseDescription);
else
Select 'Another course with this coursenumber already exists , please choose a different course number'
as errormessage;
END if;
END$$

CREATE  PROCEDURE `addCoursetoDepartment`( IN courseId int( 25 ) ,IN  departmentCode varchar(50))
BEGIN 
if not exists(Select * from DepartmentCourse where course=courseId )
then
Insert into DepartmentCourse(course,department) values(courseId,departmentCode);
else
select 'course already exists in the department' as errorMessage;
END if;
END$$

CREATE  PROCEDURE `adddepartment`( IN  departmentCode varchar( 255 ) , IN departmentName VARCHAR( 255 ) ,
IN departmentDescription VARCHAR(500))
BEGIN 
if not exists(Select * from Department where abbreviated_name=departmentCode)
then
INSERT INTO Department (abbreviated_name,name,description) VALUES
(departmentCode,departmentName,departmentDescription);
Select 'Another department with this departmentcode already exists , please choose a different
departmentcode'as errormessage;
END if;
END$$

CREATE  PROCEDURE `addSectiontoCourse`( IN sectionNumber int( 25 ) , IN sectionLimit int( 25 ),IN year_value int( 25 ),IN teacher_id int( 25 ),IN courseId int( 25 ),IN semester_value varchar( 25 ),IN room_id int( 25 ),IN  lecture_type varchar(50))
BEGIN 

DECLARE results int;

If not exists(Select section_id from Section where section_num=sectionNumber) then

if not exists(Select teacher from Section where teacher=teacher_id and semester = semester_value and year= year_value)

then
call check_Sectionlimit(sectionLimit, room_id,@result);
if(@result=1)
then
Insert into Section(section_num,section_limit,year,teacher,course,semester,room,lecture_type) 
values(sectionNumber,sectionLimit,year,teacher_id,courseId,semester,room_id,lecture_type);
Else
Select 'Section Limit is more than Room Capacity, Please select different room' As Message;
END if;
Else
SELECT 'Teacher is already handling one Subject this Semester .Please Select another Teacher' AS Message;
END if;
ELSE
SELECT 'Section Already Exists' AS Message;
END IF; 
END$$

CREATE  PROCEDURE `check_Sectionlimit`(IN `seclimit` INT(10), IN `room` INT(10), OUT `limitresult` INT(10))
BEGIN
DECLARE capacity INT;
DECLARE result INT;
Set capacity=(Select capacity from Room where room_id=room);
if(seclimit<=capacity)
then
SET result=1;
else
SET result=0;

SET limitresult=result;
END if;

END$$

CREATE  PROCEDURE `sectionSchedule`(IN sectionId INT,IN daySlot varchar(10),timeSlot int(10))
BEGIN
if not exists(select * from SectionDayTime where DAY=daySlot and TIME =timeSlot)
then
Insert into SectionDayTime (section,DAY,TIME) values(sectionId,daySlot,timeSlot);
else
Select 'Another section is alloted for this day and time slot, please select a different day or
different time' as errorMessage;
END if;
END$$

CREATE  PROCEDURE `studentEnrollsIntoSection`(IN sectionId int(10)  , IN student_id int(10))
BEGIN
Declare dayresult varchar(50);
Declare timeresult int(10);
if not exists(select * from StudentSection where section=sectionId and student=student_id)
then
Set dayresult = (select day from SectionDayTime where section=sectionId);
Set timeresult = (select time from SectionDayTime where section=sectionId);
call timingscheck(timeresult, student_id,@result);
if not exists(select * from StudentSection sc inner join SectionDayTime sd using(section) where sd.day=dayresult  and 
sc.student=student_id) and @result =1
then
if not exists(Select p.prerequisite from Section s inner join Course c on s.course = c.course_id 
inner join Prerequisite p on c.course_id=p.course where s.section_id= sectionId)
then
insert into StudentSection (student,section) values(student_id,sectionId);
else
Select 'The course you are trying to enroll has Prerequisite courses , Please look in the course details to know about its prerequisites' as errorMessage;
END if;
else
Select 'The section you are trying to enroll is conflicting with the other sections you already enrolled';
END if;
else
Select 'You have already enrolled for this section,PLease choose a different section' as errorMessage;
END if;
END$$

CREATE  PROCEDURE `studentRegistration`( IN firstName varchar( 25 ) ,IN  lastName varchar(50),OUT studentRegistration_id int(10))
BEGIN 
Insert into Student(first_name,last_name) values(firstName,lastName);
Select student_id into studentRegistration_id from Student where first_name=firstName and last_name=lastName ;
END$$

CREATE  PROCEDURE `teacherRegistration`( IN firstName VARCHAR( 25 ) , IN lastName VARCHAR( 50 ) , OUT teacherRegistration_id INT( 10 ) )
BEGIN INSERT INTO Teacher( first_name, last_name ) 
VALUES (
firstName, lastName);

SELECT teacher_id
INTO teacherRegistration_id
FROM Teacher
WHERE first_name = firstName
AND last_name = lastName;
END$$

CREATE  PROCEDURE `teacherSection`(IN teacherId int(10)  , IN sectionId int(10))
BEGIN
Declare dayresult varchar(50);
Declare timeresult int(10);
if not exists(select * from TeacherSection where section=sectionId and teacher=teacherId)
then
Set dayresult = (select day from SectionDayTime where section=sectionId);
Set timeresult = (select time from SectionDayTime where section=sectionId);
call teachertimingscheck(timeresult, teacherId,@result);
if not exists(select * from TeacherSection sc inner join SectionDayTime sd using(section) where sd.day=dayresult and
@result=1 and sc.teacher=teacherId)
then
insert into TeacherSection (teacher,section) values(teacherId,sectionId);
else
Select 'The section you are trying to enroll is conflicting with the other sections which you are already handling';
END if;
else
Select 'You are already handling this section,PLease choose a different section to handle' as errorMessage;
END if;
END$$

CREATE  PROCEDURE `teachertimingscheck`(time_id int(10),teacher_id int(25),out result int(10))
begin
declare start_time time ;
declare end_time time;
set start_time = (select start_time from Lecture_Time where lecture_time_id =time_id);
set end_time = (select end_time from Lecture_Time where lecture_time_id =time_id);
if not exists(select * from TeacherSection sc inner join SectionDayTime sd using (section) inner join Lecture_Time lt on sd.TIME = lt.lecture_time_id
where sc.teacher=teacher_id and start_time between lt.start_time and lt.end_time or start_time = lt.start_time or end_time between lt.start_time and
lt.end_time)
then
set result =1;
else
set result=0;
end if;
END$$

CREATE  PROCEDURE `timingscheck`(time_id int(10),student_id int(25),out result int(10))
begin
declare start_time time ;
declare end_time time;
set start_time = (select start_time from Lecture_Time where lecture_time_id =time_id);
set end_time = (select end_time from Lecture_Time where lecture_time_id =time_id);
if not exists(select * from StudentSection sc inner join SectionDayTime sd using (section) inner join Lecture_Time lt on sd.TIME = lt.lecture_time_id
where sc.student=student_id and start_time between lt.start_time and lt.end_time or start_time = lt.start_time or end_time between lt.start_time and
lt.end_time)
then
set result =1;
else
set result=0;
end if;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `Admin`
--

CREATE TABLE IF NOT EXISTS `Admin` (
  `username` varchar(50) NOT NULL,
  `password` varchar(50) NOT NULL,
  `first_name` varchar(50) NOT NULL,
  `last_name` varchar(50) NOT NULL,
  PRIMARY KEY (`username`),
  UNIQUE KEY `username` (`username`),
  KEY `fullName` (`last_name`,`first_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Admin`
--

INSERT INTO `Admin` (`username`, `password`, `first_name`, `last_name`) VALUES
('kjohn', '123456789', 'kevin', 'john');

-- --------------------------------------------------------

--
-- Table structure for table `Building`
--

CREATE TABLE IF NOT EXISTS `Building` (
  `name` varchar(50) NOT NULL,
  PRIMARY KEY (`name`),
  UNIQUE KEY `name` (`name`),
  KEY `buildingName` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Building`
--

INSERT INTO `Building` (`name`) VALUES
('Atkins'),
('Bio Informatics'),
('Friday'),
('Online'),
('WoodWard Hall');

-- --------------------------------------------------------

--
-- Table structure for table `Course`
--

CREATE TABLE IF NOT EXISTS `Course` (
  `course_id` int(10) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `course_number` int(10) NOT NULL,
  `credits` int(10) NOT NULL,
  `description` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`course_id`),
  KEY `name` (`name`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=9 ;

--
-- Dumping data for table `Course`
--

INSERT INTO `Course` (`course_id`, `name`, `course_number`, `credits`, `description`) VALUES
(1, 'Database Systems', 6160, 3, 'This course covers the fundamental concepts of database systems. Topics include data models (ER, relational, and others); query languages (relational algebra, SQL, and others)'),
(2, 'Mobile Application Development', 5180, 3, 'This course covers the topics of Android application development and few topics from ios Application development'),
(3, 'Knowledge Discovery in Databases', 6162, 3, 'This Course covers the algorithms to find the association rules and reducts from the given sets of data'),
(4, 'Calculus', 1120, 3, 'This course is designed to develop the topics of differential and integral calculus. Emphasis is placed on limits, continuity, derivatives and integrals of algebraic and transcendental functions of one variable.'),
(5, 'Ord Differential Equations', 5173, 3, 'The course will demonstrate the usefulness of ordinary differential equations for modeling physical and other phenomena. Complementary mathematical approaches for their solution will be presented, including analytical methods, graphical analysis and numerical techniques'),
(6, 'Calculus-Engr Tech', 1121, 3, 'This course covers topics in calculus with an emphasis on applications in engineering technology.'),
(7, 'Ecology', 3144, 3, 'Ecology is the study of the interactions between organisms and their environment. This course provides a background in the fundamental principles of ecological science, including concepts of natural selection, population and community ecology, biodiversity, and sustainability.'),
(8, 'Financial Management', 3120, 3, 'Principles and problems of financial aspects of managing capital structure, leastcost asset management, planning and control.');

-- --------------------------------------------------------

--
-- Stand-in structure for view `CourseInDepartment`
--
CREATE TABLE IF NOT EXISTS `CourseInDepartment` (
`Department` varchar(50)
,`Course Number` int(10)
,`Course` varchar(50)
);
-- --------------------------------------------------------

--
-- Table structure for table `Department`
--

CREATE TABLE IF NOT EXISTS `Department` (
  `abbreviated_name` varchar(50) NOT NULL,
  `name` varchar(50) NOT NULL,
  `description` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`abbreviated_name`),
  UNIQUE KEY `abbreviated_name` (`abbreviated_name`),
  KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Department`
--

INSERT INTO `Department` (`abbreviated_name`, `name`, `description`) VALUES
('BIOL', 'Biology', 'The biology department provides students with courses that support a broad base for understanding principles governing life processes at all levels–molecular, cellular, organismal, and ecological.'),
('FINN', 'Finance', 'The finance department covers topics dealing with accounting, money management, and banking.'),
('ITCS', 'Computer Science', 'This department has courses that teach you how to program and manage networking operations'),
('MATH', 'Mathematics', 'The department offers seven concentrations as part of the mathematics degree: Actuarial, Applied Math, Individual, Math Computing, Pure Math, Statistics, and Teaching.');

-- --------------------------------------------------------

--
-- Table structure for table `DepartmentCourse`
--

CREATE TABLE IF NOT EXISTS `DepartmentCourse` (
  `course` int(10) NOT NULL,
  `department` varchar(50) NOT NULL,
  PRIMARY KEY (`course`,`department`),
  KEY `department` (`department`),
  KEY `dep` (`department`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `DepartmentCourse`
--

INSERT INTO `DepartmentCourse` (`course`, `department`) VALUES
(7, 'BIOL'),
(8, 'FINN'),
(1, 'ITCS'),
(2, 'ITCS'),
(3, 'ITCS'),
(4, 'MATH'),
(5, 'MATH'),
(6, 'MATH');

-- --------------------------------------------------------

--
-- Table structure for table `Lecture_Day`
--

CREATE TABLE IF NOT EXISTS `Lecture_Day` (
  `day` varchar(50) NOT NULL,
  PRIMARY KEY (`day`),
  UNIQUE KEY `day` (`day`),
  KEY `lectureDay` (`day`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Lecture_Day`
--

INSERT INTO `Lecture_Day` (`day`) VALUES
('Friday'),
('Monday'),
('Thursday'),
('Tuesday'),
('Wednesday');

-- --------------------------------------------------------

--
-- Table structure for table `Lecture_Time`
--

CREATE TABLE IF NOT EXISTS `Lecture_Time` (
  `lecture_time_id` int(10) NOT NULL AUTO_INCREMENT,
  `start_time` time DEFAULT NULL,
  `end_time` time DEFAULT NULL,
  PRIMARY KEY (`lecture_time_id`),
  KEY `timeBlock` (`start_time`,`end_time`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=5 ;

--
-- Dumping data for table `Lecture_Time`
--

INSERT INTO `Lecture_Time` (`lecture_time_id`, `start_time`, `end_time`) VALUES
(1, '08:30:00', '11:15:00'),
(2, '09:30:00', '12:15:00'),
(4, '14:00:00', '16:45:00'),
(3, '15:00:00', '17:15:00');

-- --------------------------------------------------------

--
-- Table structure for table `Lecture_Type`
--

CREATE TABLE IF NOT EXISTS `Lecture_Type` (
  `type` varchar(50) NOT NULL,
  PRIMARY KEY (`type`),
  UNIQUE KEY `type` (`type`),
  KEY `lectureType` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Lecture_Type`
--

INSERT INTO `Lecture_Type` (`type`) VALUES
('Lab'),
('Lecture'),
('Online');

-- --------------------------------------------------------

--
-- Table structure for table `Prerequisite`
--

CREATE TABLE IF NOT EXISTS `Prerequisite` (
  `course` int(10) NOT NULL,
  `prerequisite` int(10) NOT NULL,
  PRIMARY KEY (`course`,`prerequisite`),
  KEY `prerequisite` (`prerequisite`),
  KEY `course` (`course`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Prerequisite`
--

INSERT INTO `Prerequisite` (`course`, `prerequisite`) VALUES
(3, 1),
(6, 4),
(6, 5);

-- --------------------------------------------------------

--
-- Stand-in structure for view `Prerequisites`
--
CREATE TABLE IF NOT EXISTS `Prerequisites` (
`Course` varchar(50)
,`Prerequisite` text
);
-- --------------------------------------------------------

--
-- Table structure for table `Room`
--

CREATE TABLE IF NOT EXISTS `Room` (
  `room_id` int(10) NOT NULL AUTO_INCREMENT,
  `number` int(10) DEFAULT NULL,
  `capacity` int(10) DEFAULT NULL,
  `building` varchar(50) NOT NULL,
  PRIMARY KEY (`room_id`),
  KEY `building` (`building`),
  KEY `number` (`number`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=6 ;

--
-- Dumping data for table `Room`
--

INSERT INTO `Room` (`room_id`, `number`, `capacity`, `building`) VALUES
(1, 155, 60, 'WoodWard Hall'),
(2, 124, 30, 'Atkins'),
(3, 130, 45, 'Bio Informatics'),
(4, NULL, NULL, 'Online'),
(5, 142, 80, 'Friday');

-- --------------------------------------------------------

--
-- Table structure for table `Section`
--

CREATE TABLE IF NOT EXISTS `Section` (
  `section_id` int(10) NOT NULL AUTO_INCREMENT,
  `section_num` int(10) NOT NULL,
  `section_limit` int(10) NOT NULL,
  `year` year(4) NOT NULL,
  `course` int(10) NOT NULL,
  `semester` varchar(50) NOT NULL,
  `room` int(10) NOT NULL,
  `lecture_type` varchar(50) NOT NULL,
  `student_count` int(5) DEFAULT NULL,
  PRIMARY KEY (`section_id`),
  KEY `course` (`course`),
  KEY `semester` (`semester`),
  KEY `room` (`room`),
  KEY `lecture_type` (`lecture_type`),
  KEY `courseSection` (`course`,`section_num`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=6 ;

--
-- Dumping data for table `Section`
--

INSERT INTO `Section` (`section_id`, `section_num`, `section_limit`, `year`, `course`, `semester`, `room`, `lecture_type`, `student_count`) VALUES
(1, 3541, 30, 2017, 4, 'Fall', 4, 'Online', 2),
(2, 4581, 45, 2018, 1, 'Fall', 3, 'Lecture', 2),
(3, 5861, 30, 2018, 2, 'Spring', 2, 'Lecture', 3),
(4, 1114, 60, 2017, 7, 'Fall', 1, 'Lab', 3),
(5, 8541, 40, 2018, 3, 'First Summer', 4, 'Online', 1);

-- --------------------------------------------------------

--
-- Table structure for table `SectionDayTime`
--

CREATE TABLE IF NOT EXISTS `SectionDayTime` (
  `section` int(10) NOT NULL,
  `TIME` int(10) NOT NULL,
  `DAY` varchar(50) NOT NULL,
  PRIMARY KEY (`section`,`TIME`,`DAY`),
  KEY `TIME` (`TIME`),
  KEY `DAY` (`DAY`),
  KEY `section` (`section`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `SectionDayTime`
--

INSERT INTO `SectionDayTime` (`section`, `TIME`, `DAY`) VALUES
(4, 1, 'Friday'),
(5, 1, 'Wednesday'),
(2, 2, 'Friday'),
(1, 3, 'Monday'),
(3, 4, 'Monday');

-- --------------------------------------------------------

--
-- Table structure for table `Semester`
--

CREATE TABLE IF NOT EXISTS `Semester` (
  `season` varchar(50) NOT NULL,
  PRIMARY KEY (`season`),
  UNIQUE KEY `season` (`season`),
  KEY `seas` (`season`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Semester`
--

INSERT INTO `Semester` (`season`) VALUES
('Fall'),
('First Summer'),
('Second Summer'),
('Spring');

-- --------------------------------------------------------

--
-- Table structure for table `Student`
--

CREATE TABLE IF NOT EXISTS `Student` (
  `student_id` int(10) NOT NULL AUTO_INCREMENT,
  `first_name` varchar(50) NOT NULL,
  `last_name` varchar(50) NOT NULL,
  PRIMARY KEY (`student_id`),
  KEY `fullName` (`last_name`,`first_name`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=7 ;

--
-- Dumping data for table `Student`
--

INSERT INTO `Student` (`student_id`, `first_name`, `last_name`) VALUES
(4, 'Mahesh', 'Babu'),
(5, 'Smith', 'John'),
(6, 'Kooper', 'Kevin'),
(1, 'Sai', 'Krishna'),
(2, 'Karthik', 'Kumar'),
(3, 'Surya', 'Shiva');

-- --------------------------------------------------------

--
-- Stand-in structure for view `StudentSchedule`
--
CREATE TABLE IF NOT EXISTS `StudentSchedule` (
`First Name` varchar(50)
,`Last Name` varchar(50)
,`Day` varchar(50)
,`Time Block` varchar(19)
);
-- --------------------------------------------------------

--
-- Table structure for table `StudentSection`
--

CREATE TABLE IF NOT EXISTS `StudentSection` (
  `student` int(10) NOT NULL,
  `section` int(10) NOT NULL,
  PRIMARY KEY (`student`,`section`),
  KEY `section` (`section`),
  KEY `student` (`student`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `StudentSection`
--

INSERT INTO `StudentSection` (`student`, `section`) VALUES
(1, 1),
(5, 1),
(1, 2),
(5, 2),
(2, 3),
(3, 3),
(3, 4),
(4, 4),
(6, 4),
(4, 5);

--
-- Triggers `StudentSection`
--
DROP TRIGGER IF EXISTS `after_student_enroll`;
DELIMITER //
CREATE TRIGGER `after_student_enroll` AFTER INSERT ON `StudentSection`
 FOR EACH ROW BEGIN 
UPDATE Section SET student_count = student_count +1 WHERE section_id = new.section;
END
//
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `Teacher`
--

CREATE TABLE IF NOT EXISTS `Teacher` (
  `teacher_id` int(10) NOT NULL AUTO_INCREMENT,
  `first_name` varchar(50) NOT NULL,
  `last_name` varchar(50) NOT NULL,
  PRIMARY KEY (`teacher_id`),
  KEY `full_name` (`last_name`,`first_name`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=5 ;

--
-- Dumping data for table `Teacher`
--

INSERT INTO `Teacher` (`teacher_id`, `first_name`, `last_name`) VALUES
(2, 'Srinivas', 'Akella'),
(4, 'Licheng', 'Jin'),
(3, 'Shakib', 'Miazi'),
(1, 'Harini', 'Ramaprasad');

-- --------------------------------------------------------

--
-- Stand-in structure for view `TeacherSchedule`
--
CREATE TABLE IF NOT EXISTS `TeacherSchedule` (
`Full Name` varchar(101)
,`Day` varchar(50)
,`Time Block` varchar(19)
);
-- --------------------------------------------------------

--
-- Table structure for table `TeacherSection`
--

CREATE TABLE IF NOT EXISTS `TeacherSection` (
  `teacher` int(10) NOT NULL,
  `section` int(10) NOT NULL,
  PRIMARY KEY (`teacher`,`section`),
  KEY `section` (`section`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `TeacherSection`
--

INSERT INTO `TeacherSection` (`teacher`, `section`) VALUES
(2, 1),
(1, 2),
(2, 2),
(3, 3),
(3, 4),
(1, 5);

-- --------------------------------------------------------

--
-- Table structure for table `Transcript`
--

CREATE TABLE IF NOT EXISTS `Transcript` (
  `transcript_id` int(10) NOT NULL AUTO_INCREMENT,
  `student` int(10) DEFAULT NULL,
  PRIMARY KEY (`transcript_id`),
  KEY `student` (`student`),
  KEY `studentTranscript` (`student`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=7 ;

--
-- Dumping data for table `Transcript`
--

INSERT INTO `Transcript` (`transcript_id`, `student`) VALUES
(6, 1),
(3, 2),
(1, 3),
(2, 4),
(4, 5),
(5, 6);

-- --------------------------------------------------------

--
-- Table structure for table `TranscriptCourse`
--

CREATE TABLE IF NOT EXISTS `TranscriptCourse` (
  `transcript` int(10) NOT NULL,
  `course` int(10) NOT NULL,
  PRIMARY KEY (`transcript`,`course`),
  KEY `course` (`course`),
  KEY `courseTrans` (`course`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `TranscriptCourse`
--

INSERT INTO `TranscriptCourse` (`transcript`, `course`) VALUES
(5, 1),
(1, 2),
(3, 3),
(1, 4),
(5, 7);

-- --------------------------------------------------------

--
-- Structure for view `CourseInDepartment`
--
DROP TABLE IF EXISTS `CourseInDepartment`;

CREATE ALGORITHM=UNDEFINED   VIEW `CourseInDepartment` AS select `d`.`name` AS `Department`,`c`.`course_number` AS `Course Number`,`c`.`name` AS `Course` from ((`Course` `c` join `DepartmentCourse` `dc` on((`c`.`course_id` = `dc`.`course`))) join `Department` `d` on((`dc`.`department` = `d`.`abbreviated_name`)));

-- --------------------------------------------------------

--
-- Structure for view `Prerequisites`
--
DROP TABLE IF EXISTS `Prerequisites`;

CREATE ALGORITHM=UNDEFINED   VIEW `Prerequisites` AS select `c`.`name` AS `Course`,group_concat(`c2`.`name` separator ',') AS `Prerequisite` from ((`Prerequisite` `p` join `Course` `c` on((`p`.`course` = `c`.`course_id`))) join `Course` `c2` on((`p`.`prerequisite` = `c2`.`course_id`))) group by `c`.`name`;

-- --------------------------------------------------------

--
-- Structure for view `StudentSchedule`
--
DROP TABLE IF EXISTS `StudentSchedule`;

CREATE ALGORITHM=UNDEFINED   VIEW `StudentSchedule` AS select `s`.`first_name` AS `First Name`,`s`.`last_name` AS `Last Name`,`sdt`.`DAY` AS `Day`,concat(`lt`.`start_time`,' - ',`lt`.`end_time`) AS `Time Block` from ((((`Student` `s` left join `StudentSection` `ss` on((`s`.`student_id` = `ss`.`student`))) left join `Section` `se` on((`ss`.`section` = `se`.`section_id`))) left join `SectionDayTime` `sdt` on((`se`.`section_id` = `sdt`.`section`))) left join `Lecture_Time` `lt` on((`sdt`.`TIME` = `lt`.`lecture_time_id`)));

-- --------------------------------------------------------

--
-- Structure for view `TeacherSchedule`
--
DROP TABLE IF EXISTS `TeacherSchedule`;

CREATE ALGORITHM=UNDEFINED   VIEW `TeacherSchedule` AS select concat(`t`.`first_name`,' ',`t`.`last_name`) AS `Full Name`,`sdt`.`DAY` AS `Day`,concat(`lt`.`start_time`,' - ',`lt`.`end_time`) AS `Time Block` from ((((`Teacher` `t` left join `TeacherSection` `ts` on((`t`.`teacher_id` = `ts`.`teacher`))) left join `Section` `se` on((`ts`.`section` = `se`.`section_id`))) left join `SectionDayTime` `sdt` on((`se`.`section_id` = `sdt`.`section`))) left join `Lecture_Time` `lt` on((`sdt`.`TIME` = `lt`.`lecture_time_id`)));

--
-- Constraints for dumped tables
--

--
-- Constraints for table `DepartmentCourse`
--
ALTER TABLE `DepartmentCourse`
  ADD CONSTRAINT `DepartmentCourse_ibfk_1` FOREIGN KEY (`course`) REFERENCES `Course` (`course_id`),
  ADD CONSTRAINT `DepartmentCourse_ibfk_2` FOREIGN KEY (`department`) REFERENCES `Department` (`abbreviated_name`);

--
-- Constraints for table `Prerequisite`
--
ALTER TABLE `Prerequisite`
  ADD CONSTRAINT `Prerequisite_ibfk_1` FOREIGN KEY (`course`) REFERENCES `Course` (`course_id`),
  ADD CONSTRAINT `Prerequisite_ibfk_2` FOREIGN KEY (`prerequisite`) REFERENCES `Course` (`course_id`);

--
-- Constraints for table `Room`
--
ALTER TABLE `Room`
  ADD CONSTRAINT `Room_ibfk_1` FOREIGN KEY (`building`) REFERENCES `Building` (`name`);

--
-- Constraints for table `Section`
--
ALTER TABLE `Section`
  ADD CONSTRAINT `Section_ibfk_2` FOREIGN KEY (`course`) REFERENCES `Course` (`course_id`),
  ADD CONSTRAINT `Section_ibfk_3` FOREIGN KEY (`semester`) REFERENCES `Semester` (`season`),
  ADD CONSTRAINT `Section_ibfk_4` FOREIGN KEY (`room`) REFERENCES `Room` (`room_id`),
  ADD CONSTRAINT `Section_ibfk_5` FOREIGN KEY (`lecture_type`) REFERENCES `Lecture_Type` (`type`);

--
-- Constraints for table `SectionDayTime`
--
ALTER TABLE `SectionDayTime`
  ADD CONSTRAINT `SectionDayTime_ibfk_1` FOREIGN KEY (`section`) REFERENCES `Section` (`section_id`),
  ADD CONSTRAINT `SectionDayTime_ibfk_2` FOREIGN KEY (`TIME`) REFERENCES `Lecture_Time` (`lecture_time_id`),
  ADD CONSTRAINT `SectionDayTime_ibfk_3` FOREIGN KEY (`DAY`) REFERENCES `Lecture_Day` (`day`);

--
-- Constraints for table `StudentSection`
--
ALTER TABLE `StudentSection`
  ADD CONSTRAINT `StudentSection_ibfk_1` FOREIGN KEY (`student`) REFERENCES `Student` (`student_id`),
  ADD CONSTRAINT `StudentSection_ibfk_2` FOREIGN KEY (`section`) REFERENCES `Section` (`section_id`);

--
-- Constraints for table `TeacherSection`
--
ALTER TABLE `TeacherSection`
  ADD CONSTRAINT `TeacherSection_ibfk_1` FOREIGN KEY (`teacher`) REFERENCES `Teacher` (`teacher_id`),
  ADD CONSTRAINT `TeacherSection_ibfk_2` FOREIGN KEY (`section`) REFERENCES `Section` (`section_id`);

--
-- Constraints for table `Transcript`
--
ALTER TABLE `Transcript`
  ADD CONSTRAINT `Transcript_ibfk_1` FOREIGN KEY (`student`) REFERENCES `Student` (`student_id`);

--
-- Constraints for table `TranscriptCourse`
--
ALTER TABLE `TranscriptCourse`
  ADD CONSTRAINT `TranscriptCourse_ibfk_1` FOREIGN KEY (`transcript`) REFERENCES `Transcript` (`transcript_id`),
  ADD CONSTRAINT `TranscriptCourse_ibfk_2` FOREIGN KEY (`course`) REFERENCES `Course` (`course_id`);

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
