﻿/* 1. 
Write an SQL query to report the first name, last name, city, and state of each person in the Person
table. If the address of a personId is not present in the Address table, report null instead.

Person(personId, firstName, lastName), Address(addressId, personId, city, state)
*/
select p.personId, p.firstName, p.lastName, a.city, a.state
from person p
left join address a on p.personId = a.personId; 

/* 2 & 3.
Second Highest Salary
tag: Nth Highest Salary
Write an SQL query to report the second highest salary from the Employee table. If there is no second
highest salary, the query should report null.

employee (id, salary)
*/

SELECT DISTINCT salary
FROM employee
ORDER BY salary DESC
LIMIT 1 OFFSET 1;


SELECT DISTINCT salary
FROM (
  SELECT salary, DENSE_RANK() OVER (ORDER BY salary DESC) AS rank
  FROM employee
) ranked
WHERE rank = 2;


SELECT MAX(salary) 
FROM employee
WHERE salary < (SELECT MAX(salary) FROM employee);

/* 4
Write an SQL query to rank the scores, The ranking should e calculated according to the
2ollowing rules1
 The scores should be ranked 2rom the highest to the lowest+
 If there is a tie between two scores, both should have the same ranking+
 After a tie, the next ranking number should be the next consecutive integer value, In other
words, there should be no holes between ranks,
id is the primary key 2or this table.

Each row o2 this tale contains the score o2 a game,
Score is a floating point value with two decimal
places,
Return the result table ordered by score in descending order.

Table => Scores (int score)
*/



select score, dense_rank() over (order by score desc) as rank from scores


/* 5.
Write an SQL query to find all numbers that appear at least three times consecutively.

Table=> Logs( id int, num varchar)
*/

SELECT num
FROM (
    SELECT num, 
           LEAD(num, 1) OVER (ORDER BY id) AS next_num, 
           LAG(num, 1) OVER (ORDER BY id) AS prev_num
    FROM Logs
) t
WHERE num = next_num AND num = prev_num;


/* 6.
Write an sql query to find the employees who earn more than their managers

Table => Employee (id int, name varchar, salary int, managerId int)
*/

SELECT e1.name AS EmployeeName, e1.salary AS EmployeeSalary, e2.name AS ManagerName, e2.salary AS ManagerSalary
FROM Employee e1
INNER JOIN Employee e2 ON e1.managerId = e2.id
WHERE e1.salary > e2.salary;



SELECT name, salary
FROM Employee
WHERE salary > (SELECT salary FROM Employee AS M WHERE M.id = Employee.managerId);


/* 7.
Duplicate Emails
Write an SQL query to report all the duplicate emails. Note that it's guaranteed that the email
field is not NULL.

Table => person (id int, email varchar)
*/

SELECT email
FROM person
GROUP BY email
HAVING COUNT(email) > 1;

select email 
from (SELECT email, DENSE_RANK() OVER (PARTITION BY email ORDER BY id) AS rank FROM person) ranked 
where rank = 1


/* 8.
Customers Who Never Order
Write an SQL query to report all customers who never order anything.

Table => customers (id int, name varchar)
Table => orders (id int, customerID int)
*/

SELECT c.id, c.name
FROM customers c
LEFT JOIN orders o ON c.id = o.customerID
WHERE o.id IS NULL;


/* 9.
Department highest salary
Write sql query to find employees who have the highest salary in each of the departments

Table => Emplyoee (id int, name varchar, salary int, departmentID int)
Table => Department (id int, name varchar)
*/

-- approach 1  (using subquery)

select employee_name, department_name 
from (select 
	e.id, 
	e.name as employee_name, 
	d.name as department_name, 
    e.salary AS employee_salary,
	dense_rank() over (partition by d.id order by e.salary desc) rank 
	from 
		employee e 
	join
		department d on e.departmentID = d.id
 ) as ranked
where rank = 1

-- approach 2 (using cte)

WITH RankedEmployees AS (
    SELECT
        e.id AS employee_id,
        e.name AS employee_name,
        e.salary AS employee_salary,
        e.departmentID AS employee_department,
        d.name AS department_name,
        RANK() OVER (PARTITION BY d.id ORDER BY e.salary DESC) AS salary_rank
    FROM
        Employee e
    JOIN
        Department d ON e.departmentID = d.id
)

SELECT
    employee_id,
    employee_name,
    employee_salary,
    employee_department,
    department_name
FROM
    RankedEmployees
WHERE
    salary_rank = 1;

    -- here we can use rank() or dense_rank() both would have same result as we are taking only the top value.



