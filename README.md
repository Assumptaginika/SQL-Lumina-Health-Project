# SQL-Lumina-Health-Project

## Project Background
### Lumina Health Systems is a multi-specialty healthcare network serving 2,500 active patients across Illinois, Indiana, and Wisconsin. Operating multiple clinics and outpatient centers, the organization relies on a centralized Electronic Health Record (EHR) system to manage patient care, appointments, and clinical data. This project analyzes healthcare operations to improve patient retention, optimize clinic capacity, strengthen revenue performance, enhance operational efficiency, and support data-driven decision-making while maintaining regulatory compliance.

## Business Problem
### Lumina Health Systems is facing operational inefficiencies that are impacting revenue, patient retention, and regulatory compliance. High appointment no-shows and cancellations create capacity leakage, leading to lost revenue, longer wait times, patient churn, and increased administrative pressure. These operational challenges also increase the risk of unauthorized data access and potential HIPAA compliance violations. This project focuses on analyzing clinical, financial, and system log data to identify revenue leaks, optimize care delivery, improve patient retention, and strengthen compliance and security across the healthcare network.

## My Role
### As the Healthcare Data Analyst, I analyzed clinical, operational, financial, and system log data using SQL to uncover revenue leaks, map the patient journey, and evaluate operational performance. I performed data audits to identify compliance risks, generated actionable insights from normalized databases, and provided evidence-based recommendations to help leadership improve efficiency, protect revenue, and strengthen patient trust.

## Data Dictionary

| Column Header  | Data Type  | Description |
|------------| --------------------------------------------------------| -----------------| 
|Patient_id |Auto-incrementing (Primary Key)Unique Patient Identifier |Serial|
|First_name |Patient's Legal First Name.| Varchar(50)|
|Last_name | Patient's Legal Last Name. |  Varchar(50) |
| Date_of_birth | Date Of Birth Used For Demographic Grouping And Age Calculation. | Date |
| Gender | Self-reported Gender Identity.  | Varchar(15) |
| Email | Direct Contact Identifier (Unique Constraint). | Varchar(100) |
| Blood_type | ABO Blood Classification Pool. |Varchar(5)
| Created_at | System Registration Timestamp With Timezone Tracking. | Timestamp With Time Zone |
|Provider_id |Auto-incrementing Unique Physician Identifier (Primary Key).| Serial|
| First_name | Clinician's Legal First Name. | Varchar(50)|
| Last_name | Clinician's Legal Last Name. |Varchar(50)|
|Specialty |Certified Medical Field (E.G., Cardiology, Pediatrics).| Varchar(100)|
|License_number |Medical Board License String (Unique Constraint). |Varchar(50)|
| Is_active |State Tracking Whether The Provider Is Actively Practicing At Lumina. |Boolean|
|appointment_id| Unique transaction identifier for each booking (Primary Key). |SERIAL|
| patient_id |Relational link identifying the booking patient (Foreign Key $\rightarrow$ patients).|INT|
|provider_id |Relational link identifying the assigned doctor (Foreign Key $\rightarrow$ providers).|INT|
|appointment_date| Exact scheduled or historical meeting timestamp with timezone. |TIMESTAMP WITH TIME ZONE
|status| State tracking: 'scheduled', 'completed', 'canceled', or 'no_show'. |appointment_status (ENUM)|
|reason_for_visit |Free-text description of symptoms or administrative purpose. |TEXT|
|record_id |Unique chart note entry identifier (Primary Key). |SERIAL|
|patient_id |Preserves clinical context for the patient (Foreign Key $\rightarrow$ patients). |INT|
|provider_id |Identifies the documenting physician (Foreign Key $\rightarrow$ providers). |INT|
|visit_date |Finalized charting date boundary.| DATE|
|type_of_record |Classification: 'visit_note', 'lab_result', 'imaging', or 'vaccination'. |record_type (ENUM)|
|diagnosis_code| Core clinical code (e.g., I10 for Hypertension, E11.9 for Diabetes). |VARCHAR(10)|
|diagnosis_description |Explicit medical definition mapping to the ICD-10 code. |VARCHAR(255)|
|clinical_notes| Free-text medical observations from the clinical evaluation. |TEXT|
|prescription_id |Unique medication tracker (Primary Key).| SERIAL|
|record_id |Links order back to the specific chart note (Foreign Key $\rightarrow$ medical_records).| INT|
|patient_id |Double-checksum reference for dispensing pharmacy (Foreign Key$\rightarrow$ patients).|INT|
|medication_name |Standard generic or brand name of the drug. |VARCHAR(150)|
|dosage |Numeric measurement strength (e.g., 10mg, 500mg).| VARCHAR(50)|
|frequency |Clinical directive for consumption (e.g., 'Once daily'). |VARCHAR(100)|
|start_date |Activation date of the pharmaceutical therapy. |DATE|
|refills_allowed |Allowed count before a formal renewal query is required.| INT|

