create database itunes_analysis;
use itunes_analysis;

ALTER TABLE album
modify album_id INT,
modify title varchar(255),
modify artist_id INT;

ALTER TABLE ARTIST
MODIFY artist_id INT,
MODIFY name varchar(255);

SELECT * FROM CUSTOMER;

ALTER TABLE CUSTOMER
MODIFY customer_id INT, 
MODIFY first_name VARCHAR(50),
MODIFY last_name VARCHAR(50),
MODIFY company VARCHAR(255),
MODIFY address VARCHAR(255),
MODIFY city VARCHAR(255),
MODIFY state VARCHAR(50),
MODIFY country VARCHAR(50), 
MODIFY postal_code VARCHAR(50), 
MODIFY phone VARCHAR(50),
MODIFY fax VARCHAR(50),
MODIFY email VARCHAR(50), 
MODIFY support_rep_id INT;

SELECT * FROM EMPLOYEE;

SELECT DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'employee'
AND COLUMN_NAME = 'birthdate';

ALTER TABLE employee
ADD birthdate_new DATE,
add hire_date_new DATE;

UPDATE employee
SET 
    birthdate_new = STR_TO_DATE(birthdate, '%d-%m-%Y %H:%i:%s'),
    hire_date_new = STR_TO_DATE(hire_date, '%d-%m-%Y %H:%i:%s');
    
    ALTER TABLE employee
DROP COLUMN birthdate,
DROP COLUMN hire_date;

ALTER TABLE employee
CHANGE birthdate_new birthdate DATE,
CHANGE hire_date_new hire_date DATE;

ALTER TABLE EMPLOYEE
MODIFY employee_id INT,
MODIFY last_name VARCHAR(50),
MODIFY first_name VARCHAR(50),
MODIFY title VARCHAR(255),
MODIFY reports_to FLOAT,
MODIFY levels VARCHAR(50),
MODIFY birthdate datetime,
MODIFY hire_date datetime,
MODIFY address VARCHAR(255),
MODIFY city VARCHAR(50),
MODIFY state VARCHAR(50),
MODIFY country VARCHAR(50),
MODIFY postal_code VARCHAR(50),
MODIFY phone VARCHAR(50),
MODIFY fax VARCHAR(50),
MODIFY email VARCHAR(255);

ALTER TABLE GENRE
MODIFY genre_id INT,
MODIFY name VARCHAR(50);

SELECT * FROM INVOICE;

ALTER TABLE INVOICE
MODIFY invoice_id INT,
MODIFY customer_id INT,
MODIFY invoice_date DATE,
MODIFY billing_address VARCHAR(255),
MODIFY billing_city VARCHAR(50),
MODIFY billing_state VARCHAR(50),
MODIFY billing_country VARCHAR(50),
MODIFY billing_postal_code VARCHAR(50),
MODIFY total FLOAT;

 ALTER TABLE INVOICE_LINE
MODIFY invoice_line_id INT,
MODIFY invoice_id INT,
MODIFY track_id INT,
MODIFY unit_price FLOAT,
MODIFY quantity INT;

ALTER TABLE MEDIA_TYPE
MODIFY media_type_id INT, 
MODIFY name VARCHAR(50);

ALTER TABLE PLAYLIST
MODIFY playlist_id INT,
MODIFY name VARCHAR(50);

ALTER TABLE PLAYLIST_TRACK
MODIFY playlist_id INT,
MODIFY track_id INT;

ALTER TABLE TRACK
MODIFY track_id INT,
MODIFY name VARCHAR(255),
MODIFY album_id INT,
MODIFY media_type_id INT,
MODIFY genre_id INT,
MODIFY composer VARCHAR(255),
MODIFY milliseconds INT,
MODIFY bytes INT,
MODIFY unit_price FLOAT;


