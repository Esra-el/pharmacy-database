################### DATABASE CREATION ###################
drop database if exists Project;
create database if not exists Project;
use Project;

################## TABLE CREATION ###################
drop table if exists Distributor;

create table if not exists Distributor (
TaxID char(11) primary key,
Name varchar(20)
) Engine=INNODB;

drop table if exists Staff;

create table if not exists Staff (
Id int primary key auto_increment,
Name varchar(15)
) Engine=INNODB;

drop table if exists Medicine;

create table if not exists Medicine (
Id int primary key,
Quantity int,
Price decimal(5,2),
Batch int
) Engine=INNODB;

drop table if exists OrderTable;

create table if not exists OrderTable (
Distributor char(11),
Staff int,
Medicine int,
Quantity int,
Date date,
foreign key (Distributor) references Distributor(TaxID),
foreign key (Staff) references Staff(Id),
foreign key (Medicine) references Medicine(Id)
) Engine=INNODB;

drop table if exists Customer;

create table if not exists Customer (
TaxCode char(16) primary key,
Name varchar(20),
PhoneNumber int,
ChronicDisease boolean
) Engine=INNODB;

drop table if exists Sale;

create table if not exists Sale (
Customer char(16),
Staff int,
Medicine int,
DoctorTaxCode char(16),
foreign key (Customer) references Customer(TaxCode),
foreign key (Staff) references Staff(Id),
foreign key (Medicine) references Medicine(Id)
) Engine=INNODB;

drop table if exists Prescription;

create table if not exists Prescription (
Customer char(16),
Medicine int,
Number char(15),
StartDate date,
EndDate date,
foreign key (Customer) references Customer(TaxCode),
foreign key (Medicine) references Medicine(Id)
) Engine=INNODB;

################### TABLE POPULATION ###################

insert into Distributor values
("FR853757385","FarmaD"),
("FG857392853","MedDib");

insert into Staff values
(1,"Mario"),
(2,"Francesca"),
(3,"Enrico"),
(4,"Emanuele"),
(5,"Laura"),
(6,"Giulia");

insert into Medicine values
(678465, 50, 13.50, 809809098),
(343872, 30, 10.00, 090921928),
(098754, 0, 8.00, 123654786),
(957835, 0, 15.60, 766432657),
(514141, 13, 20.20, 07957657);

insert into OrderTable values
("FR853757385", 4, 098754, 20, '2025-09-02'),
("FR853757385", 4, 957835, 10, '2025-09-02'),
("FG857392853", 3, 514141, 10, '2025-09-16'),
("FG857392853", 1, 957835, 10, '2026-01-09');

insert into Customer values
('RSSMRA03S11D612V', 'Mario Rossi', 154269875, false ),
('MNDLCU00B55F205M', 'Lucia Mondella', 456451287, true),
('TRMLNZ04P17F205Y', 'Lorenzo Tramaglino', 123484551, true),
('LPURST87E16F839A', 'Ernesto Lupi', 465781125, false),
('MZZNNA05E66L219R', 'Anna Mazzoli', 141516358, true),
('FRNFNC90C17D612P', 'Francesco Franchi', 121574896, false);

insert into Sale values
('RSSMRA03S11D612V', 3, 678465, null),
('MNDLCU00B55F205M', 1, 514141, 'DTTDTR84T14H501L'),
('TRMLNZ04P17F205Y', 3, 098754, 'VRDSRA89L53B354W'),
('LPURST87E16F839A', 2, 678465, null),
('TRMLNZ04P17F205Y', 2, 098754, 'VRDSRA89L53B354W'),
('MNDLCU00B55F205M', 1, 514141, 'DTTDTR84T14H501L'),
('FRNFNC90C17D612P', 5, 678465, null),
('TRMLNZ04P17F205Y', 1, 098754, 'VRDSRA89L53B354W'),
('MZZNNA05E66L219R', 6, 957835, 'DTTDTR84T14H501L'),
('MNDLCU00B55F205M', 5, 514141, 'DTTDTR84T14H501L');

