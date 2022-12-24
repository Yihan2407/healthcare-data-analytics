USE Healthcare_DB

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Query Data for Patient with ID 21383737
SELECT 
	FirstName,
	LastName,
	City,
	[State]
FROM dimPatient
WHERE dimPatient.PatientNumber = '21383737'


SELECT DISTINCT
	FirstName,
	LastName,
	City,
	[State],
	LocationName,
	dimDateServicePK
FROM FactTable
INNER JOIN dimPatient
	ON dimPatient.dimPatientPK = FactTable.dimPatientPK
INNER JOIN dimLocation
	ON dimLocation.dimLocationPK = FactTable.dimLocationPK
WHERE dimPatient.PatientNumber = '21383737'
	AND LocationName = 'Fairview General Hospital'


SELECT DISTINCT
	dimPatient.FirstName,
	dimPatient.LastName,
	dimPatient.City,
	dimPatient.[State],
	dimLocation.LocationName,
	dimDateServicePK,
	dimPhysician.ProviderName,
	SUM(FactTable.GrossCharge) AS Charges
FROM FactTable
	INNER JOIN dimPatient
		ON dimPatient.dimPatientPK = FactTable.dimPatientPK
	INNER JOIN dimLocation
		ON dimLocation.dimLocationPK = FactTable.dimLocationPK
	INNER JOIN dimPhysician
		ON dimPhysician.dimPhysicianPK = FactTable.dimPhysicianPK
WHERE dimPatient.PatientNumber = '21383737'
	AND LocationName = 'Fairview General Hospital'
GROUP BY 
	dimPatient.FirstName,
	dimPatient.LastName,
	dimPatient.City,
	dimPatient.[State],
	dimLocation.LocationName,
	dimDateServicePK,
	dimPhysician.ProviderName


SELECT 
	dimPhysician.ProviderName,
	dimDiagnosisCode.DiagnosisCode,
	dimDiagnosisCode.DiagnosisCodeDescription,
	dimCptCode.CptCode,
	dimCptCode.CptDesc,
	SUM(FactTable.GrossCharge) AS Charges
FROM FactTable
	INNER JOIN dimPatient
		ON dimPatient.dimPatientPK = FactTable.dimPatientPK
	INNER JOIN dimLocation
		ON dimLocation.dimLocationPK = FactTable.dimLocationPK
	INNER JOIN dimPhysician
		ON dimPhysician.dimPhysicianPK = FactTable.dimPhysicianPK
	INNER JOIN dimDiagnosisCode
		ON dimDiagnosisCode.dimDiagnosisCodePK = FactTable.dimDiagnosisCodePK
	INNER JOIN dimCptCode
		ON dimCptCode.dimCPTCodePK = FactTable.dimCPTCodePK
WHERE dimPatient.PatientNumber = '21383737'
	AND LocationName = 'Fairview General Hospital'
GROUP BY 
	dimPhysician.ProviderName,
	dimDiagnosisCode.DiagnosisCode,
	dimDiagnosisCode.DiagnosisCodeDescription,
	dimCptCode.CptCode,
	dimCptCode.CptDesc


SELECT 
	dimTransaction.[Transaction],
	SUM(FactTable.GrossCharge) AS Charges,
	SUM(FactTable.Payment) AS Payments,
	SUM(FactTable.Adjustment) AS Adjustments,
	SUM(FactTable.AR) AS AR
FROM FactTable
	INNER JOIN dimPatient
		ON dimPatient.dimPatientPK = FactTable.dimPatientPK
	INNER JOIN dimLocation
		ON dimLocation.dimLocationPK = FactTable.dimLocationPK
	INNER JOIN dimPhysician
		ON dimPhysician.dimPhysicianPK = FactTable.dimPhysicianPK
	INNER JOIN dimDiagnosisCode
		ON dimDiagnosisCode.dimDiagnosisCodePK = FactTable.dimDiagnosisCodePK
	INNER JOIN dimCptCode
		ON dimCptCode.dimCPTCodePK = FactTable.dimCPTCodePK
	INNER JOIN dimTransaction
		ON dimTransaction.dimTransactionPK = FactTable.dimTransactionPK
	INNER JOIN dimDate
		ON dimDate.dimDatePostPK = FactTable.dimDatePostPK
WHERE dimPatient.PatientNumber = '21383737'
	AND LocationName = 'Fairview General Hospital'
