PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;

INSERT OR IGNORE INTO occupations (name) VALUES ('student');

INSERT INTO users (first_name, last_name, email, gender, occupation_id)
VALUES 
    ('Vitaliy', 'Zyuzin', 'vitaliy.zyuzin@gmail.com', 'male', (SELECT id FROM occupations WHERE name = 'student')),
    ('Evgeniy', 'Igushkin', 'evgeniy.igushkin@gmail.com', 'male', (SELECT id FROM occupations WHERE name = 'student')),
    ('Kirill', 'Efimkin', 'kirill.efimkin@gmail.com', 'male', (SELECT id FROM occupations WHERE name = 'student')),
    ('Maxim', 'Denisov', 'maxim.denisov@gmail.com', 'female', (SELECT id FROM occupations WHERE name = 'student')),
    ('Alexey', 'Voronin', 'alexey.voronin@gmail.com', 'male', (SELECT id FROM occupations WHERE name = 'student'));

INSERT OR IGNORE INTO genres (name) VALUES ('Sci-Fi'), ('Comedy'), ('Drama');

INSERT INTO movies (title, year) VALUES 
    ('Dune: Part Two', 2024),
    ('Deadpool & Wolverine', 2024),
    ('Oppenheimer', 2023);

INSERT OR IGNORE INTO movie_genres (movie_id, genre_id)
VALUES 
    (
        (SELECT id FROM movies WHERE title = 'Dune: Part Two' AND year = 2024 LIMIT 1),
        (SELECT id FROM genres WHERE name = 'Sci-Fi')
    ),
    (
        (SELECT id FROM movies WHERE title = 'Deadpool & Wolverine' AND year = 2024 LIMIT 1),
        (SELECT id FROM genres WHERE name = 'Comedy')
    ),
    (
        (SELECT id FROM movies WHERE title = 'Oppenheimer' AND year = 2023 LIMIT 1),
        (SELECT id FROM genres WHERE name = 'Drama')
    );

INSERT INTO ratings (user_id, movie_id, rating)
VALUES 
    (
        (SELECT id FROM users WHERE email = 'vitaliy.zyuzin@gmail.com'),
        (SELECT id FROM movies WHERE title = 'Dune: Part Two' AND year = 2024 LIMIT 1),
        5.0
    ),
    (
        (SELECT id FROM users WHERE email = 'vitaliy.zyuzin@gmail.com'),
        (SELECT id FROM movies WHERE title = 'Deadpool & Wolverine' AND year = 2024 LIMIT 1),
        4.5
    ),
    (
        (SELECT id FROM users WHERE email = 'vitaliy.zyuzin@gmail.com'),
        (SELECT id FROM movies WHERE title = 'Oppenheimer' AND year = 2023 LIMIT 1),
        4.8
    );

COMMIT;