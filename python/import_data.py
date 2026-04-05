import pandas as pd
import mysql.connector
import os

# ================================================
# EDIT THESE 3 THINGS ONLY:
password = "root"   # your MySQL root password
data_folder = r"D:\retail-analytics\data"  # your data folder path
# ================================================

# Connect to MySQL
conn = mysql.connector.connect(
    host="localhost",
    user="root",
    password=password,
    database="retail_analytics"
)
cursor = conn.cursor()
print("✅ Connected to MySQL!")

# Get all CSV files in your data folder
csv_files = [f for f in os.listdir(data_folder) if f.endswith('.csv')]
print(f"\n📁 Found {len(csv_files)} CSV files:")
for f in csv_files:
    print(f"   - {f}")

# Import each CSV file
for filename in csv_files:
    table_name = filename.replace('.csv', '')  # use filename as table name
    filepath = os.path.join(data_folder, filename)
    
    print(f"\n⏳ Importing {filename}...")
    
    # Read CSV
    df = pd.read_csv(filepath, low_memory=False)
    
    # Clean column names (remove spaces, special chars)
    df.columns = df.columns.str.strip().str.replace(' ', '_').str.lower()
    
    # Drop table if exists and recreate
    cursor.execute(f"DROP TABLE IF EXISTS `{table_name}`")
    
    # Build CREATE TABLE statement automatically
    col_definitions = []
    for col in df.columns:
        col_definitions.append(f"`{col}` TEXT")
    create_sql = f"CREATE TABLE `{table_name}` ({', '.join(col_definitions)})"
    cursor.execute(create_sql)
    
    # Insert data in batches of 1000 rows (fast!)
    batch_size = 1000
    total_rows = len(df)
    
    for i in range(0, total_rows, batch_size):
        batch = df.iloc[i:i+batch_size]
        placeholders = ', '.join(['%s'] * len(df.columns))
        insert_sql = f"INSERT INTO `{table_name}` VALUES ({placeholders})"
        
        # Replace NaN with None for MySQL
        rows = [tuple(None if pd.isna(v) else v for v in row) 
                for row in batch.values]
        cursor.executemany(insert_sql, rows)
        conn.commit()
        
        print(f"   Inserted {min(i+batch_size, total_rows)}/{total_rows} rows...", end='\r')
    
    print(f"✅ {table_name} done! ({total_rows} rows)")

print("\n🎉 ALL FILES IMPORTED SUCCESSFULLY!")
print("\nTables created:")
cursor.execute("SHOW TABLES")
for table in cursor.fetchall():
    print(f"   ✅ {table[0]}")

cursor.close()
conn.close()