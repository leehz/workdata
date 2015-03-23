-- This file should be copied as the file /root/mysql.sql in cloud server.

-- MySQL dump 10.13  Distrib 5.5.34, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: ccmp
-- ------------------------------------------------------
-- Server version	5.5.34-0ubuntu0.12.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

DROP DATABASE IF EXISTS `ccmp`;
CREATE DATABASE `ccmp`;
USE `ccmp`;

--
-- Table structure for table `hardware_template`
--

DROP TABLE IF EXISTS `hardware_template`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hardware_template` (
  `HardwareTemplateID` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `Type` VARCHAR(50) NULL DEFAULT NULL,
  `Price` BIGINT(20) NULL DEFAULT NULL,
  `Name` VARCHAR(50) NULL DEFAULT NULL,
  `Description` VARCHAR(255) NULL DEFAULT NULL,
  `CpuLimit` BIGINT NULL DEFAULT NULL,
  `MemoryLimit` BIGINT NULL DEFAULT NULL,
  `DiskLimit` BIGINT NULL DEFAULT NULL,
  `NicLimit` BIGINT NULL DEFAULT NULL,
  PRIMARY KEY (`HardwareTemplateID`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `hardware_template`
--

LOCK TABLES `hardware_template` WRITE;
/*!40000 ALTER TABLE `hardware_template` DISABLE KEYS */;
INSERT INTO `hardware_template` VALUES
(1, 'VM', 1, 'Basic', 'Default Hardware Template: Basic', 1, 1024, 10240, 1),
(2, 'VM', 2, 'Pro', 'Default Hardware Template: Pro', 2, 2048, 20480, 1),
(3, 'VM', 4, 'Premier', 'Default Hardware Template: Premier', 4, 4096, 40960, 1);
/*!40000 ALTER TABLE `hardware_template` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `group_hardware_template_mapping`
--

DROP TABLE IF EXISTS `group_hardware_template_mapping`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `group_hardware_template_mapping` (
  `HardwareTemplateID` BIGINT(20) NOT NULL,
  `GroupID` BIGINT(20) NOT NULL,
  `AuthType` VARCHAR(20) NULL DEFAULT NULL,
  `ValidFrom` BIGINT(10) NULL DEFAULT NULL,
  `ExpiredAfter` BIGINT(10) NULL DEFAULT NULL,
  PRIMARY KEY (`HardwareTemplateID`, `GroupID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `group_hardware_template_mapping`
--

