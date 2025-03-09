This repository contains the solution to the Chorus interview question for a Data Engineering role.

Question Link: https://github.com/ChorusInnovations/data-engineering-interview

## 1. Create Data Model

### ER Diagram

![ER Diagram](https://github.com/shamlikt/chorus_answer/blob/main/data_modeling/task.png)

### SQL Code

```
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE organization (
       id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
       org_name VARCHAR(50) NOT NULL,
       created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
       updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
       is_deleted BOOLEAN NOT NULL DEFAULT FALSE
       );


CREATE TABLE task_user (
       id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
       username VARCHAR(50) NOT NULL,
       first_name VARCHAR(50) NOT NULL,
       last_name VARCHAR(50) NOT NULL,
       org_id UUID NOT NULL REFERENCES organization(id) ON DELETE CASCADE,
       created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
       updated_at TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP,
       is_deleted BOOLEAN NOT NULL DEFAULT FALSE
       );
     

CREATE TABLE cadence (
    id SMALLSERIAL PRIMARY KEY,
    c_name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT
);

INSERT INTO cadence(c_name, description) VALUES
       ('one_time', 'occurs only once'),
       ('daily', 'repeats every day'),
       ('weekly', 'repeats every week'),
       ('monthly', 'repeats every month');


CREATE TABLE status (
    id SMALLSERIAL PRIMARY KEY,
    s_name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT
);

INSERT INTO status(s_name, description) VALUES
       ('not_started', 'Task has not been started'),
       ('in_progress', 'Task is currently being worked on'),
       ('completed', 'Task has been completed');

CREATE TABLE task_access_type (
    id SMALLSERIAL PRIMARY KEY,
    access_type VARCHAR(50) NOT NULL UNIQUE,
    description TEXT
);

INSERT INTO task_access_type(access_type, description) VALUES
       ('view', 'Only Able to View'),
       ('manage', 'User can manage the task'),
       ('admin', 'Full Access to the task');

CREATE TABLE task (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_name VARCHAR(255) NOT NULL,
    description TEXT,
    cadence_id SMALLINT NOT NULL REFERENCES cadence(id),
    max_instance INTEGER NOT NULL, -- 0 for 
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    start_date DATE NOT NULL,
    created_by UUID REFERENCES task_user(id),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);


CREATE TABLE task_access (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES task(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES task_user(id),
    access_type_id SMALLINT NOT NULL REFERENCES task_access_type(id) DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE(task_id, user_id)
);


CREATE TABLE task_instance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES task(id) ON DELETE CASCADE,
    sequence_number INTEGER NOT NULL,
    status_id SMALLINT NOT NULL REFERENCES status(id) DEFAULT 1, -- Store the latest status only
    reason TEXT,
    run_by UUID REFERENCES task_user(id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(task_id, sequence_number)
);


CREATE TABLE status_history (
    history_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    instance_id UUID NOT NULL REFERENCES task_instance(id) ON DELETE CASCADE,
    status_id SMALLINT NOT NULL REFERENCES status(id),
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reason TEXT
);


```

## 2. SQL Query

### 1.Retrieve all active patients
```
select * from "Patient"
where active is true
```
### 2.Find encounters for a specific patient
```
select distinct encounter_date,
	status,
	reason,
	created_at
from  "Encounter" where patient_id = '395e53ec-e815-45b8-8912-b2a512560259'
```
### 3.List all observations recorded for a patient
```
select type observation_type,
	value,
	unit from "Observation"
where patient_id='395e53ec-e815-45b8-8912-b2a512560259'
```

### 4.Find the most recent encounter for each patient
```
select p.id,
	p.name, 
	p.address,
	max(e.encounter_date) latest_enc_date
	from "Patient" p 
left join "Encounter" e on e.patient_id = p.id
group by 1, 2, 3
order by 4 
```

### 5. Find patients who have had encounters with more than one practitioner
```
 select patient_id from "Encounter"
 group by patient_id
 having count(distinct practitioner_id) >= 2
```
### 6. Find the top 3 most prescribed medications
```
select medication_name,
	count(medication_name) from "MedicationRequest"
group by 1 
order by 2 desc
limit 3
```
### 7.Get practitioners who have never prescribed any medication
```
select distinct e.practitioner_id from "Encounter" e
left join "MedicationRequest" m on m.patient_id = e.patient_id
where m.practitioner_id is null
```
### 8.Find the average number of encounters per patient
```
select ROUND((select count(id) from "Encounter")*1.0/(select count(id) from "Patient"), 2) avg_encounter from "Encounter"
limit 1
```
### 9 Identify patients who have never had an encounter but have a medication request
```
select p.id from "Patient" p
left join "Encounter" e on e.patient_id = p.id
left join "MedicationRequest" m on m.patient_id = p.id
group by p.id
having count(e.patient_id) = 0 and count(m.patient_id) > 0 
```

### 10 Determine patient retention by cohort

```
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
```




