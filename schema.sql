-- MariaDB dump 10.19  Distrib 10.4.32-MariaDB, for Win64 (AMD64)
--
-- Host: localhost    Database: eventsphere
-- ------------------------------------------------------
-- Server version	10.4.32-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `eventsphere`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `eventsphere` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci */;

USE `eventsphere`;

--
-- Table structure for table `custom_event_bookings`
--

DROP TABLE IF EXISTS `custom_event_bookings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `custom_event_bookings` (
  `booking_id` int(11) NOT NULL AUTO_INCREMENT,
  `request_id` int(11) NOT NULL,
  `proposal_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `organizer_id` int(11) NOT NULL,
  `total_amount` decimal(10,2) NOT NULL,
  `advance_amount` decimal(10,2) DEFAULT 0.00,
  `remaining_amount` decimal(10,2) DEFAULT 0.00,
  `booking_status` enum('Confirmed','In Progress','Completed','Cancelled') DEFAULT 'Confirmed',
  `booking_date` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`booking_id`),
  KEY `request_id` (`request_id`),
  KEY `proposal_id` (`proposal_id`),
  KEY `user_id` (`user_id`),
  KEY `organizer_id` (`organizer_id`),
  CONSTRAINT `custom_event_bookings_ibfk_1` FOREIGN KEY (`request_id`) REFERENCES `event_requests` (`request_id`),
  CONSTRAINT `custom_event_bookings_ibfk_2` FOREIGN KEY (`proposal_id`) REFERENCES `proposals` (`proposal_id`),
  CONSTRAINT `custom_event_bookings_ibfk_3` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `custom_event_bookings_ibfk_4` FOREIGN KEY (`organizer_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `custom_event_bookings`
--

LOCK TABLES `custom_event_bookings` WRITE;
/*!40000 ALTER TABLE `custom_event_bookings` DISABLE KEYS */;
/*!40000 ALTER TABLE `custom_event_bookings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `event_requests`
--

DROP TABLE IF EXISTS `event_requests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `event_requests` (
  `request_id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `event_type_id` int(11) NOT NULL,
  `event_title` varchar(200) NOT NULL,
  `event_date` date NOT NULL,
  `event_time` time DEFAULT NULL,
  `location` varchar(255) NOT NULL,
  `guest_count` int(11) NOT NULL,
  `budget` decimal(10,2) DEFAULT NULL,
  `requirements` text DEFAULT NULL,
  `additional_notes` text DEFAULT NULL,
  `status` enum('Pending','Under Review','Proposal Received','Accepted','Rejected','Completed','Cancelled') DEFAULT 'Pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`request_id`),
  KEY `user_id` (`user_id`),
  KEY `event_type_id` (`event_type_id`),
  CONSTRAINT `event_requests_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `event_requests_ibfk_2` FOREIGN KEY (`event_type_id`) REFERENCES `event_types` (`event_type_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `event_requests`
--

LOCK TABLES `event_requests` WRITE;
/*!40000 ALTER TABLE `event_requests` DISABLE KEYS */;
INSERT INTO `event_requests` VALUES (1,1,1,'friend birthday','2026-08-15','22:00:00','rjy',8,20000.00,'ballons,cooling chocolate cake,decoration items,chairs,tables,plates','food','Proposal Received','2026-08-12 04:53:01');
/*!40000 ALTER TABLE `event_requests` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `event_reviews`
--

DROP TABLE IF EXISTS `event_reviews`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `event_reviews` (
  `review_id` int(11) NOT NULL AUTO_INCREMENT,
  `event_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `registration_id` int(11) DEFAULT NULL,
  `rating` int(11) NOT NULL CHECK (`rating` >= 1 and `rating` <= 5),
  `review_title` varchar(150) DEFAULT NULL,
  `review_text` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`review_id`),
  UNIQUE KEY `uniq_user_event_review` (`user_id`,`event_id`),
  KEY `event_id` (`event_id`),
  CONSTRAINT `event_reviews_ibfk_1` FOREIGN KEY (`event_id`) REFERENCES `events` (`event_id`) ON DELETE CASCADE,
  CONSTRAINT `event_reviews_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `event_reviews`
--

LOCK TABLES `event_reviews` WRITE;
/*!40000 ALTER TABLE `event_reviews` DISABLE KEYS */;
/*!40000 ALTER TABLE `event_reviews` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `event_types`
--

DROP TABLE IF EXISTS `event_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `event_types` (
  `event_type_id` int(11) NOT NULL AUTO_INCREMENT,
  `event_type_name` varchar(100) NOT NULL,
  `description` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`event_type_id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `event_types`
--

LOCK TABLES `event_types` WRITE;
/*!40000 ALTER TABLE `event_types` DISABLE KEYS */;
INSERT INTO `event_types` VALUES (1,'Birthday Party','Birthday parties and private celebrations','2026-08-12 04:41:47'),(2,'Wedding','Wedding, engagement and reception events','2026-08-12 04:41:47'),(3,'College Event','College fests, seminars and student events','2026-08-12 04:41:47'),(4,'Cultural Event','Dance, singing, cultural and traditional programs','2026-08-12 04:41:47'),(5,'Sports Event','Sports competitions and tournaments','2026-08-12 04:41:47'),(6,'Technical Event','Hackathons, workshops and technical programs','2026-08-12 04:41:47'),(7,'Corporate Event','Meetings, conferences and corporate programs','2026-08-12 04:41:47'),(8,'Music & Entertainment','DJ, music shows and entertainment programs','2026-08-12 04:41:47'),(9,'Other','Other customized events','2026-08-12 04:41:47');
/*!40000 ALTER TABLE `event_types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `events`
--

DROP TABLE IF EXISTS `events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `events` (
  `event_id` int(11) NOT NULL AUTO_INCREMENT,
  `event_name` varchar(100) NOT NULL,
  `subtitle` varchar(255) DEFAULT NULL,
  `category` varchar(100) DEFAULT NULL,
  `registration_start` date DEFAULT NULL,
  `registration_deadline` date DEFAULT NULL,
  `event_date` date NOT NULL,
  `event_time` time NOT NULL,
  `venue` varchar(100) DEFAULT NULL,
  `mode` enum('Online','Offline') DEFAULT NULL,
  `team_size` varchar(50) DEFAULT NULL,
  `eligibility` text DEFAULT NULL,
  `rules` text DEFAULT NULL,
  `first_prize` varchar(100) DEFAULT NULL,
  `second_prize` varchar(100) DEFAULT NULL,
  `third_prize` varchar(100) DEFAULT NULL,
  `certificate` enum('Yes','No') DEFAULT NULL,
  `coordinator_name` varchar(100) DEFAULT NULL,
  `coordinator_phone` varchar(20) DEFAULT NULL,
  `coordinator_email` varchar(100) DEFAULT NULL,
  `banner_image` varchar(255) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `organizer_id` int(11) DEFAULT NULL,
  `event_fee` decimal(10,2) DEFAULT 0.00,
  `payment_type` enum('Free','Paid') DEFAULT 'Free',
  `upi_id` varchar(100) DEFAULT NULL,
  `qr_image` varchar(255) DEFAULT NULL,
  `max_capacity` int(11) DEFAULT 100,
  `available_seats` int(11) DEFAULT 100,
  PRIMARY KEY (`event_id`),
  KEY `organizer_id` (`organizer_id`),
  CONSTRAINT `events_ibfk_1` FOREIGN KEY (`organizer_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `events`
--

LOCK TABLES `events` WRITE;
/*!40000 ALTER TABLE `events` DISABLE KEYS */;
INSERT INTO `events` VALUES (4,'T-fest','houise','Gaming','2026-10-01','2026-10-24','2026-10-25','09:00:00','sasi,tadepalligudem','Offline','single','b.tech','no cheating','1500 cash prize with certificate','1000 cash prize with certificate','500 cash prize with certificate','Yes','jhon','9123456732','sarvagna.karibandi24@sasi.ac.in','','have fun','2026-08-09 04:57:28',5,0.00,'Paid','','',100,99),(8,'hackthon','24hr Hackathon','Hackathon','2026-08-09','2026-08-11','2026-08-13','09:00:00','sasi,tadepalligudem','Online','1-4 mebers','b.tech','no cheating','1500 cash prize with certificate','1000 cash prize with certificate','500 cash prize with certificate','Yes','jhon','9123456732','sarvagna.karibandi24@sasi.ac.in','banner_398c6992-cdf2-4b8c-a896-be44a5ba1557.jpg','have fun','2026-08-09 09:15:09',3,300.00,'Paid','sarvagna.karibandi24@sasi.ac.in','qr_a8ff63da-d089-43f9-b898-3e96c1dda81b.png',100,100),(10,'LUDO','KING','Gaming','2026-10-01','2026-10-27','2026-10-28','10:30:00','vinukonda','Online','1-4 mebers','Open to all college students.\r\nValid college ID is required.\r\nPrior registration is required.','Each game will have 4 players.\r\nFollow standard Ludo rules.\r\nNo cheating or unfair play.\r\nBe on time for your match.\r\nCoordinator\'s decision is final.','1000','500','250','Yes','siya','6300324367','abcd@gmail.com','banner_60900dc0-22d9-477b-ab56-2bedd25f2501.jpg','Ludo Gaming is a fun and competitive game where players compete using strategy and luck. Winners will advance to the next round, and the final winner will be declared as the champion.','2026-08-10 08:03:32',3,0.00,'Free',NULL,NULL,100,100),(11,'CHASE THE PUZZLE','puzzle','Technical','2026-10-05','2026-11-10','2026-11-12','11:00:00','NEC ,Narasaraopet','Online','1','Open to all college students.\r\nValid college ID is required.\r\nPrior registration is required.','Participants must solve the given puzzles within the time limit.\r\nNo mobile phones or external help.\r\nNo cheating or unfair practices.\r\nFollow the instructions given by the coordinator.\r\nCoordinator\'s decision is final.','500','250','100','Yes','siya','6300324367','abcd@gmail.com','banner_e7a5e7b8-4317-412f-aa38-b6e96122dd33.jpg','Puzzle Challenge is a fun and exciting event that tests participants\' logic, thinking, problem-solving, and observation skills. Participants must solve different puzzles within the given time. The participant with the best performance will be declared the winner.','2026-08-10 08:21:28',3,200.00,'Paid','siya@upi','qr_87394757-57bf-4e8a-84dd-3e2e0e9a7366.png',100,100),(12,'Voice Vibes','singing','Cultural','2026-10-05','2026-10-29','2026-10-30','09:00:00','sasi,tadepalligudem','Offline','single','Open to all college students.\r\nValid college ID is required.\r\nPrior registration is required.','Participants must sing a song within the given time limit.\r\nParticipants can choose their own song.\r\nNo inappropriate or offensive songs are allowed.\r\nFollow the instructions given by the coordinator.\r\nCoordinator\'s decision is final.','1500','1000','500','Yes','ram','9123456732','ram123@gmail.com','banner_e0f29083-2e7b-42c5-a6f7-85fcc96409d8.jpg','Singing Competition is a fun and exciting event that gives participants a chance to showcase their singing talent, confidence, and creativity. Participants will perform their chosen songs within the given time. The participant with the best performance will be declared the winner.','2026-08-10 08:28:04',3,0.00,'Free',NULL,NULL,100,100),(13,'Dance Carnival','dancing','Cultural','2026-10-08','2026-11-14','2026-11-15','20:00:00','NEC ,Narasaraopet','Online','group','Open to all college students.\r\nValid college ID is required.\r\nPrior registration is required.','Participants must perform within the given time limit.\r\nParticipants can choose their own dance style and music.\r\nNo inappropriate or offensive performances are allowed.\r\nFollow the instructions given by the coordinator.\r\nCoordinator\'s decision is final.','2000','1500','1000','Yes','chetana','8765438976','chetana58@gmail.com','banner_b7b789de-e27e-484e-b622-f4c5777a6772.jpg','Dance Competition is a fun and exciting event that gives participants a chance to showcase their dance skills, creativity, energy, and confidence. Participants will perform their chosen dance within the given time. The participant with the best performance will be declared the winner.','2026-08-10 08:37:24',4,250.00,'Paid','chetana58@upi','qr_a47e4878-b875-46a6-adbb-4748df87892d.png',100,100);
/*!40000 ALTER TABLE `events` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notifications`
--

DROP TABLE IF EXISTS `notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `notifications` (
  `notification_id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `title` varchar(150) NOT NULL,
  `message` text NOT NULL,
  `type` enum('booking','payment','proposal','verification','system') DEFAULT 'system',
  `reference_url` varchar(255) DEFAULT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`notification_id`),
  KEY `idx_user_read` (`user_id`,`is_read`),
  KEY `idx_user_created` (`user_id`,`created_at`),
  CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notifications`
--

LOCK TABLES `notifications` WRITE;
/*!40000 ALTER TABLE `notifications` DISABLE KEYS */;
INSERT INTO `notifications` VALUES (3,8,'🎟️ Registration Confirmed!','Your booking for \'Voice Vibes\' is confirmed. Access your ticket from My Registrations.','booking','myRegistrations.jsp',1,'2026-10-15 07:21:49'),(4,3,'🎟️ New Registration','karibandi sarvagna registered for your event \'Voice Vibes\'.','booking','viewParticipants.jsp?event_id=12',0,'2026-10-15 07:21:49'),(5,8,'🎟️ Booking Cancelled','Your registration for \'Voice Vibes\' was cancelled. The reserved seat has been released.','booking','browseEvents.jsp',0,'2026-10-15 07:22:31'),(6,3,'ℹ️ Registration Cancelled','A participant cancelled their registration for \'Voice Vibes\'. Seat capacity restored.','booking','viewParticipants.jsp?id=12',0,'2026-10-15 07:22:31'),(7,2,'🎟️ Checked In at Gate!','Your admission to \'LUDO\' was verified at the entrance gate. Enjoy the event!','booking','viewTicket.jsp?id=6',0,'2026-10-15 09:40:11'),(8,7,'🎟️ Registration Confirmed!','Your booking for \'T-fest\' is confirmed. Access your ticket from My Registrations.','booking','myRegistrations.jsp',0,'2026-10-15 09:57:31'),(9,5,'🎟️ New Registration','karibandi sarvagna registered for your event \'T-fest\'.','booking','viewParticipants.jsp?event_id=4',0,'2026-10-15 09:57:31');
/*!40000 ALTER TABLE `notifications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `organizer_events_conducted`
--

DROP TABLE IF EXISTS `organizer_events_conducted`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `organizer_events_conducted` (
  `conducted_event_id` int(11) NOT NULL AUTO_INCREMENT,
  `organizer_id` int(11) NOT NULL,
  `event_type_id` int(11) NOT NULL,
  `event_name` varchar(200) NOT NULL,
  `event_description` text DEFAULT NULL,
  `event_date` date DEFAULT NULL,
  `participant_count` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`conducted_event_id`),
  KEY `organizer_id` (`organizer_id`),
  KEY `event_type_id` (`event_type_id`),
  CONSTRAINT `organizer_events_conducted_ibfk_1` FOREIGN KEY (`organizer_id`) REFERENCES `users` (`id`),
  CONSTRAINT `organizer_events_conducted_ibfk_2` FOREIGN KEY (`event_type_id`) REFERENCES `event_types` (`event_type_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `organizer_events_conducted`
--

LOCK TABLES `organizer_events_conducted` WRITE;
/*!40000 ALTER TABLE `organizer_events_conducted` DISABLE KEYS */;
INSERT INTO `organizer_events_conducted` VALUES (1,5,6,'24 Hour Hackathon','A technical hackathon conducted for college students.','2026-07-15',150,'2026-08-12 10:22:33');
/*!40000 ALTER TABLE `organizer_events_conducted` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `organizer_profiles`
--

DROP TABLE IF EXISTS `organizer_profiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `organizer_profiles` (
  `profile_id` int(11) NOT NULL AUTO_INCREMENT,
  `organizer_id` int(11) NOT NULL,
  `organizer_description` text DEFAULT NULL,
  `experience_years` int(11) DEFAULT 0,
  `contact_phone` varchar(20) DEFAULT NULL,
  `services_description` text DEFAULT NULL,
  `qr_image` varchar(255) DEFAULT NULL,
  `payment_qr_enabled` enum('Yes','No') DEFAULT 'No',
  `cash_payment_enabled` enum('Yes','No') DEFAULT 'Yes',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `verification_status` enum('Not Submitted','Pending','Under Review','Verified','Rejected','Suspended') DEFAULT 'Not Submitted',
  `business_name` varchar(150) DEFAULT NULL,
  `business_address` varchar(255) DEFAULT NULL,
  `id_document` varchar(255) DEFAULT NULL,
  `rejection_reason` text DEFAULT NULL,
  `verified_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`profile_id`),
  UNIQUE KEY `organizer_id` (`organizer_id`),
  CONSTRAINT `organizer_profiles_ibfk_1` FOREIGN KEY (`organizer_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `organizer_profiles`
--

LOCK TABLES `organizer_profiles` WRITE;
/*!40000 ALTER TABLE `organizer_profiles` DISABLE KEYS */;
INSERT INTO `organizer_profiles` VALUES (1,3,'Specialized in campus hackathons, sports tournaments, and cultural fests.',5,'+91 98765 43210','Full Stage & AV Setup, Catering, Guest Logistics',NULL,'No','Yes','2026-10-11 04:30:24','2026-10-12 16:42:43','Verified','Sara Elite Event Management','College Road, Rajahmundry','doc_test_proof.jpg',NULL,'2026-10-12 16:42:43'),(2,4,NULL,0,NULL,NULL,NULL,'No','Yes','2026-10-11 04:30:24','2026-10-12 16:42:43','Not Submitted',NULL,NULL,NULL,NULL,NULL),(3,5,NULL,0,NULL,NULL,NULL,'No','Yes','2026-10-11 04:30:24','2026-10-11 04:30:24','Not Submitted',NULL,NULL,NULL,NULL,NULL),(4,8,'',0,'','',NULL,'No','Yes','2026-10-15 06:16:08','2026-10-15 06:18:22','Not Submitted','','',NULL,NULL,NULL);
/*!40000 ALTER TABLE `organizer_profiles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `organizer_services`
--

DROP TABLE IF EXISTS `organizer_services`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `organizer_services` (
  `service_id` int(11) NOT NULL AUTO_INCREMENT,
  `organizer_id` int(11) NOT NULL,
  `event_type_id` int(11) NOT NULL,
  `service_name` varchar(150) NOT NULL,
  `service_description` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`service_id`),
  KEY `organizer_id` (`organizer_id`),
  KEY `event_type_id` (`event_type_id`),
  CONSTRAINT `organizer_services_ibfk_1` FOREIGN KEY (`organizer_id`) REFERENCES `users` (`id`),
  CONSTRAINT `organizer_services_ibfk_2` FOREIGN KEY (`event_type_id`) REFERENCES `event_types` (`event_type_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `organizer_services`
--

LOCK TABLES `organizer_services` WRITE;
/*!40000 ALTER TABLE `organizer_services` DISABLE KEYS */;
/*!40000 ALTER TABLE `organizer_services` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `organizer_specializations`
--

DROP TABLE IF EXISTS `organizer_specializations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `organizer_specializations` (
  `specialization_id` int(11) NOT NULL AUTO_INCREMENT,
  `organizer_id` int(11) NOT NULL,
  `event_type_id` int(11) NOT NULL,
  `description` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `estimated_from` decimal(10,2) DEFAULT 0.00,
  `estimated_to` decimal(10,2) DEFAULT 0.00,
  PRIMARY KEY (`specialization_id`),
  UNIQUE KEY `organizer_id` (`organizer_id`,`event_type_id`),
  KEY `event_type_id` (`event_type_id`),
  CONSTRAINT `organizer_specializations_ibfk_1` FOREIGN KEY (`organizer_id`) REFERENCES `users` (`id`),
  CONSTRAINT `organizer_specializations_ibfk_2` FOREIGN KEY (`event_type_id`) REFERENCES `event_types` (`event_type_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `organizer_specializations`
--

LOCK TABLES `organizer_specializations` WRITE;
/*!40000 ALTER TABLE `organizer_specializations` DISABLE KEYS */;
/*!40000 ALTER TABLE `organizer_specializations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `payments`
--

DROP TABLE IF EXISTS `payments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `payments` (
  `payment_id` int(11) NOT NULL AUTO_INCREMENT,
  `registration_id` int(11) DEFAULT NULL,
  `amount` decimal(10,2) DEFAULT NULL,
  `payment_status` varchar(20) DEFAULT NULL,
  `payment_date` timestamp NOT NULL DEFAULT current_timestamp(),
  `payment_method` varchar(50) DEFAULT 'UPI',
  `transaction_id` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`payment_id`),
  KEY `registration_id` (`registration_id`),
  CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`registration_id`) REFERENCES `registrations` (`registration_id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `payments`
--

LOCK TABLES `payments` WRITE;
/*!40000 ALTER TABLE `payments` DISABLE KEYS */;
INSERT INTO `payments` VALUES (1,4,300.00,'Rejected','2026-10-12 15:04:02','UPI','UTR-HIST-004'),(2,6,0.00,'Completed','2026-10-12 15:04:02','Free','FREE-HIST-006'),(3,7,0.00,'Pending','2026-10-12 15:04:02','UPI','UTR-HIST-007'),(8,12,0.00,'Not Required','2026-10-15 09:57:31','Free','FREE-044E8E55');
/*!40000 ALTER TABLE `payments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `proposal_items`
--

DROP TABLE IF EXISTS `proposal_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `proposal_items` (
  `proposal_item_id` int(11) NOT NULL AUTO_INCREMENT,
  `proposal_id` int(11) NOT NULL,
  `item_name` varchar(150) NOT NULL,
  `description` varchar(500) DEFAULT NULL,
  `quantity` int(11) DEFAULT 1,
  `price` decimal(10,2) NOT NULL,
  PRIMARY KEY (`proposal_item_id`),
  KEY `proposal_id` (`proposal_id`),
  CONSTRAINT `proposal_items_ibfk_1` FOREIGN KEY (`proposal_id`) REFERENCES `proposals` (`proposal_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `proposal_items`
--

LOCK TABLES `proposal_items` WRITE;
/*!40000 ALTER TABLE `proposal_items` DISABLE KEYS */;
INSERT INTO `proposal_items` VALUES (4,3,'decoration items','ballons,food',1,15000.00);
/*!40000 ALTER TABLE `proposal_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `proposals`
--

DROP TABLE IF EXISTS `proposals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `proposals` (
  `proposal_id` int(11) NOT NULL AUTO_INCREMENT,
  `request_id` int(11) NOT NULL,
  `organizer_id` int(11) NOT NULL,
  `proposal_title` varchar(200) NOT NULL,
  `description` text DEFAULT NULL,
  `event_plan` text DEFAULT NULL,
  `total_amount` decimal(10,2) NOT NULL,
  `advance_amount` decimal(10,2) DEFAULT 0.00,
  `valid_until` date DEFAULT NULL,
  `status` enum('Pending','Accepted','Rejected','Expired') DEFAULT 'Pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`proposal_id`),
  KEY `request_id` (`request_id`),
  KEY `organizer_id` (`organizer_id`),
  CONSTRAINT `proposals_ibfk_1` FOREIGN KEY (`request_id`) REFERENCES `event_requests` (`request_id`),
  CONSTRAINT `proposals_ibfk_2` FOREIGN KEY (`organizer_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `proposals`
--

LOCK TABLES `proposals` WRITE;
/*!40000 ALTER TABLE `proposals` DISABLE KEYS */;
INSERT INTO `proposals` VALUES (3,1,8,'birthday event','good company and 7 years experience','super excution plan',15000.00,4999.11,'2026-10-22','Pending','2026-10-15 06:28:19');
/*!40000 ALTER TABLE `proposals` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `registrations`
--

DROP TABLE IF EXISTS `registrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `registrations` (
  `registration_id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `event_id` int(11) DEFAULT NULL,
  `registration_date` timestamp NOT NULL DEFAULT current_timestamp(),
  `full_name` varchar(100) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `gender` enum('Male','Female','Other') DEFAULT NULL,
  `date_of_birth` date DEFAULT NULL,
  `city` varchar(100) DEFAULT NULL,
  `state` varchar(100) DEFAULT NULL,
  `country` varchar(100) DEFAULT NULL,
  `emergency_contact` varchar(20) DEFAULT NULL,
  `team_name` varchar(100) DEFAULT NULL,
  `team_members` int(11) DEFAULT 1,
  `special_requirements` text DEFAULT NULL,
  `payment_status` enum('Not Required','Pending','Approved','Rejected') DEFAULT 'Not Required',
  `payment_screenshot` varchar(255) DEFAULT NULL,
  `payment_method` varchar(50) DEFAULT NULL,
  `transaction_id` varchar(100) DEFAULT NULL,
  `ticket_token` varchar(64) DEFAULT NULL,
  `check_in_status` enum('Not Checked In','Checked In') DEFAULT 'Not Checked In',
  `checked_in_at` timestamp NULL DEFAULT NULL,
  `checked_in_by` int(11) DEFAULT NULL,
  `certificate_id` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`registration_id`),
  UNIQUE KEY `ticket_token` (`ticket_token`),
  UNIQUE KEY `certificate_id` (`certificate_id`),
  KEY `user_id` (`user_id`),
  KEY `event_id` (`event_id`),
  CONSTRAINT `registrations_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `registrations_ibfk_2` FOREIGN KEY (`event_id`) REFERENCES `events` (`event_id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `registrations`
--

LOCK TABLES `registrations` WRITE;
/*!40000 ALTER TABLE `registrations` DISABLE KEYS */;
INSERT INTO `registrations` VALUES (4,3,8,'2026-08-09 10:01:47','Srividya muthukuri','srividya.muthukuri24@sasi.ac.in','6300324367','Female','2006-07-05','guntur','AP','India','','quarts',2,'','Rejected',NULL,'UPI','UTR-HIST-004','TKT-0004-BEEDAF','Not Checked In',NULL,NULL,'CERT-0004-A6CAB5'),(6,2,10,'2026-08-10 08:42:54','Ramya','qwe@gmail.com','1234567891','Female','2006-03-23','guntur','AP','India','9533396431','abcgame',2,'','Not Required',NULL,'Free','FREE-HIST-006','TKT-0006-F33110','Checked In','2026-10-15 09:40:11',6,'CERT-0006-543F39'),(7,1,4,'2026-08-12 03:38:38','sarvagna karibandi','sarvagna.karibandi24@sasi.ac.in','6300324367','Female','2007-07-06','rjy','AP','India','56789012312','tackles',1,'no','Pending',NULL,'UPI','UTR-HIST-007','TKT-0007-01041A','Not Checked In',NULL,NULL,'CERT-0007-9E3080'),(12,7,4,'2026-10-15 09:57:31','karibandi sarvagna','sarvagna.karibandi24@sasi.ac.in','9533396431','Female','2007-07-09','gutala','andharapradesh','India','9876543234','club',1,'','Not Required',NULL,'Free','FREE-044E8E55','TKT-E6A828A0','Not Checked In',NULL,NULL,'CERT-7B849CE5');
/*!40000 ALTER TABLE `registrations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `full_name` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` enum('Admin','Organizer','User') NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'sarvagna karibandi','abc@sasi.ac.in','ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad','User','2026-07-29 04:26:43'),(2,'ramya','qwe@gmail.com','489cd5dbc708c7e541de4d7cd91ce6d0f1613573b7fc5b40d3942ccb9555cf35','User','2026-07-29 04:29:21'),(3,'sara','klo@sasi.ac.in','aced042cecce971f8296a85f066cfd61b2bd60d106666b49d954826a6a8e013c','Organizer','2026-07-29 04:30:35'),(4,'dfg','dfg@sasi.ac.in','dfg','Organizer','2026-08-03 09:09:06'),(5,'dev','zxc@sasi.ac.in','zxc','Organizer','2026-08-09 03:57:37'),(6,'System Administrator','admin@eventsphere.com','e86f78a8a3caf0b60d8e74e5942aa6d86dc150cd3c03338aef25b7d2d7e3acc7','Admin','2026-10-11 04:29:43'),(7,'raha','raha@123','8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92','User','2026-10-15 06:13:17'),(8,'vaha','vaha@1234','8bb0cf6eb9b17d0f7d22b456f121257dc1254e1f01665370476383ea776df414','Organizer','2026-10-15 06:16:08');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-15 15:46:13
