CREATE TABLE Category (
    CategoryId INT PRIMARY KEY,
    Name VARCHAR(120) NOT NULL
);

CREATE TABLE Product (
    ProductId INT PRIMARY KEY,
    Name VARCHAR(160) NOT NULL,
    CategoryId INT NOT NULL,
    Price NUMERIC(10,2) NOT NULL,
    Stock INT NOT NULL,
    Description VARCHAR(255),
    CONSTRAINT FK_ProductCategory FOREIGN KEY (CategoryId) REFERENCES Category(CategoryId)
);

CREATE TABLE Customer (
    CustomerId INT PRIMARY KEY,
    FirstName VARCHAR(40) NOT NULL,
    LastName VARCHAR(40) NOT NULL,
    Email VARCHAR(60) NOT NULL,
    Address VARCHAR(70),
    City VARCHAR(40),
    State VARCHAR(40),
    Country VARCHAR(40),
    PostalCode VARCHAR(10),
    Phone VARCHAR(24)
);

CREATE TABLE Employee (
    EmployeeId INT PRIMARY KEY,
    FirstName VARCHAR(20) NOT NULL,
    LastName VARCHAR(20) NOT NULL,
    Title VARCHAR(30),
    HireDate TIMESTAMP,
    Email VARCHAR(60)
);

CREATE TABLE Supplier (
    SupplierId INT PRIMARY KEY,
    Name VARCHAR(120) NOT NULL,
    ContactName VARCHAR(60),
    Phone VARCHAR(24),
    Email VARCHAR(60)
);

CREATE TABLE "order" (
    OrderId INT PRIMARY KEY,
    CustomerId INT NOT NULL,
    OrderDate TIMESTAMP NOT NULL,
    Status VARCHAR(20) NOT NULL,
    Total NUMERIC(10,2) NOT NULL,
    CONSTRAINT FK_OrderCustomer FOREIGN KEY (CustomerId) REFERENCES Customer(CustomerId)
);

CREATE TABLE OrderItem (
    OrderItemId INT PRIMARY KEY,
    OrderId INT NOT NULL,
    ProductId INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice NUMERIC(10,2) NOT NULL,
    CONSTRAINT FK_OrderItemOrder FOREIGN KEY (OrderId) REFERENCES "order"(OrderId),
    CONSTRAINT FK_OrderItemProduct FOREIGN KEY (ProductId) REFERENCES Product(ProductId)
);

CREATE TABLE ProductSupplier (
    ProductId INT NOT NULL,
    SupplierId INT NOT NULL,
    CONSTRAINT PK_ProductSupplier PRIMARY KEY (ProductId, SupplierId),
    CONSTRAINT FK_ProductSupplierProduct FOREIGN KEY (ProductId) REFERENCES Product(ProductId),
    CONSTRAINT FK_ProductSupplierSupplier FOREIGN KEY (SupplierId) REFERENCES Supplier(SupplierId)
);

CREATE TABLE "user" (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL
);

-- Function to continuously generate users over a duration