LOCK TABLES `group_hardware_template_mapping` WRITE;
/*!40000 ALTER TABLE `group_hardware_template_mapping` DISABLE KEYS */;
INSERT INTO `group_hardware_template_mapping` VALUES
(1, 2, '', 0, 0),
(2, 2, '', 0, 0),
(3, 2, '', 0, 0);
/*!40000 ALTER TABLE `group_hardware_template_mapping` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cloud_config`
--

DROP TABLE IF EXISTS `cloud_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cloud_config` (
  `Name` varchar(50) COLLATE utf8_unicode_ci NOT NULL,
  `Value` varchar(1024) COLLATE utf8_unicode_ci DEFAULT NULL,
  `Section` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  `Type` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`Name`),
  UNIQUE KEY `configKey_UNIQUE` (`Name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cloud_config`
--

LOCK TABLES `cloud_config` WRITE;
/*!40000 ALTER TABLE `cloud_config` DISABLE KEYS */;
INSERT INTO `cloud_config` VALUES
('Billing_Enabled','false','Billing Manager','bool'),
('Billing_StoragePrice','0.01','Billing Manager','float'),
('Billing_Unit_In_Sec','86400','Billing Manager','int'),
('CPUAlertEnable','false','Perfmon','bool'),
('CPUAlertPeriod','300','Perfmon','int'),
('CPUAlertThreshold','95','Perfmon','int'),
('DefaultSystemImageSize','3072','Cloud Server','int'),
('DiskAlertEnabled','false','Perfmon','bool'),
('DiskAlertThreshold','95','Perfmon','int'),
('EmailFilter','.*','User Management','regexp'),
('EmailServerHost','smtp.clustertech.com','Email Notification','string'),
('EmailServerPasswd','','Email Notification','string'),
('EmailServerPort','587','Email Notification','int'),
('EmailServerUser','ccmp-admin','Email Notification','string'),
('EmailSignature','Clustertech Cloud Management Platform (CCMP)','Email Notification','string'),
('EnableEmailNotification','true','Email Notification','bool'),
('ExpandNewVMImgLastPartFileSys','true','Cloud Server','bool'),
('IgnoreNewVMImgLastPartFileSysExpansionErr','true','Cloud Server','bool'),
('kvmBaseMigrationPort','6666','Virt Server','int'),
('kvmCheckMigrationGapInSecInt','1','Virt Server','int'),
('KvmHAGuaranteeTimeInSecond','60','Virt Server','int'),
('kvmMaxCheckMigrationTimes','3600','Virt Server','int'),
('kvmRemoveMaxWait','3','Virt Server','int'),
('kvmStopMaxRetry','10','Virt Server','int'),
/*To make your life easier, please do not update the 'License' value here.
First, if a wrongly formatted value is used here, the system will crash.
Second, even if a correctly formatted value is used here, the file
src/clustertech.com/ccmp/server/cloud/license/license.go will update this
value to the value in the trial license by the function generateTrialLics().
If you do want to update this field, please use license.INIT_SALT as the salt.*/
('License','1417242013$2a$10$CuEpraUp9CwUKQKwABlei.ti40ytVU8HNKacDogLDHFNq9S1jEO12','License Control','string'),
('lockVmTimeoutInSecInt','300','Virt Server','int'),
('LoopTimeInSec','5','Cloud Server','int'),
('MaxActionsPerLoop','20','Cloud Server','int'),
('MaximumBackupsPerHost','4','Cloud Server','int'),
('MaxNumOfGoRoutines','50','Cloud Server','int'),
('MaxPrivateSwTplPerUser','5','Cloud Server','int'),
('MaxReservationPerLoop','10','Cloud Server','int'),
/*To make your life easier, please do not update the 'MaxResourceNodes' value
here. First, if a wrongly formatted value is used here, the system will crash.
Second, even if a correctly formatted value is used here, the file
src/clustertech.com/ccmp/server/cloud/license/license.go will update this
value to the value in the trial license by the function generateTrialLics().
If you do want to update this field, please use license.INIT_SALT as the salt.*/
('MaxResourceNodes','0000000004$2a$10$0NtWbIZX0TblYSsSVniQee6iV/U/FtQl2NX5gVRzH6ItrN5OvqDyy','License Control','string'),
('MaxTriggeringsPerLoop','10','Cloud Server','int'),
('MinimumCpuReservedPerResource','0','Cloud Server','int'),
('MinimumMemReservedPerResource','2048','Cloud Server','int'),
('OrganizationAddress','Hong Kong','Email Notification','string'),
('OrganizationName','ClusterTech','Email Notification','string'),
('OverallReservePerResource','0.0','Cloud Server','float'),
('PerfMonAlertInterval','300','Perfmon','int'),
('PriorDaysToNotifyLicenseToExpire','30','Email Notification','int'),
('PriorDaysToNotifyMachinesToExpire','3','Email Notification','int'),
('PriorDaysToNotifyStoragesToExpire','3','Email Notification','int'),
('RequireAdminApproval','false','Cloud Server','bool'),
('RequireStrongPassword','true','Cloud Server','bool'),
('retryGapInSecInStopVmInt','2','Virt Server','int'),
('ShowWebLog','true','Debug','bool'),
('TimeoutLongInSec','7200','Cloud Server','int'),
('TimeoutShortInSec','30','Cloud Server','int'),
/*To make your life easier, please do not update the 'TimeRecord' value here.
If a wrongly formatted value is used here, the system will crash.
If you do want to update this field, please use license.INIT_SALT as the salt.*/
('TimeRecord','1387518292$2a$10$S58toVXotKFl012VkKkI..Iwu3.9y6j32ve7CTqSXXG4zuxrxf/s2','License Control','string'),
('UserNameFilter','.*','User Management','regexp'),
('VmHaRetryCount','10','Cloud Server','int');
/*!40000 ALTER TABLE `cloud_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_group_info`
--

DROP TABLE IF EXISTS `user_group_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_group_info` (
  `GroupID` bigint(20) NOT NULL AUTO_INCREMENT,
  `Name` varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  `CpuLimit` bigint(20) DEFAULT '0',
  `MemoryLimit` bigint(20) DEFAULT '0',
  `DiskLimit` bigint(20) DEFAULT '0',
  `Description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `SambaLimit` bigint(20) DEFAULT '0',
  `SubnetId` bigint(20) DEFAULT '-1',
  PRIMARY KEY (`GroupID`),
  UNIQUE KEY `Name` (`Name`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_group_info`
--

LOCK TABLES `user_group_info` WRITE;
/*!40000 ALTER TABLE `user_group_info` DISABLE KEYS */;
INSERT INTO `user_group_info` VALUES
(1,'admin',0,0,0,'',0,0),
(2,'user',320,409600,2048000,'',819200,1);
/*!40000 ALTER TABLE `user_group_info` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_info`
--

DROP TABLE IF EXISTS `user_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_info` (
  `UserID` bigint(20) NOT NULL AUTO_INCREMENT,
  `LoginName` varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  `Password` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  `Email` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  `FirstName` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  `LastName` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  `Address` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `Phone` varchar(20) COLLATE utf8_unicode_ci DEFAULT NULL,
  `GroupID` bigint(20) DEFAULT NULL,
  `IsLeader` tinyint(1) DEFAULT '0',
  `Description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `State` varchar(20) COLLATE utf8_unicode_ci DEFAULT NULL,
  `Money` bigint(20) DEFAULT '0',
  `Deposit` bigint(20) DEFAULT '0',
  `CpuLimit` bigint(20) DEFAULT '0',
  `MemoryLimit` bigint(20) DEFAULT '0',
  `DiskLimit` bigint(20) DEFAULT '0',
  `SambaLimit` bigint(20) DEFAULT '0',
  `SubnetId` bigint(20) DEFAULT '-1',
  PRIMARY KEY (`UserID`),
  UNIQUE KEY `user_name_UNIQUE` (`LoginName`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_info`
--

LOCK TABLES `user_info` WRITE;
/*!40000 ALTER TABLE `user_info` DISABLE KEYS */;
INSERT INTO `user_info` VALUES
(1,'admin','$2a$10$0Mdcc76P26LpcN6ulWdB8OvoIOvlQuNr4s/SSadJqjmWTUX4Tr4QC','ccmp-admin@clustertech.com','Admin','CCMP','ct','123456',1,0,'','OK',0,0,0,0,0,0,-1),
(2,'user','$2a$10$0Mdcc76P26LpcN6ulWdB8OvoIOvlQuNr4s/SSadJqjmWTUX4Tr4QC','ccmp-user@clustertech.com','User','CCMP','ct','',2,0,'','OK',100000,0,10,10240,20480,20480,-1);
/*!40000 ALTER TABLE `user_info` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2013-12-20 21:09:20
