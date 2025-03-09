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


