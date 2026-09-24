import os
import csv
import re

# конфигурация путей
DATA_DIR = 'dataset'
OUTPUT_FILE = 'db_init.sql'

# описание структуры таблиц
TABLES = {
    'movies': 'id INTEGER PRIMARY KEY, title TEXT, year INTEGER, genres TEXT',
    'ratings': 'id INTEGER PRIMARY KEY, user_id INTEGER, movie_id INTEGER, rating REAL, timestamp INTEGER',
    'tags': 'id INTEGER PRIMARY KEY, user_id INTEGER, movie_id INTEGER, tag TEXT, timestamp INTEGER',
    'users': 'id INTEGER PRIMARY KEY, name TEXT, email TEXT, gender TEXT, register_date TEXT, occupation TEXT'
}

def format_val(val):
    # форматирует значения пустые в NULL, строки экранирует
    val = str(val).strip()
    if not val:
        return "NULL"
    if val.isdigit():
        return val
    try:
        if val.lower() in ['infinity', 'inf', '-inf', 'nan']:
            raise ValueError
        
        float(val)
        return val
    except ValueError:
        # экранирование одинарных кавычек
        escaped_str = val.replace("'", "''")
        return f"'{escaped_str}'"

def get_transformer(table_name):
    # возвращает нужные колонки и функцию трансформации для конкретной таблицы
    if table_name == 'movies':
        def transform(row):
            if len(row) < 3: return None
            match = re.search(r'\((\d{4})\)\s*$', row[1])
            if match:
                year = match.group(1)
                title = row[1][:match.start()].strip()
            else:
                year = ""
                title = row[1]
            return [row[0], title, year, row[2]]
        return "id, title, year, genres", transform
        
    elif table_name == 'ratings':
        def transform(row):
            return row[:4] if len(row) >= 4 else None
        return "user_id, movie_id, rating, timestamp", transform
        
    elif table_name == 'tags':
        def transform(row):
            return row[:4] if len(row) >= 4 else None
        return "user_id, movie_id, tag, timestamp", transform
        
    elif table_name == 'users':
        def transform(row):
            return row[:6] if len(row) >= 6 else None
        return "id, name, email, gender, register_date, occupation", transform

def generate_sql():    
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as sql_file:
        sql_file.write("PRAGMA synchronous = OFF;\n")
        sql_file.write("PRAGMA journal_mode = MEMORY;\n")
        sql_file.write("BEGIN TRANSACTION;\n\n")

        for table_name, schema in TABLES.items():
            sql_file.write(f"DROP TABLE IF EXISTS {table_name};\n")
            sql_file.write(f"CREATE TABLE {table_name} ({schema});\n\n")
            
            filepath = os.path.join(DATA_DIR, f"{table_name}.csv")
            if not os.path.exists(filepath):
                filepath = os.path.join(DATA_DIR, f"{table_name}.txt")
            
            with open(filepath, 'r', encoding='utf-8') as f:
                first_line = f.readline()
                if '|' in first_line:
                    delimiter = '|'
                elif ';' in first_line:
                    delimiter = ';'
                else:
                    delimiter = ','
                f.seek(0)
                
                reader = csv.reader(f, delimiter=delimiter)
                first_row = next(reader, None)
                if not first_row:
                    continue
                
                # получаем правила трансформации для текущей таблицы
                col_names, transform_func = get_transformer(table_name)
                base_insert = f"INSERT INTO {table_name} ({col_names}) VALUES "
                batch = []
                
                # если первая строка данные (начинается с числа), обрабатываем её
                if first_row[0].strip().lstrip('\ufeff').isdigit():
                    t_row = transform_func(first_row)
                    if t_row:
                        batch.append(f"({', '.join(format_val(v) for v in t_row)})")
                
                # обработка остальных строк
                for row in reader:
                    t_row = transform_func(row)
                    if t_row:
                        batch.append(f"({', '.join(format_val(v) for v in t_row)})")
                    
                    if len(batch) >= 1000:
                        sql_file.write(base_insert + ", ".join(batch) + ";\n")
                        batch.clear()
                        
                if batch:
                    sql_file.write(base_insert + ", ".join(batch) + ";\n")
            
            sql_file.write("\n")
        
        sql_file.write("COMMIT;\n")

if __name__ == '__main__':
    generate_sql()