CREATE OR REPLACE FUNCTION generate_random_users(seconds_to_run INT DEFAULT 60)
RETURNS TABLE(users_created INT, actual_duration INTERVAL) AS $$
DECLARE
    end_time TIMESTAMP;
    start_time TIMESTAMP;
    counter INT := 0;
    first_names TEXT[] := ARRAY[
        'John', 'Jane', 'Mike', 'Sarah', 'Tom', 'Lisa', 'David', 'Emma', 'Chris', 'Anna',
        'Robert', 'Maria', 'James', 'Jennifer', 'William', 'Patricia', 'Richard', 'Linda', 'Joseph', 'Barbara',
        'Thomas', 'Susan', 'Charles', 'Jessica', 'Daniel', 'Matthew', 'Nancy', 'Paul', 'Mark', 'Elizabeth',
        'Donald', 'Betty', 'George', 'Helen', 'Kenneth', 'Sandra', 'Steven', 'Donna', 'Edward', 'Carol',
        'Brian', 'Ruth', 'Ronald', 'Sharon', 'Kevin', 'Michelle', 'Jason', 'Laura', 'Jeffrey', 'Amy',
        'Ryan', 'Shirley', 'Jacob', 'Angela', 'Gary', 'Ashley', 'Nicholas', 'Emily', 'Eric', 'Kimberly',
        'Jonathan', 'Deborah', 'Stephen', 'Dorothy', 'Larry', 'Brenda', 'Justin', 'Emma', 'Scott', 'Lisa',
        'Brandon', 'Nancy', 'Benjamin', 'Karen', 'Samuel', 'Betty', 'Frank', 'Dorothy', 'Gregory', 'Sandra',
        'Raymond', 'Ashley', 'Alexander', 'Kimberly', 'Patrick', 'Donna', 'Jack', 'Emily', 'Dennis', 'Michelle',
        'Jerry', 'Carol', 'Tyler', 'Amanda', 'Aaron', 'Melissa', 'Jose', 'Deborah', 'Nathan', 'Stephanie',
        'Henry', 'Rebecca', 'Zachary', 'Laura', 'Douglas', 'Helen', 'Peter', 'Sharon', 'Adam', 'Cynthia',
        'Kyle', 'Kathleen', 'Noah', 'Amy', 'Albert', 'Shirley', 'Ethan', 'Angela', 'Wayne', 'Anna',
        'Carl', 'Brenda', 'Dylan', 'Emma', 'Jordan', 'Pamela', 'Mason', 'Nicole', 'Logan', 'Samantha'
    ];
    last_names TEXT[] := ARRAY[
        'Smith', 'Johnson', 'Brown', 'Davis', 'Wilson', 'Moore', 'Taylor', 'Anderson', 'Thomas', 'Jackson',
        'White', 'Harris', 'Martin', 'Thompson', 'Garcia', 'Martinez', 'Robinson', 'Clark', 'Rodriguez', 'Lewis',
        'Lee', 'Walker', 'Hall', 'Allen', 'Young', 'King', 'Wright', 'Lopez', 'Hill', 'Scott',
        'Green', 'Adams', 'Baker', 'Gonzalez', 'Nelson', 'Carter', 'Mitchell', 'Perez', 'Roberts', 'Turner',
        'Phillips', 'Campbell', 'Parker', 'Evans', 'Edwards', 'Collins', 'Stewart', 'Sanchez', 'Morris', 'Rogers',
        'Reed', 'Cook', 'Morgan', 'Bell', 'Murphy', 'Bailey', 'Rivera', 'Cooper', 'Richardson', 'Cox',
        'Howard', 'Ward', 'Torres', 'Peterson', 'Gray', 'Ramirez', 'James', 'Watson', 'Brooks', 'Kelly',
        'Sanders', 'Price', 'Bennett', 'Wood', 'Barnes', 'Ross', 'Henderson', 'Coleman', 'Jenkins', 'Perry',
        'Powell', 'Long', 'Patterson', 'Hughes', 'Flores', 'Washington', 'Butler', 'Simmons', 'Foster', 'Gonzales',
        'Bryant', 'Alexander', 'Russell', 'Griffin', 'Diaz', 'Hayes', 'Myers', 'Ford', 'Hamilton', 'Graham',
        'Sullivan', 'Wallace', 'Woods', 'Cole', 'West', 'Jordan', 'Owens', 'Reynolds', 'Fisher', 'Ellis',
        'Harrison', 'Gibson', 'McDonald', 'Cruz', 'Marshall', 'Ortiz', 'Gomez', 'Murray', 'Freeman', 'Wells',
        'Webb', 'Simpson', 'Stevens', 'Tucker', 'Porter', 'Hunter', 'Hicks', 'Crawford', 'Henry', 'Boyd',
        'Mason', 'Morales', 'Kennedy', 'Warren', 'Dixon', 'Ramos', 'Reyes', 'Burns', 'Gordon', 'Shaw',
        'Holmes', 'Rice', 'Robertson', 'Hunt', 'Black', 'Daniels', 'Palmer', 'Mills', 'Nichols', 'Grant'
    ];
    user_id INT;
    selected_first_name TEXT;
    selected_last_name TEXT;
    generated_username TEXT;