## Tools Used
#### SQL
#### Postgresql
#### PGAdmin


## Key Analytical Questions
### •Question 1: Forensic Shift Auditing for Compliance 
#### •Business Need: A security compliance officer needs to detect potentially fraudulent internal modifications. They need to flag any automated record updates that happened outside standard Monday-to-Friday business operations.
#### •Task: Write a query against the audit_logs table to find all rows where the action is strictly 'UPDATE' and the user_id is 'app_backend', but use a date-time function to filter exclusively for modifications that occurred on weekends (Saturday or Sunday).

```sql
select * 
from audit_logs
	where action = 'UPDATE' 
	and user_id = 'app_backend'
	and extract(ISODOW from accessed_at) IN (0,6);
```

### •Question 2: Identifying Long-Term Maintenance Therapies
#### •Business Need: The pharmacy division is auditing high-frequency chronic care prescriptions to optimize wholesale inventory purchasing. 
#### •Task: Write a query against the prescriptions table to extract a unique, non-repeating list of medication_name values, but filter the data to only include records where the frequency contains the word 'daily' (case-insensitive) and the provider authorized more than 2 refills. Sort the final list alphabetically.

``` sql
select 
	distinct(medication_name)
from prescriptions
	where frequency ilike '%daily%'
	and refills_allowed > 2
order by medication_name asc;

"medication_name"
"Atorvastatin"
"Ibuprofen"
"Lisinopril"
"Metformin"
```
###  •Question 3: Screening for Chronic Cohorts by Age
#### •Business Need: The Population Health team wants to identify older, high-risk patient segments to enroll them in a proactive wellness pilot program.
#### Task: Write a query against the patients table that counts the total number of patients, grouped by their blood_type. Use date arithmetic to ensure the query only calculates totals for patients who are strictly over the age of 50 based on the current date

 ``` sql
select 
	count(patient_id) as total_patient,
	blood_type,
	date_of_birth,
	extract(YEAR from AGE(CURRENT_DATE, date_of_birth)) AS AGE
from patients
group by blood_type, date_of_birth
having AGE(current_date, date_of_birth) > interval '50 years';



```
### •Question 4: Chronic Disease Medication Audits
#### •Business Need: The Quality Assurance board wants to verify that prescribing behaviors perfectly align with primary diagnoses for Type 2 Diabetes (E11.9).
#### •Task: Without using subqueries, write a query that joins patients, medical_records, and prescriptions to return a unified list of patient full names (first and last concatenated into a single column), their diagnosis_description, and their prescribed medication_name. Filter the output to strictly display records matching code 'E11.9'.
``` sql
select 
	distinct(concat(p.first_name, ' ',p.last_name)) as full_name,
	mr.diagnosis_description,
	mr.diagnosis_code,
	pr.medication_name
		
from patients p
	inner join medical_records mr
on p.patient_id = mr.patient_id
	inner join prescriptions pr
on p.patient_id = pr.patient_id
where diagnosis_code =  'E11.9'

```

### •Question 5: Clinical Symptom Keyword Profiling
#### •Business Need: Management wants to track clinical charting diligence by screening electronic health records for specific physical exam keywords, while filtering out routine operational noise.
#### Task: Write a query that joins providers and medical_records to find charts where the clinical_notes string contains either the word 'pain' or 'acute'. Display the provider's full name, their specialty, and a truncated snippet showing only the first 50 characters of the clinical_notes. Explicitly exclude any records where the type_of_record is 'vaccination’.

```sql
select 
	concat(p.first_name, ' ', p.last_name),
	p.specialty,
	substring(mr.clinical_notes,1, 50),
	mr.type_of_record
from providers p
join medical_records mr
on p.provider_id = mr.provider_id
where type_of_record  != 'vaccination' 
	and (clinical_notes like '%pain%' or clinical_notes like '%acute%')
```


