-- 1.	Вывести к каждому самолету класс обслуживания и количество мест этого класса
select model ->> 'ru' as model, fare_conditions, count(seat_no) as number_of_seats
from aircrafts_data
    join seats
        on aircrafts_data.aircraft_code = seats.aircraft_code
group by model, fare_conditions
group by model;


-- 2.	Найти 3 самых вместительных самолета (модель + кол-во мест)
select ad.model,
       (select count(*) from seats s where ad.aircraft_code = s.aircraft_code) seats
from aircrafts_data ad
order by seats desc limit 3;


-- 3.	Найти все рейсы, которые задерживались более 2 часов
select *
from flights
where (actual_arrival - scheduled_arrival) > interval '2 hour'
    and status = 'Arrived';


-- 4.	Найти последние 10 билетов, купленные в бизнес-классе (fare_conditions = 'Business'), с указанием имени пассажира и контактных данных
select t.passenger_name, t.contact_data
from ticket_flights tf
    join tickets t
         on tf.ticket_no = t.ticket_no
    join bookings b
         on b.book_ref = t.book_ref
where fare_conditions = 'Business'
group by t.passenger_name, t.contact_data, b.book_date
order by b.book_date desc limit 10;


-- 5.	Найти все рейсы, у которых нет забронированных мест в бизнес-классе (fare_conditions = 'Business')
select f.*
from ticket_flights tf
    left join flights f
        on tf.flight_id = f.flight_id
where f.flight_id in
    (select flight_id
     from ticket_flights tf
     where fare_conditions = 'Business'
     group by flight_id
     having count(ticket_no) = 0)
group by f.flight_id;


-- 6.	Получить список аэропортов (airport_name) и городов (city), в которых есть рейсы с задержкой по вылету
select a.airport_name, a.city
from airports a
    join flights f
        on a.airport_code = f.departure_airport
where f.status = 'Delayed'
group by a.airport_name, a.city;


-- 7.	Получить список аэропортов (airport_name) и количество рейсов, вылетающих из каждого аэропорта, отсортированный по убыванию количества рейсов
select a.airport_name, count(f.flight_no) count_flight
from airports a
    join flights f
        on a.airport_code = f.departure_airport
group by a.airport_name
order by count_flight desc;


-- 8.	Найти все рейсы, у которых запланированное время прибытия (scheduled_arrival) было изменено и новое время прибытия (actual_arrival) не совпадает с запланированным
select *
from flights f
where f.scheduled_arrival <> f.actual_arrival
order by f.flight_no;

-- 9.	Вывести код, модель самолета и места не эконом класса для самолета "Аэробус A321-200" с сортировкой по местам
select ad.aircraft_code, model, seats.*
from seats
    join aircrafts_data ad
        on ad.aircraft_code = seats.aircraft_code
where fare_conditions <> 'Economy'
    and model ->>'ru' like '%Аэробус A321-200%'
order by seat_no;


-- 10.	Вывести города, в которых больше 1 аэропорта (код аэропорта, аэропорт, город)
select airport_code, airport_name ->> 'en' as 'name', city ->> 'ru' as 'city'
from airports_data
where city in
    (select city
    from airports_data
    group by city
    having count(*) > 1)
order by city;

-- 11.	Найти пассажиров, у которых суммарная стоимость бронирований превышает среднюю сумму всех бронирований
select t.passenger_name
from tickets t
    left join bookings b
        on t.book_ref = b.book_ref
group by t.passenger_name
having sum(b.total_amount) >
       (select avg(total_amount)
        from bookings);


-- 12.	Найти ближайший вылетающий рейс из Екатеринбурга в Москву, на который еще не завершилась регистрация
select flight_id, dep.city ->> 'ru' as departure, arr.city ->> 'ru' as arrival, status
from flights
    join airports_data as dep
        on flights.departure_airport = dep.airport_code
    join airports_data as arr
        on flights.arrival_airport = arr.airport_code
where dep.city ->> 'ru' = 'Екатеринбург'
    and arr.city ->> 'ru' = 'Москва'
    and flights.status not in ('Departed', 'Arrived', 'Cancelled')
    and scheduled_departure > bookings.now()
order by scheduled_departure limit 1;


-- 13.	Вывести самый дешевый и дорогой билет и стоимость (в одном результирующем ответе)
(select *
 from ticket_flights
 order by amount desc LIMIT 1)
    union all
(select *
 from ticket_flights
 order by amount limit 1);


-- 14.	Написать DDL таблицы Customers, должны быть поля id, firstName, LastName, email, phone. Добавить ограничения на поля (constraints)
create table if not exists bookings."Customers"
(
    id serial,
    first_name varchar(30),
    last_name varchar(30),
    email varchar(30) not null,
    phone varchar(30) not null,
    constraint "Customers_pk"
    primary key (id),
    unique (email),
    unique (phone)
);


-- 15.	Написать DDL таблицы Orders, должен быть id, customerId, quantity. Должен быть внешний ключ на таблицу customers + constraints
create table if not exists "Orders"
(
    id serial,
    customer_id integer not null,
    quantity integer not null,
    constraint "Orders_pk"
    primary key (id),
    constraint "Orders_Customers_id_fk"
    foreign key (customer_id) references "Customers"
);


-- 16.	Написать 5 insert в эти таблицы
insert into "Customers" (id, first_name, last_name, email, phone)
values (5, 'Nam', 'Surn', 'qwe@qwe.qwe', '88005553535'),
       (6, 'Uio', 'Surn', 'qwe2@qwe.qwe', '88005553536'),
       (7, 'Bnm', 'Shjk', 'qwe3@qwe.qwe', '88005553537');


-- 17.	Удалить таблицы
drop table if exists "Customers", "Orders" cascade;