/* 10

A company's executives are interested in seeing who earns the most money in each of the
company's departments. A high earner in a department is an employee who has a salary in the
top three unique salaries for that department.

Write an SQL query to find the employees who are high earners in each of the departments.

Table => Emplyoee (id int, name varchar, salary int, departmentID int)
Table => Department (id int, name varchar)
*/

-- approach 1

select employee_name, department_name , salary
from (select 
	e.id, 
	e.name as employee_name, 
	d.name as department_name, 
	e.salary,
	rank() over (partition by d.id order by e.salary desc) rank 
	from 
		employee e 
	join
		department d on e.departmentID = d.id
 ) as ranked
where rank <= 3 

-- approach 2

WITH RankedEmployees AS (
    SELECT
        e.id AS employee_id,
        e.name AS employee_name,
        e.salary AS employee_salary,
        e.departmentID AS employee_department,
        d.name AS department_name,
        dense_rank() OVER (PARTITION BY d.id ORDER BY e.salary DESC) AS rank
    FROM
        Employee e
    JOIN
        Department d ON e.departmentID = d.id
)

SELECT
    employee_name,
    department_name,
    employee_salary
FROM
    RankedEmployees
WHERE
    rank <= 3 ;


/* 11.

Delete Duplicate Emails
Question. 11
Write an SQL query to delete all the duplicate emails, keeping only one unique email with the
smallest id. Note that you are supposed to write a DELETE statement and not a SELECT one.

After running your script, the answer shown is the Person table. The driver will first compile and
run your piece of code and then show the Person table. The final order of the Person table does
not matter.

Table => person (id int, email varchar)

*/

-- approach 1

with rankedEmails as (
	SELECT id, email, DENSE_RANK() OVER (PARTITION BY email ORDER BY id) AS rank 
		FROM 
	person
)

delete person where id in ( select id from rankedEmails where rank > 1)

-- approach 2

WITH DuplicateEmails AS (
    SELECT
        email,
        DENSE_RANK() OVER (ORDER BY email) AS rank
    FROM
        person
)

DELETE FROM person
WHERE (email, rank) IN (
    SELECT email, rank
    FROM DuplicateEmails
    WHERE rank > 1
);


/* 12.
Rising Temperature
Question. 12
Write an SQL query to find all dates' Id with higher temperatures compared to its previous dates
(yesterday).

Table=> Weather (id int, recordDate date, temperature int)
*/

-- approach 1 (this could be okie if comparing previous recorded date.  
--             But the question is for previous day so the next solution is appropriate)

with lagTemperature as(
	select id, recordDate, lag(temperature, 1) over (order by recordDate) as lagTemperature, temperature 
    from Weather 
)

select id, recordDate, temperature from lagTemperature where temperature > lagTemperature

-- approach 2  (this would be appropriate as the previous date is calcuated)

SELECT
    w.id AS date_id,
    w.recordDate AS date,
    w.temperature AS current_temperature
FROM
    Weather w
JOIN
    Weather w_previous ON w.recordDate = DATEADD(day, 1, w_previous.recordDate)
WHERE
    w.temperature > w_previous.temperature;

/* 13.
Trips and Users

The cancellation rate is computed by dividing the number of canceled (by client or driver)
requests with unbanned users by the total number of requests with unbanned users on that
day.

Write a SQL query to find the cancellation rate of requests with unbanned users (both client and
driver must not be banned) each day between "2013-10-01" and "2013-10-03". Round
Cancellation Rate to two decimal points.

Table => Users (users_id int, banned enum, role enum)

*/


/* 14.
Write an SQL query to report the names of the customer that are not referred by the
customer with id = 2.

Table => customer (id int, name varchar,referee_id int )   // referee_id is a customer id who refered the customer
*/

-- approach 1

SELECT name FROM customer WHERE referee_id <> 2 OR referee_id IS NULL;


/* Note:  We would get our mind with the below solution without the validation of NULL.

SELECT name FROM customer WHERE referee_Id <> 2;
But in this case we would not get the customers who did'nt by refered by any customer.  As the question is bring all the customer
but the customer refered by customer id is 2 (referee id)
*/

/* 15.
Customer Placing the Largest Number of Orders

Write an SQL query to find the customer_number for the customer who has placed the largest
number of orders.

The test cases are generated so that exactly one customer will have placed more orders than any
other customer.

Table => orders ( order_number int, customer_number int)
*/

-- approach 1


