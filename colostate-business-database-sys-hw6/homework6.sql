-- Modify table definitions and stored procedures to “appropriately” restrict or check the data to increase database integrity and keep the data clean. Implement the “CRUD” stored procedures to manage/encrypt/decrypt credit card data – you have already implemented the “Retrieve” stored procedure. These stored procedures must do input validation, and protect from cross-site scripting (which is a form of sql injection) and raise errors back to the web server.
-- Implement a trigger to “log”, into an “audit” table called “CreditCardAudit”, with columns {id(identity), ccAuditType(varchar(20), ccAuditDate(date)}. When the credit card or expiration date column is updated, insert the string “ccUpdated”, with the current time (do NOT put this code into the sp_updateCC stored procedure).

-- Triggers
ALTER TRIGGER [dbo].[TriggerAuditRecord_Insert] ON [dbo].[CreditCard]
FOR INSERT
AS
BEGIN
SET NOCOUNT ON
INSERT INTO CreditCardAudit (id, ccAuditType, ccAuditDate)
SELECT i.ClientID, 'ccCreated', GETDATE()
FROM CreditCard t
INNER JOIN inserted i ON t.ClientID=i.ClientID
END

ALTER TRIGGER [dbo].[TriggerAuditRecord_Update] ON [dbo].[CreditCard]
FOR UPDATE
AS
BEGIN
SET NOCOUNT ON
INSERT INTO CreditCardAudit (id, ccAuditType, ccAuditDate)
SELECT i.ClientID, 'ccUpdated', GETDATE()
FROM CreditCard t
INNER JOIN inserted i ON t.ClientID=i.ClientID
END

-- Stored Procedures
ALTER PROCEDURE [dbo].[sp_retrieveCC]
‐‐ Add the parameters for the stored procedure here
@clientID int
WITH EXECUTE AS OWNER
AS
BEGIN
DECLARE @sqlcmd NVARCHAR(MAX);
DECLARE @params NVARCHAR(MAX);
IF (ISNUMERIC(@clientID) <> 1)
BEGIN
RAISERROR (15600,‐1,‐1, 'Invalid client ID');
END
SET @sqlcmd = N'SELECT Hash, convert (varchar, DecryptByKeyAutoCert(cert_id(''CreditCardCert''), NULL, Encrypted))
AS DecryptedCC, ExpirationDate
FROM CreditCard WHERE clientID = @clientID';
SET @params = N'@clientID int';
EXECUTE sp_executesql @sqlcmd, @params, @clientID;
END

ALTER PROCEDURE [dbo].[sp_insertCC]
‐‐ Add the parameters for the stored procedure here
@clientID int,
@CC varchar(20),
@expDate varchar(10)
‐‐@lastFour varchar(4)
WITH EXECUTE AS OWNER
AS
BEGIN
OPEN SYMMETRIC KEY CreditCardKey DECRYPTION BY certificate CreditCardCert;
IF (PATINDEX('%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%', @CC) = 0)
BEGIN
RAISERROR (15600,‐1,‐1, 'Invalid credit card number format, ex: 1234567891234567');
END
ELSE IF (PATINDEX('%[01]%[1‐9]%[/‐]%[0123]%[0‐9]%[/‐]%[12]%[0‐9]%[0‐9]%[0‐9]%', @expDate) = 0)
BEGIN
RAISERROR (15600,‐1,‐1, 'Invalid exp date format, ex: 02/02/2020');
END
ELSE IF (@expDate < GETDATE())
BEGIN
RAISERROR (15600,‐1,‐1, 'Invalid exp date, card is expired');
END
ELSE IF (ISNUMERIC(@clientID) <> 1)
BEGIN
RAISERROR (15600,‐1,‐1, 'Invalid client ID');
END
ELSE
BEGIN
DECLARE @sqlcmd NVARCHAR(MAX);
DECLARE @params NVARCHAR(MAX);
SET @sqlcmd = N'INSERT INTO CreditCard VALUES (CIS_ZZZ.dbo.HashCC(@CC), EncryptByKey(Key_GUID(''CreditCardKey''), @CC), (SELECT RIGHT(@CC, 4)), @expDate, @clientID)';
SET @params = N'@CC varchar(20), @expDate varchar(10), @clientID int';
EXECUTE sp_executesql @sqlcmd, @params, @CC, @expDate, @clientID;
END
IF @@ERROR <> 0
BEGIN
CLOSE SYMMETRIC KEY CreditCardKey;
RETURN(1)
END
ELSE
BEGIN
CLOSE SYMMETRIC KEY CreditCardKey;
‐‐ RETURN(0)
END
END

ALTER PROCEDURE [dbo].[sp_updateCC]
@clientID int,
@CC varchar(16),
@expDate varchar(10)
WITH EXECUTE AS OWNER
AS
BEGIN
OPEN SYMMETRIC KEY CreditCardKey DECRYPTION BY certificate CreditCardCert;
IF (PATINDEX('%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%', @CC) = 0)
BEGIN
RAISERROR (15600,‐1,‐1, 'Invalid credit card number format, ex: 1234567891234567');
END
ELSE IF (PATINDEX('%[01]%[1‐9]%[/‐]%[0123]%[0‐9]%[/‐]%[12]%[0‐9]%[0‐9]%[0‐9]%', @expDate) = 0)
BEGIN
RAISERROR (15600,‐1,‐1, 'Invalid exp date format, ex: 02/02/2020');
END
ELSE IF (@expDate < GETDATE())
BEGIN
RAISERROR (15600,‐1,‐1, 'Invalid exp date, card is expired');
END
ELSE IF (ISNUMERIC(@clientID) <> 1)
BEGIN
RAISERROR (15600,‐1,‐1, 'Invalid client ID');
END
ELSE
BEGIN
DECLARE @sqlcmd NVARCHAR(MAX);
DECLARE @params NVARCHAR(MAX);
SET @sqlcmd = N'UPDATE CreditCard SET ExpirationDate = @expDate WHERE Hash = (CIS_ZZZ.dbo.HashCC(@CC)) AND ClientID = @clientID';
SET @params = N'@clientID int, @CC varchar(16), @expDate varchar(10)';
EXECUTE sp_executesql @sqlcmd, @params, @clientID, @CC, @expDate;
END
IF @@ERROR <> 0
BEGIN
CLOSE SYMMETRIC KEY CreditCardKey;
RETURN(1)
END
ELSE
BEGIN
CLOSE SYMMETRIC KEY CreditCardKey;
‐‐ RETURN(0)
END
END

ALTER PROCEDURE [dbo].[sp_deleteCC]
@clientID int,
@CC varchar(16)
WITH EXECUTE AS OWNER
AS
BEGIN
OPEN SYMMETRIC KEY CreditCardKey DECRYPTION BY certificate CreditCardCert;
IF (PATINDEX('%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%[0‐9]%', @CC) = 0)
BEGIN
RAISERROR (15600,‐1,‐1, 'Invalid credit card number format, ex: 1234567891234567');
END
ELSE IF (ISNUMERIC(@clientID) <> 1)
BEGIN
RAISERROR (15600,‐1,‐1, 'Invalid client ID');
END
ELSE
BEGIN
DECLARE @sqlcmd NVARCHAR(MAX);
DECLARE @params NVARCHAR(MAX);
SET @sqlcmd = N'DELETE FROM CreditCard WHERE clientID = @clientID AND Hash = (CIS_ZZZ.dbo.HashCC(@CC))';
SET @params = N'@clientID int, @CC varchar(16)';
EXECUTE sp_executesql @sqlcmd, @params, @clientID, @CC;
END
IF @@ERROR <> 0
BEGIN
CLOSE SYMMETRIC KEY CreditCardKey;
RETURN(1)
END
ELSE
BEGIN
CLOSE SYMMETRIC KEY CreditCardKey;
‐‐ RETURN(0)
END
END