### Question 6: High-Risk Refill Workload Projections (Corrected)
#### •Business Need: The internal pharmacy needs to audit active medication regimens that represent both high clinical monitoring risks and steady recurring workloads.
#### Task: Write a query that pulls data from the prescriptions table to show the medication_name, the average number of refills allowed (rounded to 1 decimal place), and the total count of prescriptions written for that drug. Filter the base data to only look at prescriptions with a frequency containing the word 'daily' (case-insensitive) and group the output by the drug name
``` sql
select 
	medication_name,
	round(avg(refills_allowed),1) as avg_refills,
	count(prescription_id) as total_precriptions
from prescriptions
where frequency ilike '%daily%'
group by medication_name;

"medication_name"	"avg_refills"	"total_precriptions"
"Metformin"	2.0	813
"Lisinopril"	2.1	757
"Ibuprofen"	2.0	745
"Atorvastatin"	2.0	756
```
### Question 7: Flagging Underutilized Operational States
#### Business Need: The Regional Director wants to find specific medical specialties that are experiencing exceptionally low patient volume to assess facility downsizing or resource reallocation.
#### Task: Write a query joining providers and appointments to display the providers specialty and the count of completed visits. Use a grouping filter (HAVING) to display only specialties that have managed fewer than 5 total completed appointments.

``` sql
select 
	p.specialty,
	count(a.appointment_id) as total_visit
from providers p
join appointments a
	on a.provider_id = p.provider_id
where a.status = 'completed'
group by p.specialty
having count(a.appointment_id) < 500;

"specialty"	"total_visit"
"Dermatology"	389
"Orthopedics"	382
```
### •Question 8: High-Risk Patient Encounter Density Tracker
#### •Business Need: High-utilization patients often suffer from chronic disease gaps and drive up hospital costs. Case managers need a list of individuals who cross the clinic threshold frequently.
#### •Task: Write a query that joins patients and medical_records to calculate the total number of clinical encounters logged per patient. Display the patient's ID, combined full name, and the total record count. Use a filter to restrict the final output exclusively to individuals who have more than 3 separate clinical records on file.

``` sql

select 
	p.patient_id,
	concat(p.first_name, '', p.last_name) as fullname,
	count(mr.record_id) as total_records
from patients p
join medical_records mr
on p.patient_id = mr.patient_id
group by 
	p.patient_id,
	p.first_name,
	p.last_name
having count(mr.record_id) > 3
order by total_records asc
```

### •Question 9: Dynamic Patient Portal Engagement Metrics
#### •Business Need: The marketing team needs to evaluate patient portal adoption by looking at which demographic brackets are actually showing up to their appointments versus cancelling.
#### •Task: Write a query grouping data by patient gender. Calculate the total number of appointments booked, the total number of completed visits, and the total number of lost visits ('canceled' or 'no_show'). Use conditional logic (CASE WHEN) to build these custom metrics in a single query.

``` sql
select 
	p.gender,
	count(a.appointment_id) as total_visit,
	sum(case when a.status = 'completed' then 1 else 0 end) as completed_visit,
	sum(case when a.status  in ('canceled', 'no_show') then 1 else 0 end) as lost_visit
from patients p
join appointments a
on p.patient_id = a.patient_id
group by p.gender;


"gender"	"total_visit"	"completed_visit"	"lost_visit"
"Female"	5005	2480	1639
"Male"	5125	2545	1687
```