-- Ensure ALL parent tables have PRIMARY KEYs
ALTER TABLE artist ADD PRIMARY KEY (artist_id);
ALTER TABLE album ADD PRIMARY KEY (album_id);
ALTER TABLE genre ADD PRIMARY KEY (genre_id);
ALTER TABLE media_type ADD PRIMARY KEY (media_type_id);
ALTER TABLE customer ADD PRIMARY KEY (customer_id);
ALTER TABLE employee ADD PRIMARY KEY (employee_id);
ALTER TABLE invoice ADD PRIMARY KEY (invoice_id);
ALTER TABLE playlist ADD PRIMARY KEY (playlist_id);
ALTER TABLE track ADD PRIMARY KEY (track_id);

-- Core relationships
ALTER TABLE album 
ADD CONSTRAINT fk_album_artist 
FOREIGN KEY (artist_id) REFERENCES artist(artist_id);

ALTER TABLE track 
ADD CONSTRAINT fk_track_album 
FOREIGN KEY (album_id) REFERENCES album(album_id),
ADD CONSTRAINT fk_track_genre 
FOREIGN KEY (genre_id) REFERENCES genre(genre_id),
ADD CONSTRAINT fk_track_media_type 
FOREIGN KEY (media_type_id) REFERENCES media_type(media_type_id);

ALTER TABLE invoice_line 
ADD CONSTRAINT fk_invoice_line_invoice 
FOREIGN KEY (invoice_id) REFERENCES invoice(invoice_id),
ADD CONSTRAINT fk_invoice_line_track 
FOREIGN KEY (track_id) REFERENCES track(track_id);

ALTER TABLE invoice 
ADD CONSTRAINT fk_invoice_customer 
FOREIGN KEY (customer_id) REFERENCES customer(customer_id);

ALTER TABLE playlist_track 
ADD CONSTRAINT fk_playlist_track_playlist 
FOREIGN KEY (playlist_id) REFERENCES playlist(playlist_id),
ADD CONSTRAINT fk_playlist_track_track 
FOREIGN KEY (track_id) REFERENCES track(track_id);


-- See all foreign keys on playlist_track
SELECT 
  CONSTRAINT_NAME, 
  COLUMN_NAME, 
  REFERENCED_TABLE_NAME, 
  REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
WHERE TABLE_NAME = 'playlist_track' 
AND TABLE_SCHEMA = DATABASE()
AND REFERENCED_TABLE_NAME IS NOT NULL;

-- EDA
-- Dataset Overview
-- Total records overview
SELECT 
    'Customers' as table_name, COUNT(*) as record_count FROM customer
UNION ALL SELECT 'Invoices', COUNT(*) FROM invoice
UNION ALL SELECT 'Invoice Lines', COUNT(*) FROM invoice_line
UNION ALL SELECT 'Tracks', COUNT(*) FROM track
UNION ALL SELECT 'Albums', COUNT(*) FROM album
UNION ALL SELECT 'Artists', COUNT(*) FROM artist
UNION ALL SELECT 'Playlists', COUNT(*) FROM playlist;

-- REVENUE SUMMARY
-- Total revenue & average order value
SELECT 
    COUNT(*) as total_invoices,
    COUNT(DISTINCT customer_id) as active_customers,
    ROUND(SUM(total), 2) as total_revenue,
    ROUND(AVG(total), 2) as avg_order_value,
    ROUND(MAX(total), 2) as max_order_value
FROM invoice;

-- TOP 10 Customers (Lifetime Value)
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) as customer_name,
    c.country,
    COUNT(i.invoice_id) as total_orders,
    ROUND(SUM(i.total), 2) as total_spent,
    ROUND(AVG(i.total), 2) as avg_order
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.country
ORDER BY total_spent DESC
LIMIT 10;

-- Sales by Country 
SELECT 
    c.country,
    COUNT(DISTINCT c.customer_id) as customers,
    COUNT(i.invoice_id) as invoices,
    ROUND(SUM(i.total), 2) as total_sales,
    ROUND(AVG(i.total), 2) as avg_order
FROM customer c
LEFT JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.country
ORDER BY total_sales DESC;

-- Revenue Trends (Monthly - Line Chart)
SELECT 
    DATE_FORMAT(i.invoice_date, '%Y-%m') as sales_month,
    COUNT(i.invoice_id) as invoice_count,
    ROUND(SUM(i.total), 2) as monthly_revenue
FROM invoice i
GROUP BY DATE_FORMAT(i.invoice_date, '%Y-%m')
ORDER BY sales_month;

