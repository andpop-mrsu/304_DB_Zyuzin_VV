PRAGMA foreign_keys = OFF;
BEGIN TRANSACTION;

DROP TABLE IF EXISTS completed_works;
DROP TABLE IF EXISTS appointment_services;
DROP TABLE IF EXISTS appointments;
DROP TABLE IF EXISTS services;
DROP TABLE IF EXISTS clients;
DROP TABLE IF EXISTS master_schedules;
DROP TABLE IF EXISTS masters;

-- Мастера (кадровый учет)
CREATE TABLE masters (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    middle_name TEXT,
    phone TEXT NOT NULL UNIQUE,
    specialization TEXT NOT NULL CHECK(specialization IN ('male', 'female', 'universal')),
    salary_percent REAL NOT NULL CHECK(salary_percent > 0 AND salary_percent <= 100),
    hire_date TEXT NOT NULL DEFAULT (date('now')),
    fire_date TEXT CHECK(fire_date IS NULL OR fire_date >= hire_date),
    is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1))
);

-- Индивидуальный график работы мастеров
CREATE TABLE master_schedules (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    master_id INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL CHECK(day_of_week BETWEEN 1 AND 7),
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL CHECK(end_time > start_time),
    UNIQUE(master_id, day_of_week),
    FOREIGN KEY (master_id) REFERENCES masters(id) ON DELETE CASCADE
);

-- Клиенты
CREATE TABLE clients (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    first_name TEXT NOT NULL,
    last_name TEXT,
    phone TEXT NOT NULL UNIQUE,
    gender TEXT NOT NULL CHECK(gender IN ('male', 'female'))
);

-- Справочник услуг
CREATE TABLE services (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    target_gender TEXT NOT NULL CHECK(target_gender IN ('male', 'female')),
    duration_minutes INTEGER NOT NULL CHECK(duration_minutes > 0),
    price REAL NOT NULL CHECK(price >= 0),
    UNIQUE(name, target_gender)
);

-- Предварительная запись
CREATE TABLE appointments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    client_id INTEGER NOT NULL,
    master_id INTEGER NOT NULL,
    start_datetime TEXT NOT NULL,
    end_datetime TEXT NOT NULL CHECK(end_datetime > start_datetime),
    status TEXT NOT NULL DEFAULT 'scheduled' CHECK(status IN ('scheduled', 'completed', 'cancelled', 'no_show')),
    notes TEXT,
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE RESTRICT,
    FOREIGN KEY (master_id) REFERENCES masters(id) ON DELETE RESTRICT
);