GROUP BY 
	dimTransaction.[Transaction]

------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Patient Demographics
SELECT (FirstName + ' ' + LastName) AS Full_Name,	
		Email,
		PatientAge as Patient_Age,
		CASE WHEN PatientAge < 18 THEN 'Under 18'
			 WHEN PatientAge BETWEEN 18 AND 65 THEN '18-65'
			 WHEN PatientAge > 65 THEN 'Over 65'
			 END AS Age_Bucket,
		(City + ', ' + State) AS City_State
FROM dimPatient

------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Building a Table that includes: Number of physicians, patients, gross charge and average charge per patients for each location

SELECT LocationName, 
COUNT(DISTINCT ProviderNpi) AS [CountOfPhysicians], 
COUNT(DISTINCT dimPatient.PatientNumber) AS [CountOfPatients],
FORMAT(SUM(GrossCharge), '$#,#') AS [GrossCharges],
FORMAT((SUM(GrossCharge) / COUNT(DISTINCT dimPatient.PatientNumber)), '$#,#.##') AS [AverageChargePerPatient]
FROM FactTable
INNER JOIN dimLocation
	ON dimLocation.dimLocationPK = FactTable.dimLocationPK
INNER JOIN dimPhysician
	ON dimPhysician.dimPhysicianPK = FactTable.dimPhysicianPK
INNER JOIN dimPatient
	ON dimPatient.dimPatientPK = FactTable.dimPatientPK
GROUP BY LocationName
ORDER BY 1


------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- How many dollars have been written off (adjustments) due to credentialing (AdjustmentReason)? Which location has the highest number of credentialing adjustments?
-- How many physicians at this location have been impacted by credentialing adjustments?

SELECT FORMAT(-SUM(Adjustment), '$#,###') AS 'Credit_Writeoff'
FROM FactTable
INNER JOIN dimTransaction
	ON dimTransaction.dimTransactionPK = FactTable.dimTransactionPK
WHERE AdjustmentReason LIKE 'Credentialing'

SELECT LocationName, -SUM(Adjustment) AS 'Credit_Writeoff'
FROM FactTable
INNER JOIN dimLocation
	ON dimLocation.dimLocationPK = FactTable.dimLocationPK
INNER JOIN dimTransaction
	ON dimTransaction.dimTransactionPK = FactTable.dimTransactionPK
WHERE AdjustmentReason LIKE 'Credentialing'
GROUP BY LocationName
ORDER BY 2 DESC
-- Angelstone Community Hospital has the highest number of credentialing adjustments

SELECT COUNT(DISTINCT ProviderNpi) AS 'No_Physicians_Affected'
FROM FactTable
INNER JOIN dimLocation
	ON dimLocation.dimLocationPK = FactTable.dimLocationPK
INNER JOIN dimTransaction
	ON dimTransaction.dimTransactionPK = FactTable.dimTransactionPK
INNER JOIN dimPhysician
	ON dimPhysician.dimPhysicianPK = FactTable.dimPhysicianPK
WHERE AdjustmentReason LIKE 'Credentialing'
	AND LocationName LIKE 'Angelstone Community Hospital'
-- 58 physicians affected by credentialing adjustments

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Number of rows of data in FactTable that include a Gross Charge greater than $100

SELECT COUNT(*) AS [Count]
FROM FactTable
WHERE GrossCharge > 100

------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Number of Unique Patients in Healthcare_DB
SELECT COUNT(DISTINCT PatientNumber) as 'UniquePatients'
FROM dimPatient

------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Number of CptCodes in each CptGrouping
SELECT CptGrouping, COUNT(DISTINCT CptCode) AS [Count]
FROM dimCptCode
GROUP BY CptGrouping
ORDER BY 2 DESC

------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Number of Providers who have submitted a Medicare insurance claim
select COUNT(DISTINCT dimPhysician.ProviderNpi) as 'Count_of_Providers'
FROM FactTable
INNER JOIN dimPhysician
	ON dimPhysician.dimPhysicianPK = FactTable.dimPhysicianPK
INNER JOIN dimPayer
	ON dimPayer.dimPayerPK = FactTable.dimPayerPK
WHERE PayerName = 'Medicare'

------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Gross Collection Rate (GCR) for each LocationName, where GCR = Payments/GrossCharge
SELECT dimLocation.LocationName,
		FORMAT(-SUM(Payment) / Sum(GrossCharge), 'P1') AS 'Gross_collection_rate'
