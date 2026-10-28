create database if not exists flipkart_db;
use flipkart_db;

set sql_safe_updates = 0;

create table if not exists customer (
    customer_id int auto_increment primary key,
    customer_name varchar(100) not null,
    email varchar(100) not null unique,
    phone varchar(15) unique,
    city varchar(50)
);

create table if not exists category (
    category_id int auto_increment primary key,
    category_name varchar(50) not null unique
);

create table if not exists product (
    product_id int auto_increment primary key,
    product_name varchar(100) not null,
    category_id int not null,
    price decimal(10,2) not null check (price > 0),
    foreign key (category_id) references category(category_id)
);

create table orders (
    order_id int auto_increment primary key,
    customer_id int not null,
    order_date date not null default (current_date),
    total_amount decimal(12,2) not null default 0 check (total_amount >= 0),
    order_status varchar(20) not null default 'Pending'
        check (order_status in ('Pending','Shipped','Delivered','Cancelled')),
    foreign key (customer_id) references customer(customer_id)
);

create table order_details (
    order_detail_id int auto_increment primary key,
    order_id int not null,
    product_id int not null,
    quantity int not null check (quantity > 0),
    price decimal(10,2) not null check (price > 0),
    unique (order_id, product_id),
    foreign key (order_id) references orders(order_id) on delete cascade,
    foreign key (product_id) references product(product_id)
);

insert into customer (customer_name, email, phone, city) values
('Arun Kumar', 'arun@gmail.com', '9876543210', 'Chennai'),
('Priya Devi', 'priya@gmail.com', '9876543211', 'Madurai'),
('Karthik Raj', 'karthik@gmail.com', '9876543212', 'Coimbatore'),
('Divya Lakshmi', 'divya@gmail.com', '9876543213', 'Thoothukudi');

insert into category (category_name) values
('Electronics'), ('Fashion'), ('Books');

insert into product (product_name, category_id, price) values
('Smartphone', 1, 15000.00),
('Headphones', 1, 1200.00),
('T-Shirt', 2, 500.00),
('Jeans', 2, 1500.00),
('Java Programming Book', 3, 650.00),
('Laptop', 1, 45000.00);

insert into orders (customer_id, order_date) values
(1, '2026-10-01'),
(2, '2026-10-03'),
(1, '2026-10-10'),
(3, '2026-10-12'),
(4, '2026-10-15');

insert into order_details (order_id, product_id, quantity, price) values
(1, 1, 1, 15000.00),
(1, 2, 2, 1200.00),
(2, 3, 3, 500.00),
(2, 4, 1, 1500.00),
(3, 5, 2, 650.00),
(4, 6, 1, 45000.00),
(4, 2, 1, 1200.00),
(5, 3, 2, 500.00);

update orders o
set o.total_amount = (
    select sum(od.quantity * od.price)
    from order_details od
    where od.order_id = o.order_id
);

start transaction;
insert into orders (customer_id, order_date) values (2, current_date);
set @new_order = last_insert_id();
insert into order_details (order_id, product_id, quantity, price)
select @new_order, product_id, 2, price from product where product_id = 2;
insert into order_details (order_id, product_id, quantity, price)
select @new_order, product_id, 1, price from product where product_id = 5;
insert into order_details (order_id, product_id, quantity, price)
select @new_order, product_id, 1, price from product where product_id = 3;
update orders
set total_amount = (select sum(quantity * price) from order_details where order_id = @new_order)
where order_id = @new_order;
commit;

select order_id, sum(quantity * price) as calculated_total
from order_details
group by order_id;

update orders set order_status = 'Shipped' where order_id = 1;
update orders set order_status = 'Delivered' where order_id = 2;
update orders set order_status = 'Cancelled' where order_id = 5;

update order_details
set quantity = 3
where order_id = 1 and product_id = 2;

update orders o
set o.total_amount = (
    select sum(od.quantity * od.price)
    from order_details od
    where od.order_id = o.order_id
)
where o.order_id = 1;

delete from orders where order_status = 'Cancelled';

select o.order_id, o.order_date, o.order_status,
       c.customer_id, c.customer_name, c.email, c.city,
       p.product_id, p.product_name, cat.category_name,
       od.quantity, od.price, (od.quantity * od.price) as line_total,
       o.total_amount
from orders o
join customer c on o.customer_id = c.customer_id
join order_details od on o.order_id = od.order_id
join product p on od.product_id = p.product_id
join category cat on p.category_id = cat.category_id
order by o.order_id;

select c.customer_name, o.order_id, o.order_date, o.order_status, o.total_amount
from customer c
join orders o on c.customer_id = o.customer_id
order by c.customer_name, o.order_date;

select p.product_name, o.order_id, c.customer_name, od.quantity, (od.quantity * od.price) as amount
from product p
join order_details od on p.product_id = od.product_id
join orders o on od.order_id = o.order_id
join customer c on o.customer_id = c.customer_id
order by p.product_name;

select p.product_name, count(od.order_id) as times_ordered
from product p
left join order_details od on p.product_id = od.product_id
group by p.product_id, p.product_name
order by times_ordered desc;

select p.product_name, coalesce(sum(od.quantity), 0) as total_quantity_sold
from product p
left join order_details od on p.product_id = od.product_id
group by p.product_id, p.product_name
order by total_quantity_sold desc;

select c.customer_name, count(o.order_id) as total_orders
from customer c
join orders o on c.customer_id = o.customer_id
group by c.customer_id, c.customer_name
having count(o.order_id) = (
    select max(order_count)
    from (select count(*) as order_count from orders group by customer_id) t
);

select c.customer_name, coalesce(sum(o.total_amount), 0) as total_spending
from customer c
left join orders o on c.customer_id = o.customer_id
group by c.customer_id, c.customer_name
order by total_spending desc;

select round(avg(total_amount), 2) as average_order_value from orders;

select sum(total_amount) as total_sales_amount from orders;