-- Услуги, выбранные в предварительной записи
CREATE TABLE appointment_services (
    appointment_id INTEGER NOT NULL,
    service_id INTEGER NOT NULL,
    PRIMARY KEY (appointment_id, service_id),
    FOREIGN KEY (appointment_id) REFERENCES appointments(id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE RESTRICT
);

-- Фактически выполненные работы
CREATE TABLE completed_works (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    appointment_id INTEGER,
    master_id INTEGER NOT NULL,
    client_id INTEGER,
    service_id INTEGER NOT NULL,
    work_datetime TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
    actual_price REAL NOT NULL CHECK(actual_price >= 0),
    applied_salary_percent REAL NOT NULL CHECK(applied_salary_percent > 0 AND applied_salary_percent <= 100),
    FOREIGN KEY (appointment_id) REFERENCES appointments(id) ON DELETE SET NULL,
    FOREIGN KEY (master_id) REFERENCES masters(id) ON DELETE RESTRICT,
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL,
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE RESTRICT
);

-- Индексы для ускорения выборок, расписания и отчетов
CREATE INDEX idx_masters_active ON masters(is_active);
CREATE INDEX idx_appointments_master_date ON appointments(master_id, start_datetime);
CREATE INDEX idx_completed_works_master_date ON completed_works(master_id, work_datetime);

-- Мастера
INSERT INTO masters (id, first_name, last_name, middle_name, phone, specialization, salary_percent, hire_date, fire_date, is_active) VALUES
    (1, 'Артем', 'Мисоло', 'Игоревич', '+79001112233', 'male', 45.0, '2024-01-15', NULL, 1),
    (2, 'Елена', 'Собчак', 'Сергеевна', '+79002223344', 'female', 50.0, '2024-03-10', NULL, 1),
    (3, 'Зюзин', 'Виталий', 'Витальевич', '+79003334455', 'universal', 40.0, '2024-06-01', NULL, 1),
    (4, 'Дмитрий', 'Игушкин', 'Олегович', '+79004445566', 'male', 35.0, '2023-09-01', '2025-10-20', 0);

-- График работы мастеров
INSERT INTO master_schedules (master_id, day_of_week, start_time, end_time) VALUES
    (1, 1, '09:00', '18:00'),
    (1, 2, '09:00', '18:00'),
    (1, 4, '10:00', '19:00'),
    (1, 5, '10:00', '19:00'),
    (2, 2, '10:00', '20:00'),
    (2, 3, '10:00', '20:00'),
    (2, 6, '09:00', '17:00'),
    (3, 1, '11:00', '20:00'),
    (3, 3, '11:00', '20:00'),
    (3, 5, '11:00', '20:00'),
    (3, 7, '10:00', '16:00');

-- Клиенты
INSERT INTO clients (id, first_name, last_name, phone, gender) VALUES
    (1, 'Максим', 'Башмаков', '+79110001122', 'male'),
    (2, 'Ким', 'Кардашьян', '+79110002233', 'female'),
    (3, 'Иван', 'Иванович', '+79110003344', 'male'),
    (4, 'Ольга', 'Бузова', '+79110004455', 'female');

-- Справочник услуг
INSERT INTO services (id, name, target_gender, duration_minutes, price) VALUES
    (1, 'Мужская модельная стрижка', 'male', 45, 1200.0),
    (2, 'Оформление бороды и усов', 'male', 30, 800.0),
    (3, 'Женская стрижка на средние волосы', 'female', 60, 1800.0),
    (4, 'Окрашивание волос в один тон', 'female', 120, 4500.0),
    (5, 'Вечерняя укладка', 'female', 50, 2000.0);

-- Предварительные записи
INSERT INTO appointments (id, client_id, master_id, start_datetime, end_datetime, status, notes) VALUES
    (1, 1, 1, '2026-11-20 10:00', '2026-11-20 11:15', 'completed', 'Стрижка + борода'),
    (2, 2, 2, '2026-11-21 12:00', '2026-11-21 15:00', 'completed', 'Стрижка и окрашивание'),
    (3, 3, 3, '2026-11-24 14:00', '2026-11-24 14:45', 'scheduled', 'Запись к универсалу'),
    (4, 4, 2, '2026-11-25 11:00', '2026-11-25 11:50', 'scheduled', 'Укладка');

-- Состав услуг в записях
INSERT INTO appointment_services (appointment_id, service_id) VALUES
    (1, 1),
    (1, 2),
    (2, 3),
    (2, 4),
    (3, 1),
    (4, 5);

-- Фактически выполненные работы
INSERT INTO completed_works (appointment_id, master_id, client_id, service_id, work_datetime, actual_price, applied_salary_percent) VALUES
    (1, 1, 1, 1, '2026-11-20 10:45', 1200.0, 45.0),
    (1, 1, 1, 2, '2026-11-20 11:15', 800.0, 45.0),
    (2, 2, 2, 3, '2026-11-21 13:00', 1800.0, 50.0),
    (2, 2, 2, 4, '2026-11-21 15:00', 4500.0, 50.0),
    (NULL, 3, 1, 1, '2026-11-22 16:30', 1200.0, 40.0),
    (NULL, 4, 3, 1, '2025-10-15 14:00', 1000.0, 35.0);

COMMIT;
PRAGMA foreign_keys = ON;