BEGIN
    start_time := clock_timestamp();
    end_time := clock_timestamp() + (seconds_to_run || ' seconds')::INTERVAL;
    
    WHILE clock_timestamp() < end_time LOOP
        selected_first_name := first_names[1 + floor(random() * array_length(first_names, 1))];
        selected_last_name := last_names[1 + floor(random() * array_length(last_names, 1))];
        
        generated_username := LOWER(
            RPAD(LEFT(selected_first_name, 2), 2, '0') || 
            RPAD(LEFT(selected_last_name, 6), 6, '0')
        );
        
        INSERT INTO "user" (username, first_name, last_name, email)
        VALUES (
            generated_username,
            selected_first_name,
            selected_last_name,
            generated_username || '@example.com'
        )
        RETURNING id INTO user_id;
        
        counter := counter + 1;
        
        -- Sleep for 0.1 seconds to achieve 10 users per second
        PERFORM pg_sleep(0.1);
    END LOOP;
    
    RETURN QUERY SELECT counter, clock_timestamp() - start_time;
END;
$$ LANGUAGE plpgsql;

-- Initial load of data to build the e-commerce dataset

INSERT INTO Category (CategoryId, Name) VALUES (1, 'Electronics');
INSERT INTO Category (CategoryId, Name) VALUES (2, 'Books');
INSERT INTO Category (CategoryId, Name) VALUES (3, 'Clothing');
INSERT INTO Category (CategoryId, Name) VALUES (4, 'Home & Kitchen');
INSERT INTO Category (CategoryId, Name) VALUES (5, 'Sports');
INSERT INTO Category (CategoryId, Name) VALUES (6, 'Toys');
INSERT INTO Category (CategoryId, Name) VALUES (7, 'Beauty');
INSERT INTO Category (CategoryId, Name) VALUES (8, 'Automotive');
INSERT INTO Category (CategoryId, Name) VALUES (9, 'Garden');
INSERT INTO Category (CategoryId, Name) VALUES (10, 'Health');
INSERT INTO Category (CategoryId, Name) VALUES (11, 'Jewelry');
INSERT INTO Category (CategoryId, Name) VALUES (12, 'Music');
INSERT INTO Category (CategoryId, Name) VALUES (13, 'Office Supplies');
INSERT INTO Category (CategoryId, Name) VALUES (14, 'Pet Supplies');
INSERT INTO Category (CategoryId, Name) VALUES (15, 'Baby');
INSERT INTO Category (CategoryId, Name) VALUES (16, 'Shoes');
INSERT INTO Category (CategoryId, Name) VALUES (17, 'Games');
INSERT INTO Category (CategoryId, Name) VALUES (18, 'Outdoors');
INSERT INTO Category (CategoryId, Name) VALUES (19, 'Groceries');
INSERT INTO Category (CategoryId, Name) VALUES (20, 'Crafts');
INSERT INTO Category (CategoryId, Name) VALUES (21, 'Watches');
INSERT INTO Category (CategoryId, Name) VALUES (22, 'Appliances');
INSERT INTO Category (CategoryId, Name) VALUES (23, 'Bags');
INSERT INTO Category (CategoryId, Name) VALUES (24, 'Furniture');

