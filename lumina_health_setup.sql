BEGIN;

-- ============================================================================
-- 1. CLEAN SLATE
-- ============================================================================
DROP TABLE IF EXISTS audit_logs CASCADE;
DROP TABLE IF EXISTS prescriptions CASCADE;
DROP TABLE IF EXISTS medical_records CASCADE;
DROP TABLE IF EXISTS appointments CASCADE;
DROP TABLE IF EXISTS providers CASCADE;
DROP TABLE IF EXISTS patients CASCADE;

DROP TYPE IF EXISTS appointment_status CASCADE;
DROP TYPE IF EXISTS record_type CASCADE;

-- Re-create Types
CREATE TYPE appointment_status AS ENUM ('scheduled', 'completed', 'canceled', 'no_show');
CREATE TYPE record_type AS ENUM ('visit_note', 'lab_result', 'imaging', 'vaccination');

-- Re-create Schema
CREATE TABLE patients (
    patient_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    date_of_birth DATE,
    gender VARCHAR(15),
    email VARCHAR(100) UNIQUE,
    blood_type VARCHAR(5),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE providers (
    provider_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    specialty VARCHAR(100),
    license_number VARCHAR(50) UNIQUE,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE appointments (
    appointment_id SERIAL PRIMARY KEY,
    patient_id INT REFERENCES patients(patient_id),
    provider_id INT REFERENCES providers(provider_id),
    appointment_date TIMESTAMP WITH TIME ZONE,
    status appointment_status DEFAULT 'scheduled',
    reason_for_visit TEXT
);

CREATE TABLE medical_records (
    record_id SERIAL PRIMARY KEY,
    patient_id INT REFERENCES patients(patient_id) ON DELETE CASCADE,
    provider_id INT REFERENCES providers(provider_id),
    visit_date DATE,
    type_of_record record_type,
    diagnosis_code VARCHAR(10),
    diagnosis_description VARCHAR(255),
    clinical_notes TEXT
);

CREATE TABLE prescriptions (
    prescription_id SERIAL PRIMARY KEY,
    record_id INT REFERENCES medical_records(record_id) ON DELETE CASCADE,
    patient_id INT REFERENCES patients(patient_id) ON DELETE CASCADE,
    medication_name VARCHAR(150),
    dosage VARCHAR(50),
    frequency VARCHAR(100),
    start_date DATE,
    refills_allowed INT DEFAULT 0
);

CREATE TABLE audit_logs (
    log_id BIGSERIAL PRIMARY KEY,
    user_id VARCHAR(50),
    action VARCHAR(50),
    table_name VARCHAR(50),
    record_id INT,
    accessed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 2. FIXED DATA GENERATOR (PL/pgSQL Block)
-- ============================================================================
DO $$
DECLARE
    -- Pool arrays for structural randomization
    first_names TEXT[] := ARRAY['John', 'Jane', 'Michael', 'Emily', 'Robert', 'Mary', 'William', 'David', 'James', 'Patricia', 'Linda', 'Barbara', 'Richard', 'Joseph', 'Thomas', 'Charles', 'Christopher', 'Daniel', 'Matthew', 'Anthony'];
    last_names TEXT[] := ARRAY['Smith', 'Doe', 'Johnson', 'Brown', 'Davis', 'Miller', 'Wilson', 'Moore', 'Taylor', 'Anderson', 'Thomas', 'Jackson', 'White', 'Harris', 'Martin', 'Thompson', 'Garcia', 'Martinez', 'Robinson', 'Clark'];
    specialties TEXT[] := ARRAY['Cardiology', 'Diagnostic Medicine', 'Pediatrics', 'Family Medicine', 'Internal Medicine', 'Neurology', 'Orthopedics', 'Dermatology'];
    blood_types TEXT[] := ARRAY['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
    
    -- ICD-10 Diagnostics & Medications paired pools
    diags TEXT[][] := ARRAY[
        ARRAY['I10', 'Essential (primary) hypertension', 'Lisinopril', '10mg', 'Once daily'],
        ARRAY['E11.9', 'Type 2 diabetes mellitus without complications', 'Metformin', '500mg', 'Twice daily with meals'],
        ARRAY['G43.909', 'Migraine, unspecified', 'Sumatriptan', '50mg', 'At onset of attack'],
        ARRAY['J45.909', 'Unspecified asthma, uncomplicated', 'Albuterol HFA', '90mcg Inhaler', '2 puffs every 4 hours as needed'],
        ARRAY['M17.9', 'Osteoarthritis of knee, unspecified', 'Ibuprofen', '600mg', 'Three times daily with food'],
        ARRAY['E78.5', 'Hyperlipidemia, unspecified', 'Atorvastatin', '20mg', 'Once daily at bedtime']
    ];
    
    reasons TEXT[] := ARRAY['Routine checkup', 'Follow-up consultation', 'Chronic pain management', 'Acute symptoms relief', 'Prescription renewal refill', 'Lab results review'];
    statuses appointment_status[] := ARRAY['completed', 'completed', 'completed', 'scheduled', 'canceled', 'no_show'];
    rec_types record_type[] := ARRAY['visit_note', 'visit_note', 'lab_result', 'imaging', 'vaccination'];
    db_users TEXT[] := ARRAY['app_backend', 'dr_smith_user', 'dr_jones_user', 'billing_service', 'patient_portal_api'];
    db_actions TEXT[] := ARRAY['SELECT', 'SELECT', 'INSERT', 'UPDATE'];
    target_tables TEXT[] := ARRAY['patients', 'medical_records', 'prescriptions', 'appointments'];

    -- Counters and limits
    i INT;
    j INT;
    rand_idx INT;
    p_count INT := 2500; -- Total Patients to generate
    doc_count INT := 40;  -- Total Doctors to generate
    
    -- Dynamic holding variables
    v_patient_id INT;
    v_provider_id INT;
    v_record_id INT;
    v_date TIMESTAMP;
BEGIN
    RAISE NOTICE 'Generating Base Entities...';

    -- Generate Providers
    FOR i IN 1..doc_count LOOP
        INSERT INTO providers (first_name, last_name, specialty, license_number)
        VALUES (
            first_names[floor(random() * 20 + 1)],
            last_names[floor(random() * 20 + 1)],
            specialties[floor(random() * 8 + 1)],
            'MD' || (100000 + i)
        );
    END LOOP;

    -- Generate Patients
    FOR i IN 1..p_count LOOP
        INSERT INTO patients (first_name, last_name, date_of_birth, gender, email, blood_type, created_at)
        VALUES (
            first_names[floor(random() * 20 + 1)],
            last_names[floor(random() * 20 + 1)],
            CURRENT_DATE - (floor(random() * 24000 + 3650)::int), -- Age between ~10 and 75
            CASE WHEN random() > 0.5 THEN 'Male' ELSE 'Female' END,
            'patient' || i || '@h-tech-example.com',
            blood_types[floor(random() * 8 + 1)],
            NOW() - (random() * INTERVAL '3 years')
        );
    END LOOP;

    RAISE NOTICE 'Generating Relational Clinical Streams...';

    -- Generate appointments, clinical logs, and medical events cascading down
    FOR i IN 1..p_count LOOP
        -- Give every patient between 2 to 6 historical/future appointments
        FOR j IN 1..floor(random() * 5 + 2)::int LOOP
            v_provider_id := floor(random() * doc_count + 1);
            v_date := NOW() + (random() * INTERVAL '1 year') - (random() * INTERVAL '2 years');
            
            -- Insert Appointment
            INSERT INTO appointments (patient_id, provider_id, appointment_date, status, reason_for_visit)
            VALUES (
                i,
                v_provider_id,
                v_date,
                statuses[floor(random() * 6 + 1)],
                reasons[floor(random() * 6 + 1)]
            );

            -- If the appointment occurred in the past and was 'completed', build an EHR & Prescription profile
            IF v_date < NOW() AND random() > 0.15 THEN
                rand_idx := floor(random() * 6 + 1);
                
                INSERT INTO medical_records (patient_id, provider_id, visit_date, type_of_record, diagnosis_code, diagnosis_description, clinical_notes)
                VALUES (
                    i,
                    v_provider_id,
                    v_date::date,
                    rec_types[floor(random() * 5 + 1)],
                    diags[rand_idx][1],
                    diags[rand_idx][2],
                    'Patient presented for evaluation regarding: ' || reasons[floor(random() * 6 + 1)] || '. Evaluated and findings match criteria for standard ' || diags[rand_idx][2] || '.'
                ) RETURNING record_id INTO v_record_id;

                -- 70% of clinical visits yield a therapeutic prescription
                IF random() > 0.3 THEN
                    INSERT INTO prescriptions (record_id, patient_id, medication_name, dosage, frequency, start_date, refills_allowed)
                    VALUES (
                        v_record_id,
                        i,
                        diags[rand_idx][3],
                        diags[rand_idx][4],
                        diags[rand_idx][5],
                        v_date::date,
                        floor(random() * 5)::int
                    );
                END IF;
            END IF;
        END LOOP;
    END LOOP;

    RAISE NOTICE 'Generating Large Scale Security Logs...';

    -- Generate 15,000 HIPAA security audit logs to build a high-volume index stress-test
    FOR i IN 1..15000 LOOP
        INSERT INTO audit_logs (user_id, action, table_name, record_id, accessed_at)
        VALUES (
            db_users[floor(random() * 5 + 1)],
            db_actions[floor(random() * 4 + 1)],
            target_tables[floor(random() * 4 + 1)], -- Fixed inline array syntax bug here
            floor(random() * p_count + 1),
            NOW() - (random() * INTERVAL '180 days')
        );
    END LOOP;

END $$;

-- ============================================================================
-- 3. SCALE INDEXES
-- ============================================================================
CREATE INDEX idx_appointments_perf ON appointments(patient_id, appointment_date);
CREATE INDEX idx_med_records_search ON medical_records(patient_id, diagnosis_code);
CREATE INDEX idx_audit_log_perf ON audit_logs(accessed_at, table_name);

COMMIT;