-- Top Selling Genres
SELECT 
    g.name as genre,
    COUNT(il.invoice_line_id) as units_sold,
    ROUND(SUM(il.unit_price * il.quantity), 2) as revenue
FROM invoice_line il
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
GROUP BY g.genre_id, g.name
ORDER BY revenue DESC
LIMIT 10;

-- Most Popular Artists
SELECT 
    art.name as artist,
    COUNT(DISTINCT a.album_id) as albums,
    COUNT(il.invoice_line_id) as tracks_sold,
    ROUND(SUM(il.unit_price * il.quantity), 2) as revenue
FROM artist art
JOIN album a ON art.artist_id = a.artist_id
JOIN track t ON a.album_id = t.album_id
JOIN invoice_line il ON t.track_id = il.track_id
GROUP BY art.artist_id, art.name
ORDER BY revenue DESC
LIMIT 10;

--  Bestselling Albums
SELECT 
    alb.title as album,
    art.name as artist,
    COUNT(il.invoice_line_id) as tracks_sold,
    ROUND(SUM(il.unit_price * il.quantity), 2) as revenue
FROM album alb
JOIN artist art ON alb.artist_id = art.artist_id
JOIN track t ON alb.album_id = t.album_id
JOIN invoice_line il ON t.track_id = il.track_id
GROUP BY alb.album_id, alb.title, art.name
ORDER BY revenue DESC
LIMIT 10;

-- Playlist Popularity
SELECT 
    p.name as playlist,
    COUNT(pt.track_id) as tracks,
    COUNT(DISTINCT pt.track_id) as unique_tracks
FROM playlist p
JOIN playlist_track pt ON p.playlist_id = pt.playlist_id
GROUP BY p.playlist_id, p.name
ORDER BY tracks DESC
LIMIT 10;

-- Customer Purchase Frequency
WITH customer_stats AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) as customer_name,
        COUNT(i.invoice_id) as total_orders,
        SUM(i.total) as total_spent
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name
)
SELECT 
    CASE 
        WHEN total_orders >= 20 THEN 'High Value (20+ orders)'
        WHEN total_orders >= 10 THEN 'Medium Value (10-19 orders)'
        ELSE 'Low Value (<10 orders)'
    END as customer_segment,
    COUNT(*) as customer_count,
    ROUND(AVG(total_spent), 2) as avg_lifetime_value,
    ROUND(SUM(total_spent), 2) as segment_total_revenue,
    ROUND(MIN(total_orders), 0) as min_orders,
    ROUND(MAX(total_orders), 0) as max_orders
FROM customer_stats
GROUP BY 
    CASE 
        WHEN total_orders >= 20 THEN 'High Value (20+ orders)'
        WHEN total_orders >= 10 THEN 'Medium Value (10-19 orders)'
        ELSE 'Low Value (<10 orders)'
    END
ORDER BY customer_count DESC;

-- Track Length vs Price Analysis
SELECT 
    ROUND(t.milliseconds / 60000, 2) as minutes,
    AVG(t.unit_price) as avg_price,
    COUNT(*) as track_count
FROM track t
GROUP BY ROUND(t.milliseconds / 60000, 2)
ORDER BY minutes;

-- Top Tracks (Most Purchased)
SELECT 
    t.name as track,
    art.name as artist,
    g.name as genre,
    COUNT(il.invoice_line_id) as units_sold,
    ROUND(SUM(il.unit_price * il.quantity), 2) as revenue
FROM track t
JOIN artist art ON t.album_id IN (SELECT album_id FROM album WHERE artist_id = art.artist_id)
JOIN genre g ON t.genre_id = g.genre_id
JOIN invoice_line il ON t.track_id = il.track_id
GROUP BY t.track_id, t.name, art.name, g.name
ORDER BY units_sold DESC
LIMIT 20;

-- Media Type Performance
SELECT 
    mt.name as media_type,
    COUNT(il.invoice_line_id) as units_sold,
    ROUND(SUM(il.unit_price * il.quantity), 2) as revenue,
    ROUND(AVG(il.unit_price), 2) as avg_price
