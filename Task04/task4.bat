#!/bin/bash
chcp 65001 > /dev/null 2>&1

sqlite3 movies_rating.db < db_init.sql

echo "1. Найти все пары пользователей, оценивших один и тот же фильм. Устранить дубликаты, проверить отсутствие пар с самим собой. Для каждой пары должны быть указаны имена пользователей и название фильма, который они ценили. В списке оставить первые 100 записей."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT DISTINCT u1.name AS user1, u2.name AS user2, m.title AS movie_title FROM ratings r1 INNER JOIN ratings r2 ON r1.movie_id = r2.movie_id AND r1.user_id < r2.user_id INNER JOIN users u1 ON r1.user_id = u1.id INNER JOIN users u2 ON r2.user_id = u2.id INNER JOIN movies m ON r1.movie_id = m.id LIMIT 100;"
echo " "

echo "2. Найти 10 самых свежих оценок от разных пользователей, вывести названия фильмов, имена пользователей, оценку, дату отзыва в формате ГГГГ-ММ-ДД."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH latest_user_ratings AS (SELECT user_id, movie_id, rating, timestamp, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY timestamp DESC, id DESC) AS rn FROM ratings) SELECT m.title AS movie_title, u.name AS user_name, r.rating, date(r.timestamp, 'unixepoch') AS review_date FROM latest_user_ratings r INNER JOIN movies m ON r.movie_id = m.id INNER JOIN users u ON r.user_id = u.id WHERE r.rn = 1 ORDER BY r.timestamp DESC LIMIT 10;"
echo " "

echo "3. Вывести в одном списке все фильмы с максимальным средним рейтингом и все фильмы с минимальным средним рейтингом. Общий список отсортировать по году выпуска и названию фильма. В зависимости от рейтинга в колонке 'Рекомендуем' для фильмов должно быть написано 'Да' или 'Нет'."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH movie_avg AS (SELECT m.id, m.title, m.year, AVG(r.rating) AS avg_rating FROM movies m INNER JOIN ratings r ON m.id = r.movie_id GROUP BY m.id, m.title, m.year), bounds AS (SELECT MAX(avg_rating) AS max_r, MIN(avg_rating) AS min_r FROM movie_avg) SELECT ma.title, ma.year, ROUND(ma.avg_rating, 2) AS avg_rating, CASE WHEN ma.avg_rating = b.max_r THEN 'Да' ELSE 'Нет' END AS 'Рекомендуем' FROM movie_avg ma CROSS JOIN bounds b WHERE ma.avg_rating = b.max_r OR ma.avg_rating = b.min_r ORDER BY ma.year, ma.title;"
echo " "

echo "4. Вычислить количество оценок и среднюю оценку, которую дали фильмам пользователи-женщины в период с 2010 по 2012 год."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT COUNT(r.id) AS ratings_count, ROUND(AVG(r.rating), 2) AS avg_rating FROM ratings r INNER JOIN users u ON r.user_id = u.id WHERE u.gender = 'female' AND strftime('%Y', datetime(r.timestamp, 'unixepoch')) BETWEEN '2010' AND '2012';"
echo " "

echo "5. Составить список фильмов с указанием их средней оценки и места в рейтинге по средней оценке. Полученный список отсортировать по году выпуска и названиям фильмов. В списке оставить первые 20 записей."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH ranked_movies AS (SELECT m.title, m.year, ROUND(AVG(r.rating), 2) AS avg_rating, DENSE_RANK() OVER (ORDER BY AVG(r.rating) DESC) AS rating_rank FROM movies m INNER JOIN ratings r ON m.id = r.movie_id GROUP BY m.id, m.title, m.year) SELECT title, year, avg_rating, rating_rank FROM ranked_movies ORDER BY year, title LIMIT 20;"
echo " "

echo "6. Вывести список из 10 последних зарегистрированных пользователей в формате 'Фамилия Имя|Дата регистрации' (сначала фамилия, потом имя)."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT SUBSTR(name, INSTR(name, ' ') + 1) || ' ' || SUBSTR(name, 1, INSTR(name, ' ') - 1) || '|' || register_date AS user_info FROM users ORDER BY register_date DESC LIMIT 10;"
echo " "

echo "7. С помощью рекурсивного CTE составить таблицу умножения для чисел от 1 до 10. Должен получиться один столбец следующего вида: 1x1=1 ... 10x10=100"
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE nums(n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM nums WHERE n < 10) SELECT a.n || 'x' || b.n || '=' || (a.n * b.n) AS multiplication_table FROM nums a CROSS JOIN nums b ORDER BY a.n, b.n;"
echo " "

echo "8. С помощью рекурсивного CTE выделить все жанры фильмов, имеющиеся в таблице movies (каждый жанр в отдельной строке)."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split_genres(genre, rest) AS (SELECT CASE WHEN INSTR(genres, '|') > 0 THEN SUBSTR(genres, 1, INSTR(genres, '|') - 1) ELSE genres END, CASE WHEN INSTR(genres, '|') > 0 THEN SUBSTR(genres, INSTR(genres, '|') + 1) ELSE '' END FROM movies WHERE genres IS NOT NULL AND genres != '' AND genres != '(no genres listed)' UNION ALL SELECT CASE WHEN INSTR(rest, '|') > 0 THEN SUBSTR(rest, 1, INSTR(rest, '|') - 1) ELSE rest END, CASE WHEN INSTR(rest, '|') > 0 THEN SUBSTR(rest, INSTR(rest, '|') + 1) ELSE '' END FROM split_genres WHERE rest != '') SELECT DISTINCT genre FROM split_genres WHERE genre != '' ORDER BY genre;"
echo " "