FROM FactTable
INNER JOIN dimLocation
	ON dimLocation.dimLocationPK = FactTable.dimLocationPK
GROUP BY dimLocation.LocationName
ORDER BY 2 DESC

------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Number of CptCodes with more than 100 units
SELECT COUNT(*) AS 'CountCPT>100' FROM
	(SELECT dimCptCode.CptCode, dimCptCode.CptDesc, SUM(CPTUnits) as 'Units'
	FROM FactTable
	INNER JOIN dimCptCode
		ON dimCptCode.dimCPTCodePK = FactTable.dimCPTCodePK
	GROUP BY dimCptCode.CptCode, dimCptCode.CptDesc
	HAVING SUM(CPTUnits) > 100) x

------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Physician speciality that received the highest amount of payments, then show the payments by month for this group of physicians

SELECT dimPhysician.ProviderSpecialty,
		-SUM(Payment) AS 'Sum_of_payments'
FROM FactTable
INNER JOIN dimPhysician
	ON dimPhysician.dimPhysicianPK = FactTable.dimPhysicianPK
GROUP BY dimPhysician.ProviderSpecialty
ORDER BY 2 DESC
-- Internal Medicine received the highest amount of payments.

SELECT	dimDate.MonthYear,
		FORMAT(-SUM(Payment), '$#,###') AS 'Sum_of_payments'
FROM FactTable
INNER JOIN dimPhysician
	ON dimPhysician.dimPhysicianPK = FactTable.dimPhysicianPK
INNER JOIN dimDate
	ON dimDate.dimDatePostPK = FactTable.dimDatePostPK
WHERE dimPhysician.ProviderSpecialty = 'Internal Medicine'
GROUP BY dimDate.MonthYear, 
		 dimDate.MonthPeriod
ORDER BY dimDate.MonthPeriod 
------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Number of CptUnits by DiagnosisCodeGroup that are assigned to a 'J code' Diagnosis (diagnosis codes with the letter J in the code)
SELECT  DiagnosisCodeGroup, SUM(CPTUnits) as 'Sum_CPTUnits'
FROM FactTable
INNER JOIN dimDiagnosisCode
	ON dimDiagnosisCode.dimDiagnosisCodePK = FactTable.dimDiagnosisCodePK
WHERE DiagnosisCode LIKE 'J%'
GROUP BY DiagnosisCodeGroup
ORDER BY 2 DESC
------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- What is the average age of patients by gender for patients seen at Big Heart Community Hospital with a Diagnosis that included Type 2 diabetes?
-- How many patients are included in that average?

SELECT PatientGender,
		FORMAT(AVG(PatientAge), '#.#') AS Avg_PatientAge,
		Count(DISTINCT PatientNumber) AS Patient_Count 
FROM
	(SELECT DISTINCT
		FactTable.PatientNumber,
		PatientGender,
		CONVERT(DECIMAL(6,2), PatientAge) AS PatientAge
	FROM FactTable
	INNER JOIN dimDiagnosisCode
		ON dimDiagnosisCode.dimDiagnosisCodePK = FactTable.dimDiagnosisCodePK
	INNER JOIN dimLocation
		ON dimLocation.dimLocationPK = FactTable.dimLocationPK
	INNER JOIN dimPatient
		ON dimPatient.dimPatientPK = FactTable.dimPatientPK
	WHERE LocationName LIKE 'Big Heart Community Hospital'
		AND DiagnosisCodeDescription LIKE '%Type 2 diabetes%') x
GROUP BY PatientGender

------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Two visit types to compare: 'Office/outpatient visit est' and 'Office/outpatient visit new'
-- Show each CptCode, CptDesc and the associated CptUnits
-- What is the Charge per CptUnit? (2 d.p.)

SELECT CptCode, 
		CptDesc, 
		SUM(CPTUnits) as 'Sum_of_CPTUnits',
		FORMAT(SUM(GrossCharge) / SUM(CPTUnits), '$#.##') AS 'Charge_per_CPTUnit'
FROM FactTable
INNER JOIN dimCptCode
	ON dimCptCode.dimCPTCodePK = FactTable.dimCPTCodePK
WHERE CptDesc LIKE 'Office/outpatient visit est'
	OR CptDesc LIKE 'Office/outpatient visit new'
GROUP BY CptCode, CptDesc
ORDER BY 1,2 DESC