FROM media_type mt
JOIN track t ON t.media_type_id = mt.media_type_id
JOIN invoice_line il ON t.track_id = il.track_id
GROUP BY mt.media_type_id, mt.name
ORDER BY revenue DESC;


-- ADVANCE ANALYSIS
-- Customer revenue with ranks
WITH customer_revenue AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.country,
        SUM(i.total) AS total_spent,
        COUNT(i.invoice_id) AS total_orders
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.country
)
SELECT
    customer_id,
    customer_name,
    country,
    total_orders,
    ROUND(total_spent, 2) AS total_spent,
    RANK()       OVER (ORDER BY total_spent DESC) AS revenue_rank,
    DENSE_RANK() OVER (ORDER BY total_spent DESC) AS revenue_dense_rank,
    NTILE(4)     OVER (ORDER BY total_spent DESC) AS revenue_quartile
FROM customer_revenue
ORDER BY total_spent DESC; 

-- Segment customers by behaviour
WITH customer_stats AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        SUM(i.total) AS total_spent,
        COUNT(i.invoice_id) AS total_orders,
        MIN(i.invoice_date) AS first_order_date,
        MAX(i.invoice_date) AS latest_order_date
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name
)
SELECT
    CASE 
        WHEN total_spent >= 100 THEN 'High Value'
        WHEN total_spent >= 50  THEN 'Medium Value'
        ELSE 'Low Value'
    END AS value_segment,
    CASE 
        WHEN total_orders >= 10 THEN 'Frequent'
        WHEN total_orders >= 5  THEN 'Regular'
        ELSE 'Occasional'
    END AS frequency_segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(total_spent), 2) AS avg_spent_per_customer
FROM customer_stats
GROUP BY 
    CASE WHEN total_spent >= 100 THEN 'High Value'
         WHEN total_spent >= 50  THEN 'Medium Value'
         ELSE 'Low Value' END,
    CASE WHEN total_orders >= 10 THEN 'Frequent'
         WHEN total_orders >= 5  THEN 'Regular'
         ELSE 'Occasional' END
ORDER BY value_segment, frequency_segment;


-- . Top tracks by popularity and sales
WITH track_sales AS (
    SELECT 
        t.track_id,
        t.name AS track_name,
        t.milliseconds,
        t.unit_price,
        a.title AS album,
        art.name AS artist,
        g.name AS genre,
        SUM(il.quantity) AS units_sold,
        SUM(il.quantity * il.unit_price) AS revenue
    FROM track t
    JOIN album a      ON t.album_id = a.album_id
    JOIN artist art   ON a.artist_id = art.artist_id
    JOIN genre g      ON t.genre_id = g.genre_id
    JOIN invoice_line il ON t.track_id = il.track_id
    GROUP BY t.track_id, t.name, t.milliseconds, t.unit_price, 
             a.title, art.name, g.name
)
SELECT
    track_id,
    track_name,
    artist,
    album,
    genre,
    units_sold,
    ROUND(revenue, 2) AS revenue,
    ROW_NUMBER() OVER (ORDER BY revenue DESC)              AS global_rownum,
    RANK()       OVER (ORDER BY revenue DESC)              AS global_rank,
    DENSE_RANK() OVER (ORDER BY revenue DESC)              AS global_dense_rank
FROM track_sales
ORDER BY revenue DESC
LIMIT 50;


-- Rank tracks within each genre
WITH track_sales AS (
    SELECT 
        t.track_id,
        t.name AS track_name,
        g.name AS genre,
        SUM(il.quantity) AS units_sold,
        SUM(il.quantity * il.unit_price) AS revenue
    FROM track t
    JOIN genre g      ON t.genre_id = g.genre_id
    JOIN invoice_line il ON t.track_id = il.track_id
    GROUP BY t.track_id, t.name, g.name
)
SELECT *
FROM (
    SELECT
        genre,
        track_name,
        units_sold,
        ROUND(revenue, 2) AS revenue,
        RANK() OVER (PARTITION BY genre ORDER BY revenue DESC) AS rank_in_genre
    FROM track_sales
) x
WHERE rank_in_genre <= 5;

