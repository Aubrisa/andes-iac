IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'Andes_Store')
    CREATE DATABASE Andes_Store
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'Andes_App') 
    CREATE DATABASE Andes_App
GO

IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = 'andes_login_api') 
    CREATE LOGIN andes_login_api WITH PASSWORD = '${api_store_password}'

IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = 'andes_login_api_security') 
    CREATE LOGIN andes_login_api_security WITH PASSWORD = '${api_security_password}'

IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = 'andes_login_reporting_service') 
    CREATE LOGIN andes_login_reporting_service WITH PASSWORD = '${reporting_password}'

IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = 'andes_login_load_service') 
    CREATE LOGIN andes_login_load_service WITH PASSWORD = '${load_store_password}'

IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = 'andes_login_adjustments_service') 
    CREATE LOGIN andes_login_adjustments_service WITH PASSWORD = '${adjustments_password}'

IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = 'andes_login_murex_service') 
    CREATE LOGIN andes_login_murex_service WITH PASSWORD = '${murex_password}'

USE Andes_Store
GO

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'andes_login_api')
    CREATE USER andes_login_api FOR LOGIN andes_login_api
ALTER ROLE db_owner ADD MEMBER andes_login_api

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'andes_login_reporting_service') 
    CREATE USER andes_login_reporting_service FOR LOGIN andes_login_reporting_service

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'andes_login_load_service') 
    CREATE USER andes_login_load_service FOR LOGIN andes_login_load_service

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'andes_login_adjustments_service') 
    CREATE USER andes_login_adjustments_service FOR LOGIN andes_login_adjustments_service

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'andes_login_murex_service') 
    CREATE USER andes_login_murex_service FOR LOGIN andes_login_murex_service

USE Andes_App
GO

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'andes_login_api') 
    CREATE USER andes_login_api FOR LOGIN andes_login_api

ALTER ROLE db_owner ADD MEMBER andes_login_api

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'andes_login_api_security')
    CREATE USER andes_login_api_security FOR LOGIN andes_login_api_security

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'andes_login_load_service') 
    CREATE USER andes_login_load_service FOR LOGIN andes_login_load_service

               