#### •Question 10: Executive Capacity Leakage Leaderboard
#### •Business Need: The COO needs a master operational dashboard to instantly see which medical fields are losing the most billable provider hours to cancellations and missed slots.
#### Task: Write a single query that joins providers and appointments. Group the rows by specialty and calculate: total_bookings, completed_visits, lost_visits (cancellations and no-shows combined), and the leakage_rate (lost visits divided by total bookings, multiplied by 100). Use a LEFT JOIN so empty specialties aren't dropped, use a division guard to prevent zero-division errors, and round the final rate to 2 decimal places.
``` sql
select 
	p.specialty,
	
	count(a.appointment_id) as total_visit,
	
	sum(case when a.status = 'completed' then 1 else 0 end) as completed_visit,
	
	sum(case when a.status in ('canceled', 'no_show') then 1 else 0 end) as lost_visit,
	
	round(sum(case when a.status in ('canceled', 'no_show') then 1 else 0 end * 100) /
	nullif(count(a.appointment_id),0),2) as leakage_rate

from providers p  
left join appointments a
on p.provider_id = a.provider_id
group by p.specialty
order by leakage_rate desc;
```
## key Insights and Business outcome
| Question| Key insights | Business Outcome|
|--------------|-------------------|--------------|
| Question 1: Forensic Shift Auditing for Complianc| 114 records were flagged as UPDATE actions occurring outside standard Monday–Friday business hours. |This gives the compliance officer a concrete audit trail of after-hours system activity. Each of these 114 rows warrants manual review to confirm whether the update was a legitimate automated process (e.g., scheduled batch job) or an unauthorized/fraudulent change, since off-hours edits fall outside expected operational patterns.|
|Question 2: Identifying Long-Term Maintenance Therapies | Only 4 medications (Atorvastatin, Ibuprofen, Lisinopril, Metformin) meet the criteria of daily frequency with more than 2 refills authorized.|These 4 drugs represent the core "chronic maintenance therapy" basket. The pharmacy division can prioritize these for bulk wholesale purchasing agreements and safety stock planning, since they represent predictable, recurring demand rather than one-off prescriptions.
|Question 3: Screening for Chronic Cohorts by Age| 1,010 patients over age 50 were identified, broken down by blood type.| his defines the total eligible population for the proactive wellness pilot program. The Population Health team can now use the blood-type breakdown to plan resource allocation (e.g., blood donation drives, transfusion-related risk stratification) alongside general chronic care outreach.|
|Question 4: Chronic Disease Medication Audits| 1,167 records link patients diagnosed with Type 2 Diabetes (E11.9) to a prescribed medication.| This volume gives Quality Assurance a full audit set to verify prescribing alignment. If any of these 1,167 records show medications inconsistent with standard diabetes care protocols, they can be flagged for clinical review — supporting compliance with treatment guidelines and reducing malpractice/liability risk.|
|Question 5: Clinical Symptom Keyword Profiling| 845 non-vaccination records contain the keywords "pain" or "acute" in the clinical notes.| This surfaces the volume of charting activity tied to acute or pain-related presentations, excluding routine vaccination visits. Management can use this to assess documentation diligence (are providers thoroughly charting symptomatic visits?) and potentially correlate specialty/provider patterns with acute-case volume for staffing or training decisions.|
|Question 6: High-Risk Refill Workload Projections| The same 4 chronic daily medications show consistent average refills (~2.0–2.1) but high total prescription counts (745–813 each).| This confirms a stable, high-volume refill workload for these drugs. Pharmacy operations can forecast staffing and inventory needs with confidence, since refill patterns are consistent rather than volatile — supporting smoother supply chain planning.|
|Question 7: Flagging Underutilized Operational States| Dermatology (389 visits) and Orthopedics (382 visits) are the only specialties falling below the low-volume threshold in this cut of the data (note: the HAVING < 5 filter as literally described would only catch near-zero counts, so the real business rule was likely a much higher threshold — worth double-checking your query logic here).| These two specialties are candidates for the Regional Director's downsizing/reallocation review. Before acting, leadership should also consider whether appointment volume reflects fewer providers or genuinely lower demand.|
|Question 8: High-Risk Patient Encounter Density Tracker| 617 patients have more than 3 clinical records on file, with individual patients ranging from 4 to 6 total encounters.| This is the target list for case management outreach. Since the max is only 6 encounters, no single patient is an extreme outlier — meaning the "high-utilizer" cohort is broad but moderate in intensity, suggesting a scalable, standardized care-gap intervention rather than individualized crisis management.|
|Question 9: Dynamic Patient Portal Engagement Metrics| Female patients booked 5,005 appointments, with only 2,480 completed (about 49.5%) and 1,639 lost to cancellation/no-show (about 32.7%).| Nearly half of booked appointments for this gender segment don't result in a completed visit. Marketing and patient engagement teams can use this to design targeted reminder campaigns, portal engagement nudges, or scheduling flexibility specifically aimed at reducing no-shows in this demographic.|
|Question 10: Executive Capacity Leakage Leaderboard| Neurology has the highest leakage rate (34.00%) and highest total lost visits (522), while Orthopedics has the lowest leakage rate (31.00%) among the specialties shown — though leakage rates cluster tightly between 31–34% across the board.|Because leakage is consistently high (roughly 1 in 3 bookings) across every specialty, this points to a systemic scheduling or reminder-process issue rather than a problem isolated to one department. The COO can use this leaderboard to prioritize Neurology and Internal Medicine for immediate intervention (highest absolute lost-hour impact) while treating the underlying leakage rate as an organization-wide process fix.|






