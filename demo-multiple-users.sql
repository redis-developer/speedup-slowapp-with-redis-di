-- Insert some specific users into the database

INSERT INTO "user" (username, first_name, last_name, email) VALUES ('jasmith0', 'Jane', 'Smith', 'jane.smith@acme.com');
INSERT INTO "user" (username, first_name, last_name, email) VALUES ('rojohnso', 'Robert', 'Johnson', 'robert.johnson@example.com');
INSERT INTO "user" (username, first_name, last_name, email) VALUES ('emdavis0', 'Emily', 'Davis', 'emily.davis@example.com');
INSERT INTO "user" (username, first_name, last_name, email) VALUES ('mibrown0', 'Michael', 'Brown', 'michael.brown@example.com');
INSERT INTO "user" (username, first_name, last_name, email) VALUES ('sawilson', 'Sarah', 'Wilson', 'sarah.wilson@example.com');
INSERT INTO "user" (username, first_name, last_name, email) VALUES ('damoore0', 'David', 'Moore', 'david.moore@example.com');
INSERT INTO "user" (username, first_name, last_name, email) VALUES ('litaylor', 'Lisa', 'Taylor', 'lisa.taylor@example.com');
INSERT INTO "user" (username, first_name, last_name, email) VALUES ('jaanders', 'James', 'Anderson', 'james.anderson@example.com');
INSERT INTO "user" (username, first_name, last_name, email) VALUES ('jethomas', 'Jennifer', 'Thomas', 'jennifer.thomas@example.com');

-- Continuously generate users over a duration

CREATE OR REPLACE FUNCTION generate_users_timed(seconds_to_run INT DEFAULT 60)
RETURNS TABLE(users_created INT, actual_duration INTERVAL) AS $$
DECLARE
    end_time TIMESTAMP;
    start_time TIMESTAMP;
    counter INT := 0;
    first_names TEXT[] := ARRAY[
        'John', 'Jane', 'Mike', 'Sarah', 'Tom', 'Lisa', 'David', 'Emma', 'Chris', 'Anna',
        'Robert', 'Maria', 'James', 'Jennifer', 'William', 'Patricia', 'Richard', 'Linda', 'Joseph', 'Barbara',
        'Thomas', 'Susan', 'Charles', 'Jessica', 'Daniel'
    ];
    last_names TEXT[] := ARRAY[
        'Smith', 'Johnson', 'Brown', 'Davis', 'Wilson', 'Moore', 'Taylor', 'Anderson', 'Thomas', 'Jackson',
        'White', 'Harris', 'Martin', 'Thompson', 'Garcia', 'Martinez', 'Robinson', 'Clark', 'Rodriguez', 'Lewis',
        'Lee', 'Walker', 'Hall', 'Allen', 'Young', 'King', 'Wright', 'Lopez', 'Hill', 'Scott',
        'Green', 'Adams', 'Baker', 'Gonzalez', 'Nelson', 'Carter', 'Mitchell', 'Perez', 'Roberts', 'Turner',
        'Phillips', 'Campbell', 'Parker', 'Evans', 'Edwards', 'Collins', 'Stewart', 'Sanchez', 'Morris', 'Rogers'
    ];
    user_id INT;
BEGIN
    start_time := clock_timestamp();
    end_time := clock_timestamp() + (seconds_to_run || ' seconds')::INTERVAL;
    
    WHILE clock_timestamp() < end_time LOOP
        INSERT INTO "user" (username, first_name, last_name, email)
        VALUES (
            'user_' || nextval('user_id_seq'),
            first_names[1 + floor(random() * array_length(first_names, 1))],
            last_names[1 + floor(random() * array_length(last_names, 1))],
            'user_' || currval('user_id_seq') || '@example.com'
        )
        RETURNING id INTO user_id;
        
        counter := counter + 1;
        
        -- Sleep for 0.1 seconds to achieve 10 users per second
        PERFORM pg_sleep(0.1);
    END LOOP;
    
    RETURN QUERY SELECT counter, clock_timestamp() - start_time;
END;
$$ LANGUAGE plpgsql;

-- Invoking the function for 5 seconds

SELECT * FROM generate_users_timed(5);