INSERT INTO Product (ProductId, Name, CategoryId, Price, Stock, Description) VALUES (1, 'Smartphone', 1, 699.99, 50, 'Latest model smartphone');
INSERT INTO Product (ProductId, Name, CategoryId, Price, Stock, Description) VALUES (2, 'Laptop', 1, 1199.99, 30, 'High performance laptop');
INSERT INTO Product (ProductId, Name, CategoryId, Price, Stock, Description) VALUES (3, 'Novel Book', 2, 19.99, 100, 'Bestselling novel');
INSERT INTO Product (ProductId, Name, CategoryId, Price, Stock, Description) VALUES (4, 'T-Shirt', 3, 14.99, 200, 'Cotton t-shirt');
INSERT INTO Product (ProductId, Name, CategoryId, Price, Stock, Description) VALUES (5, 'Blender', 4, 49.99, 40, 'Kitchen blender');
INSERT INTO Product (ProductId, Name, CategoryId, Price, Stock, Description) VALUES (6, 'Football', 5, 29.99, 60, 'Official size football');
INSERT INTO Product (ProductId, Name, CategoryId, Price, Stock, Description) VALUES (7, 'Doll', 6, 24.99, 80, 'Popular kids doll');
INSERT INTO Product (ProductId, Name, CategoryId, Price, Stock, Description) VALUES (8, 'Lipstick', 7, 9.99, 150, 'Red lipstick');
INSERT INTO Product (ProductId, Name, CategoryId, Price, Stock, Description) VALUES (9, 'Car Vacuum', 8, 39.99, 25, 'Portable car vacuum');
INSERT INTO Product (ProductId, Name, CategoryId, Price, Stock, Description) VALUES (10, 'Garden Hose', 9, 34.99, 35, 'Flexible garden hose');
INSERT INTO Product (ProductId, Name, CategoryId, Price, Stock, Description) VALUES (11, 'Vitamins', 10, 24.99, 70, 'Multivitamin tablets');
INSERT INTO Product (ProductId, Name, CategoryId, Price, Stock, Description) VALUES (12, 'Necklace', 11, 199.99, 15, 'Gold necklace');
INSERT INTO Product (ProductId, Name, CategoryId, Price, Stock, Description) VALUES (13, 'Desk Chair', 24, 89.99, 20, 'Ergonomic desk chair');
INSERT INTO Product (ProductId, Name, CategoryId, Price, Stock, Description) VALUES (14, 'Dog Food', 14, 39.99, 60, 'Premium dog food');
INSERT INTO Product (ProductId, Name, CategoryId, Price, Stock, Description) VALUES (15, 'Baby Stroller', 15, 149.99, 10, 'Lightweight stroller');
INSERT INTO Product (ProductId, Name, CategoryId, Price, Stock, Description) VALUES (16, 'Running Shoes', 16, 79.99, 50, 'Comfort running shoes');
INSERT INTO Product (ProductId, Name, CategoryId, Price, Stock, Description) VALUES (17, 'Board Game', 17, 29.99, 40, 'Family board game');
INSERT INTO Product (ProductId, Name, CategoryId, Price, Stock, Description) VALUES (18, 'Tent', 18, 99.99, 15, '2-person camping tent');
INSERT INTO Product (ProductId, Name, CategoryId, Price, Stock, Description) VALUES (19, 'Organic Apples', 19, 4.99, 100, 'Fresh organic apples');
INSERT INTO Product (ProductId, Name, CategoryId, Price, Stock, Description) VALUES (20, 'Paint Set', 20, 24.99, 30, 'Acrylic paint set');
INSERT INTO Product (ProductId, Name, CategoryId, Price, Stock, Description) VALUES (21, 'Wrist Watch', 21, 129.99, 25, 'Waterproof wrist watch');
INSERT INTO Product (ProductId, Name, CategoryId, Price, Stock, Description) VALUES (22, 'Microwave', 22, 149.99, 12, 'Compact microwave oven');
INSERT INTO Product (ProductId, Name, CategoryId, Price, Stock, Description) VALUES (23, 'Handbag', 23, 59.99, 40, 'Leather handbag');
INSERT INTO Product (ProductId, Name, CategoryId, Price, Stock, Description) VALUES (24, 'Bookshelf', 24, 119.99, 8, 'Wooden bookshelf');

INSERT INTO Customer (CustomerId, FirstName, LastName, Email, Address, City, State, Country, PostalCode, Phone) VALUES (1, 'Alice', 'Smith', 'alice.smith@example.com', '123 Main St', 'Springfield', 'IL', 'USA', '62701', '555-1234');
INSERT INTO Customer (CustomerId, FirstName, LastName, Email, Address, City, State, Country, PostalCode, Phone) VALUES (2, 'Bob', 'Johnson', 'bob.johnson@example.com', '456 Oak Ave', 'Lincoln', 'NE', 'USA', '68508', '555-5678');
INSERT INTO Customer (CustomerId, FirstName, LastName, Email, Address, City, State, Country, PostalCode, Phone) VALUES (3, 'Carol', 'Williams', 'carol.williams@example.com', '789 Pine Rd', 'Madison', 'WI', 'USA', '53703', '555-8765');
INSERT INTO Customer (CustomerId, FirstName, LastName, Email, Address, City, State, Country, PostalCode, Phone) VALUES (4, 'Derek', 'Miller', 'derek.miller@example.com', '321 Elm St', 'Denver', 'CO', 'USA', '80203', '555-4321');
INSERT INTO Customer (CustomerId, FirstName, LastName, Email, Address, City, State, Country, PostalCode, Phone) VALUES (5, 'Emma', 'Clark', 'emma.clark@example.com', '654 Maple Ave', 'Austin', 'TX', 'USA', '73301', '555-6789');
INSERT INTO Customer (CustomerId, FirstName, LastName, Email, Address, City, State, Country, PostalCode, Phone) VALUES (6, 'Frank', 'Lewis', 'frank.lewis@example.com', '987 Cedar Rd', 'Seattle', 'WA', 'USA', '98101', '555-9876');

