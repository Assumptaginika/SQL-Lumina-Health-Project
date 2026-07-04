-- •Question 1: Forensic Shift Auditing for Compliance
--•Business Need: A security compliance officer needs to detect potentially fraudulent internal modifications. 
--They need to flag any automated record updates that happened outside standard Monday-to-Friday business operations.
--•Task: Write a query against the audit_logs table to find all rows where the action is strictly 'UPDATE' 
--and the user_id is 'app_backend', but use a date-time function to filter exclusively for modifications that occurred on weekends (Saturday or Sunday).

select * 
from audit_logs
	where action = 'UPDATE' 
	and user_id = 'app_backend'
	and extract(ISODOW from accessed_at) IN (0,6);



--•Question 2: Identifying Long-Term Maintenance Therapies
--•Business Need: The pharmacy division is auditing high-frequency chronic care prescriptions 
--to optimize wholesale inventory purchasing.
--•Task: Write a query against the prescriptions table to extract a unique, non-repeating list of medication_name 
--values, but filter the data to only includE records where the frequency contains the word 'daily' (case-insensitive) 
--and the provider authorized more than 2 refills. Sort the final list alphabetically.
--PRESCRIPTON TABLE-UNIQUEMEDICATION NAME, frquency = daily , refill > 2  , ORDER ASC


select 
	distinct(medication_name)
from prescriptions
	where frequency ilike '%daily%'
	and refills_allowed > 2
order by medication_name asc;

--•Question 3: Screening for Chronic Cohorts by Age
--•Business Need: The Population Health team wants to identify older, high-risk patient segments to enroll them 
--in a proactive wellness pilot program.
--Task: Write a query against the patients table that counts the total number of patients, 
--grouped by their blood_type. Use date arithmetic to ensure the query only calculates totals for patients 
--who are strictly over the age of 50 based on the current date
--count total pt, group by blood group, age above 50 based on cuurent date

select 
	count(patient_id) as total_patient,
	blood_type,
	date_of_birth,
	extract(YEAR from AGE(CURRENT_DATE, date_of_birth)) AS AGE
from patients
group by blood_type, date_of_birth
having AGE(current_date, date_of_birth) > interval '50 years';

--•Question 4: Chronic Disease Medication Audits
--•Business Need: The Quality Assurance board wants to verify that prescribing behaviors perfectly align with 
--primary diagnoses for Type 2 Diabetes (E11.9).
--•Task: Without using subqueries, write a query that joins patients, medical_records, and prescriptions to 
--return a unified list of patient full names (first and last concatenated into a single column), 
--their diagnosis_description, and their prescribed medication_name. Filter the output to strictly display records
--matching code 'E11.9'.
-- pt, med rec, pres. fullname, dia des, med name. grop by e11.9

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


--•Question 5: Clinical Symptom Keyword Profiling
--•Business Need: Management wants to track clinical charting diligence by screening electronic health records 
--for specific physical exam keywords, while filtering out routine operational noise.

--Task: Write a query that joins providers and medical_records to find charts where the clinical_notes string 
--contains either the word 'pain' or 'acute'. Display the provider's full name, their specialty, and a 
--truncated snippet showing only the first 50 characters of the clinical_notes. Explicitly exclude any records 
--where the type_of_record is 'vaccination’.

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

--Question 6: High-Risk Refill Workload Projections (Corrected)

--•Business Need: The internal pharmacy needs to audit active medication regimens that represent both high clinical monitoring risks and
--steady recurring workloads.

--Task: Write a query that pulls data from the prescriptions table to show the medication_name, 
--the average number of refills allowed (rounded
--to 1 decimal place), and the total count of prescriptions written for that drug. Filter the base data to only 
--look at prescriptions with a frequency containing the word 'daily' (case-insensitive) and 
--group the output by the drug name

select 
	medication_name,
	round(avg(refills_allowed),1) as avg_refills,
	count(prescription_id) as total_precriptions
from prescriptions
where frequency ilike '%daily%'
group by medication_name;


--Question 7: Flagging Underutilized Operational States

--Business Need: The Regional Director wants to find specific medical specialties that are experiencing 
--exceptionally low patient volume to assess facility downsizing or resource reallocation.
--Task: Write a query joining providers and appointments to display the providers specialty and the 
--count of completed visits. Use a grouping filter (HAVING) to display only specialties that have managed 
--fewer than 5 total completed appointments.

select 
	p.specialty,
	count(a.appointment_id) as total_visit
from providers p
join appointments a
	on a.provider_id = p.provider_id
where a.status = 'completed'
group by p.specialty
having count(a.appointment_id) < 500;


--•Question 8: High-Risk Patient Encounter Density Tracker
--•Business Need: High-utilization patients often suffer from chronic disease gaps and drive up hospital costs. 
--Case managers need a list of individuals who cross the clinic threshold frequently.

--•Task: Write a query that joins patients and medical_records to calculate the total number of clinical encounters
--logged per patient. Display the patient's ID, combined full name,and the total record count. 
--Use a filter to restrict the final output exclusively to individuals who have more than
--3 separate clinical records on file.

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


--•Question 9: Dynamic Patient Portal Engagement Metrics
--•Business Need: The marketing team needs to evaluate patient portal adoption by looking at
--which demographic brackets are actually showing up to their appointments versus cancelling.
--•Task: Write a query grouping data by patient gender. Calculate the total number of appointments booked, 
--the total number of completed visits, and the total number of lost visits ('canceled' or 'no_show').
--Use conditional logic (CASE WHEN) to build these custom metrics in a single query.

select * from patients
select * from appointments

select 
	p.gender,
	count(a.appointment_id) as total_visit,
	sum(case when a.status = 'completed' then 1 else 0 end) as completed_visit,
	sum(case when a.status  in ('canceled', 'no_show') then 1 else 0 end) as lost_visit
from patients p
join appointments a
on p.patient_id = a.patient_id
group by p.gender




--•Question 10: Executive Capacity Leakage Leaderboard
--•Business Need: The COO needs a master operational dashboard to instantly see which medical fields are 
---losing the most billable provider hours to cancellations and missed slots.

--Task: Write a single query that joins providers and appointments. Group the rows by specialty and 
--calculate: total_bookings, completed_visits, lost_visits (cancellations and no-shows combined), 
--and the leakage_rate (lost visits divided by total bookings, multiplied by 100). 
--Use a LEFT JOIN so empty specialties aren't dropped, use a division guard to prevent zero-division errors, 
--and round the final rate to 2 decimal places.

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
