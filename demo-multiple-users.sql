-- Insert specific users into the target database

INSERT INTO "user" (username, first_name, last_name, email) VALUES ('jasmith0', 'Jane', 'Smith', 'jane.smith@acme.com');
INSERT INTO "user" (username, first_name, last_name, email) VALUES ('rojohnso', 'Robert', 'Johnson', 'robert.johnson@example.com');
INSERT INTO "user" (username, first_name, last_name, email) VALUES ('emdavis0', 'Emily', 'Davis', 'emily.davis@example.com');
INSERT INTO "user" (username, first_name, last_name, email) VALUES ('mibrown0', 'Michael', 'Brown', 'michael.brown@example.com');
INSERT INTO "user" (username, first_name, last_name, email) VALUES ('sawilson', 'Sarah', 'Wilson', 'sarah.wilson@example.com');
INSERT INTO "user" (username, first_name, last_name, email) VALUES ('damoore0', 'David', 'Moore', 'david.moore@example.com');
INSERT INTO "user" (username, first_name, last_name, email) VALUES ('litaylor', 'Lisa', 'Taylor', 'lisa.taylor@example.com');
INSERT INTO "user" (username, first_name, last_name, email) VALUES ('jaanders', 'James', 'Anderson', 'james.anderson@example.com');
INSERT INTO "user" (username, first_name, last_name, email) VALUES ('jethomas', 'Jennifer', 'Thomas', 'jennifer.thomas@example.com');

-- Continuously insert random users for 5 seconds

SELECT * FROM generate_random_users(5);