SELECT top 1 customer_number,COUNT(order_number)
FROM customer_orders
GROUP BY customer_number
ORDER BY COUNT(order_number) DESC

/* we can use limit 1 approach in the above query.  In this query we have an issue if two customers have the same high
orders then it would return only one customer.  The approach 2 is feasible one if we consider this case. as rank() function 
give same rank for equal competitor.*/

-- approach 2

SELECT customer_number
FROM (
    SELECT customer_number, RANK() OVER (ORDER BY COUNT(order_number) DESC) AS rnk
    FROM customer_orders
    GROUP BY customer_number
) ranked
WHERE rnk = 1;

/* 16
Big Countries

A country is big if,
* it has an area of at least three million (i.e., 3000000 km2), or
* it has a population of at least twenty-five million (i.e., 25000000).

Write an SQL query to report the name, population, and area of the big countries.

Table => world (name varchar, continent varchar, area int, population int, gdp bigint)
*/

-- approach 1:
SELECT name, population, area
FROM world
WHERE area >= 3000000 OR population >= 25000000;

-- approach 2: (this one is little fast as if index is used each query is fetched using index and unions it)

SELECT
    name, population, area
FROM
    world
WHERE
    area >= 3000000

UNION

SELECT
    name, population, area
FROM
    world
WHERE
    population >= 25000000; 


/* 17.
Classes More Than 5 Students
Write an SQL query to report all the classes that have at least five students

Table => Courses (student varchar, class varchar)
*/

-- approach 1

SELECT class
FROM Courses
GROUP BY class
HAVING COUNT(student) >= 5;

-- approach 2

SELECT class
FROM (
    SELECT class, COUNT(student) AS student_count
    FROM Courses
    GROUP BY class
) ordered
WHERE student_count >= 5;

/* 18.

Human Traffic of Stadium

Write an SQL query to display the records with three or more rows with consecutive id's, and the
number of people is greater than or equal to 100 for each.

visit_date is the primary key for this table.

Each row of this table contains the visit date and visit id to
the stadium with the number of people during the visit.

No two rows will have the same visit_date, and as the id
increases, the dates increase as well.


Table => Stadium (visit_date date (primary_key), id int, people int)
*/

-- approach 1

with filtered_data as (
select id, 
       visit_date, 
       people, 
       LAG(id,1) OVER(order by id) as prevID_1, 
       LAG(id,2) OVER(order by id) as prevID_2,
       LEAD(id,1) OVER(order by id) as nextID_1, 
       LEAD(id,2) OVER(order by id) as nextID_2
from Stadium 
where people>=100
), 

ordered_filtered_data as (
select *, 
       CASE WHEN id+1=nextID_1 AND id+2 = nextID_2 then 'Y' 
            WHEN id-1=prevID_1 AND id-2 = prevID_2 then 'Y' 
            WHEN id-1 = prevID_1 and id+1=nextID_1 then 'Y'
            ELSE 'N' END as flag
from filtered_data
)

select id, visit_date, people from ordered_filtered_data where flag = 'Y'


-- approach 2


WITH partitioned AS (
      SELECT *, id - ROW_NUMBER() OVER (ORDER BY id) AS grp
      FROM stadium
      WHERE people >= 100
    ),
    counted AS (
      SELECT *, COUNT(*) OVER (PARTITION BY grp) AS cnt
      FROM partitioned
    )    
   
    select id , visit_date,people
    from counted
    where cnt>=3

/* 19.
Sales Person
Question. 19
Write an SQL query to report the names of all the salespersons who did not have any orders
related to the company with the name "RED".

Table => company (com_id int, name varchar, city varchar)
Table => SalesPerson (sales_id int, name varchar, salary int, commission_rate int, hire_date date)
Table => Orders (order_id int, order_date date, com_in int, sales_id int, amount int)
*/

SELECT name
FROM salesperson
WHERE
    sales_id NOT IN (
        SELECT s.sales_id
        FROM
            orders AS o
            INNER JOIN salesperson AS s ON o.sales_id = s.sales_id
            INNER JOIN company AS c ON o.com_id = c.com_id
        WHERE c.name = 'RED'
    );

    /*
    There is chance that we end up with below query,

    select sp.name, o.order_id, c.name from SalesPerson sp 
	left join orders o on sp.sales_id = o.sales_id
	left join company c on c.com_id = o.com_id
	where c.name IS NULL or c.name <> 'RED'

    This query brings sales person if it has "RED" and some other company.   
    But we should get only sales person who is not involved with the order "RED".
    So we need fetch the sales person of having RED and exclude from the original list.
    */