INSERT INTO Employee (EmployeeId, FirstName, LastName, Title, HireDate, Email) VALUES (1, 'David', 'Brown', 'Manager', '2020-01-15', 'david.brown@shop.com');
INSERT INTO Employee (EmployeeId, FirstName, LastName, Title, HireDate, Email) VALUES (2, 'Eva', 'Davis', 'Sales', '2021-03-22', 'eva.davis@shop.com');
INSERT INTO Employee (EmployeeId, FirstName, LastName, Title, HireDate, Email) VALUES (3, 'George', 'Wilson', 'Support', '2022-06-10', 'george.wilson@shop.com');
INSERT INTO Employee (EmployeeId, FirstName, LastName, Title, HireDate, Email) VALUES (4, 'Hannah', 'Moore', 'Marketing', '2023-02-05', 'hannah.moore@shop.com');

INSERT INTO Supplier (SupplierId, Name, ContactName, Phone, Email) VALUES (1, 'TechSource', 'Frank Miller', '555-1111', 'frank@techsource.com');
INSERT INTO Supplier (SupplierId, Name, ContactName, Phone, Email) VALUES (2, 'BookWorld', 'Grace Lee', '555-2222', 'grace@bookworld.com');
INSERT INTO Supplier (SupplierId, Name, ContactName, Phone, Email) VALUES (3, 'FashionHub', 'Irene Scott', '555-3333', 'irene@fashionhub.com');
INSERT INTO Supplier (SupplierId, Name, ContactName, Phone, Email) VALUES (4, 'HomePro', 'Jack White', '555-4444', 'jack@homepro.com');

INSERT INTO ProductSupplier (ProductId, SupplierId) VALUES (1, 1);
INSERT INTO ProductSupplier (ProductId, SupplierId) VALUES (2, 1);
INSERT INTO ProductSupplier (ProductId, SupplierId) VALUES (3, 2);
INSERT INTO ProductSupplier (ProductId, SupplierId) VALUES (4, 3);
INSERT INTO ProductSupplier (ProductId, SupplierId) VALUES (5, 4);
INSERT INTO ProductSupplier (ProductId, SupplierId) VALUES (6, 1);

INSERT INTO "order" (OrderId, CustomerId, OrderDate, Status, Total) VALUES (1, 1, '2023-08-01', 'Shipped', 719.98);
INSERT INTO "order" (OrderId, CustomerId, OrderDate, Status, Total) VALUES (2, 2, '2023-08-02', 'Processing', 34.99);
INSERT INTO "order" (OrderId, CustomerId, OrderDate, Status, Total) VALUES (3, 4, '2023-08-03', 'Delivered', 149.99);
INSERT INTO "order" (OrderId, CustomerId, OrderDate, Status, Total) VALUES (4, 5, '2023-08-04', 'Cancelled', 79.99);

INSERT INTO OrderItem (OrderItemId, OrderId, ProductId, Quantity, UnitPrice) VALUES (1, 1, 1, 1, 699.99);
INSERT INTO OrderItem (OrderItemId, OrderId, ProductId, Quantity, UnitPrice) VALUES (2, 1, 3, 1, 19.99);
INSERT INTO OrderItem (OrderItemId, OrderId, ProductId, Quantity, UnitPrice) VALUES (3, 2, 10, 1, 34.99);
INSERT INTO OrderItem (OrderItemId, OrderId, ProductId, Quantity, UnitPrice) VALUES (4, 3, 15, 1, 149.99);
INSERT INTO OrderItem (OrderItemId, OrderId, ProductId, Quantity, UnitPrice) VALUES (5, 4, 16, 1, 79.99);
INSERT INTO OrderItem (OrderItemId, OrderId, ProductId, Quantity, UnitPrice) VALUES (6, 3, 19, 5, 4.99);
