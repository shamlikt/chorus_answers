--1.Retrieve all active patients
select * from "Patient"
where active is true

--2.Find encounters for a specific patient

select distinct encounter_date,
	status,
	reason,
	created_at
from  "Encounter" where patient_id = '395e53ec-e815-45b8-8912-b2a512560259'

--3.List all observations recorded for a patient

select type observation_type,
	value,
	unit from "Observation"
where patient_id='395e53ec-e815-45b8-8912-b2a512560259'


--4.Find the most recent encounter for each patient

select p.id,
	p.name, 
	p.address,
	max(e.encounter_date) latest_enc_date
	from "Patient" p 
left join "Encounter" e on e.patient_id = p.id
group by 1, 2, 3
order by 4 


--5. Find patients who have had encounters with more than one practitioner

 select patient_id from "Encounter"
 group by patient_id
 having count(distinct practitioner_id) >= 2

--6. Find the top 3 most prescribed medications

select medication_name,
	count(medication_name) from "MedicationRequest"
group by 1 
order by 2 desc
limit 3

--7.Get practitioners who have never prescribed any medication
select distinct e.practitioner_id from "Encounter" e
left join "MedicationRequest" m on m.patient_id = e.patient_id
where m.practitioner_id is null

--8.Find the average number of encounters per patient

select ROUND((select count(id) from "Encounter")*1.0/(select count(id) from "Patient"), 2) avg_encounter from "Encounter"
limit 1

--9 Identify patients who have never had an encounter but have a medication request

select p.id from "Patient" p
left join "Encounter" e on e.patient_id = p.id
left join "MedicationRequest" m on m.patient_id = p.id
group by p.id
having count(e.patient_id) = 0 and count(m.patient_id) > 0 


--10 Determine patient retention by cohort


with CTE as (
	select patient_id,
	encounter_date,
	lead(encounter_date, 1) over(partition by patient_id order by encounter_date) as next_encounter,
	dense_rank() over (partition by patient_id order by encounter_date) as rk
	from "Encounter" 
	
)

select count( patient_id) as new_registration, 
	sum(
	case
	when 
		next_encounter <= encounter_date + INTERVAL '6 months'
		then 1
		else 0
	end
	) as retention_patient

from CTE
where rk = 1 
group by TO_CHAR(encounter_date, 'YYYY-MM')