------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Analyze the PaymentPerUnit, by first finding the PaymentPerUnit by PayerName on the following visit type (CptDesc): 'Initial hospital care'.
-- Show each CptCode, CptDesc and associated CptUnits.

select * from dimCptCode
select * from FactTable
select * from dimPayer

SELECT CptCode,
	CptDesc,
	PayerName,
	SUM(CPTUnits) AS [CPTUnits]
	,FORMAT(-SUM(Payment) / NULLIF(SUM(CPTUnits), 0), '$#') AS [PaymentPerUnit]
FROM FactTable
INNER JOIN dimCptCode
	ON dimCptCode.dimCPTCodePK = FactTable.dimCPTCodePK
INNER JOIN dimPayer
	ON dimPayer.dimPayerPK = FactTable.dimPayerPK
WHERE CptDesc LIKE 'Initial hospital care'
GROUP BY CptCode, CptDesc, PayerName


SELECT CptCode,
	CptDesc,
	PayerName,
	SUM(CPTUnits) AS [CPTUnits]
	,FORMAT(-SUM(Payment) / NULLIF(SUM(CPTUnits), 0), '$#') AS [PaymentPerUnit]
FROM FactTable
INNER JOIN dimCptCode
	ON dimCptCode.dimCPTCodePK = FactTable.dimCPTCodePK
INNER JOIN dimPayer
	ON dimPayer.dimPayerPK = FactTable.dimPayerPK
WHERE CptDesc LIKE 'Initial hospital care'
	AND CptCode = '99223'
GROUP BY CptCode, CptDesc, PayerName
-- We can see that paying by commercial means is the most expensive, following by Medicare and Medicaid.

------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Find the NetCharge (Gross Charges - Contractual Adjustments) using FactTable, then 
-- Calculate the Net Collection Rate (Payments/Net Charge) for each physician specialty

SELECT ProviderSpecialty,
		FORMAT(GrossCharges, '$#,#') AS 'GrossCharges',
		FORMAT(ContractualAdj, '$#,#') AS 'ContractualAdj',
		FORMAT(NetCharges, '$#,#') AS 'NetCharges',
		FORMAT(Payments, '$#,#') AS 'Payments',
		FORMAT(Adjustments - ContractualAdj, '$#,#') AS 'Adjustments',
		FORMAT((-Payments) / (NetCharges), 'P0') AS 'Net_collection_rate',
		FORMAT(AR, '$#,#') AS 'AR',
		FORMAT(AR/NetCharges, 'P0') AS 'Percent_In_AR',
		FORMAT(-(Adjustments - ContractualAdj)/NetCharges, 'P0') AS 'WriteOff_Percent'
FROM (
	SELECT ProviderSpecialty,
			SUM(GrossCharge) AS 'GrossCharges',
			SUM(CASE WHEN AdjustmentReason = 'Contractual'
					THEN Adjustment
					ELSE NULL
					END) AS 'ContractualAdj',
			SUM(GrossCharge) + SUM(CASE WHEN AdjustmentReason = 'Contractual' 
					THEN Adjustment
					ELSE NULL
					END) AS 'NetCharges',
			SUM(Payment) AS 'Payments',
			SUM(Adjustment) AS 'Adjustments',
			SUM(AR) AS 'AR'
	FROM FactTable
	INNER JOIN dimTransaction
		ON dimTransaction.dimTransactionPK = FactTable.dimTransactionPK
	INNER JOIN dimPhysician
		ON dimPhysician.dimPhysicianPK = FactTable.dimPhysicianPK
	GROUP BY ProviderSpecialty) x
WHERE NetCharges > 25000
ORDER BY net_collection_rate 

WITH a AS(
SELECT Date, COUNT(dimPatient.PatientNumber) AS 'NoOfPatients'
FROM FactTable
INNER JOIN dimDate
	ON dimDate.dimDatePostPK = FactTable.dimDatePostPK
INNER JOIN dimPatient
	ON dimPatient.dimPatientPK = FactTable.dimPatientPK
INNER JOIN dimLocation
	ON dimLocation.dimLocationPK = FactTable.dimLocationPK
WHERE LocationName = 'Angelstone Community Hospital'
GROUP BY Date)
SELECT Date, NoOfPatients, SUM(NoOfPatients) OVER (ORDER BY Date ASC) AS 'CumulativeNoOfPatients'
FROM a