insert into Prescription values
('MNDLCU00B55F205M', 514141, '1005A4785412774', '2025-09-09', '2025-12-09'),
('TRMLNZ04P17F205Y', 098754, '12A147475841236','2025-10-22' , '2026-04-22'),
('MZZNNA05E66L219R', 957835, '1A8547458745142', '2025-12-16', '2026-04-16'),
('MNDLCU00B55F205M', 514141, '1300A4854426541', '2026-01-05', '2026-04-05');

################### QUERIES ###################

# Count all orders made on a certain date
select count(*) as NumberOfOrders, Date
from OrderTable
where Date='2025-09-02';

# Find all purchases made by customers with chronic diseases
select Sale.*
from Sale
join Customer on Sale.Customer=Customer.TaxCode
where Customer.ChronicDisease=true;

# Find all medicines in a certain price range and order by descending price
select * from Medicine
where Price>=10 and Price<=20
order by Price desc;

################### VIEWS ###################

drop view if exists ChronicCustomers;

create view ChronicCustomers 
(TaxCode, Name, Medicine)
as select TaxCode, Name, Medicine
from Customer join Sale on Customer.TaxCode=Sale.Customer
where ChronicDisease=true
group by TaxCode, Name, Medicine;

drop view if exists DistributorMedicines;

create view DistributorMedicines
(Medicine, Distributor)
as select Medicine, Distributor
from OrderTable
order by Distributor;

drop view if exists SoldMedicines;

create view SoldMedicines
(Batch, Customer, PhoneNumber, Medicine)
as select Batch, Customer, PhoneNumber, Medicine 
from (Sale, Customer, Medicine)
where Sale.Customer=Customer.TaxCode 
and Sale.Medicine=Medicine.Id
group by Batch, Customer, PhoneNumber, Medicine;

################### PROCEDURES AND FUNCTIONS ###################

drop procedure if exists customerPurchases;

DELIMITER $$

create procedure customerPurchases (TaxCode char(16))
comment 'returns all purchases for a certain customer'
begin
select * from Sale
where Customer=TaxCode;
end $$

drop function if exists numberOfPurchases$$

create function numberOfPurchases (TaxCode char(16))
returns int
deterministic
begin
declare purchases int;
select count(*) from Sale
where Customer=TaxCode into purchases;
return purchases;
end$$

drop function if exists checkFrequentChronicCustomer$$

# checks if a customer has a chronic disease and at least 3 purchases
create function checkFrequentChronicCustomer (TaxCode char(16))
returns boolean
deterministic
begin
declare purchases int;
declare chronic boolean;
select numberOfPurchases(TaxCode) into purchases;
if (exists(
	select ChronicDisease from Customer
	where ChronicDisease=true
    and Customer.TaxCode=TaxCode))
    then set chronic=true;
    else set chronic=false;
    end if;
    
if (purchases >=3 and chronic) 
then return true;
return false;
end if;
end$$

drop procedure if exists checkChronicCustomerInsert$$

create procedure checkChronicCustomerInsert(TaxCode char(16), Id int)
comment 'given a customer and a medicine, returns the number of purchases for that medicine 
but only if the customer has at least 3 purchases and is chronically ill'
begin
if (select checkFrequentChronicCustomer(TaxCode)=true)
then select count(*) from Sale
	where Medicine=Id;
end if;
end$$

DELIMITER ;

call checkChronicCustomerInsert('MNDLCU00B55F205M',514141);

################### TRIGGER ###################

drop trigger if exists checkLargeOrder;

DELIMITER $$

create trigger checkLargeOrder
before insert on Project.OrderTable
for each row
begin
if (new.Quantity>50)
then set new.Quantity=50;
end if;
end$$

DELIMITER ;

insert into OrderTable values
("FG857392853", 6, 514141, 200, '2025-11-03');

select * from OrderTable where Date='2025-11-03';