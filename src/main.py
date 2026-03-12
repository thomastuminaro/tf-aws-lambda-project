import os
import json
import logging
import boto3
import pymysql
import pymysql.cursors

logging.basicConfig(level=logging.INFO)

PROXY_ENDPOINT = os.environ["proxy_endpoint"]
DB_USER = os.environ["db_user"]
DB_NAME = os.environ["db_name"]
DB_SECRET = os.environ["db_secret"]

# Global caches (persist between Lambda invocations)
conn = None
DB_PASSWORD = None


def get_secret():
    global DB_PASSWORD

    if DB_PASSWORD:
        return DB_PASSWORD

    logging.info("Retrieving DB password from Secrets Manager")

    client = boto3.client("secretsmanager")
    response = client.get_secret_value(SecretId=DB_SECRET)

    DB_PASSWORD = json.loads(response["SecretString"])["password"]
    return DB_PASSWORD


def get_connection():
    global conn

    if conn and conn.open:
        return conn

    logging.info("Creating new DB connection")

    conn = pymysql.connect(
        host=PROXY_ENDPOINT,
        user=DB_USER,
        password=get_secret(),
        database=DB_NAME,
        port=3306,
        ssl={},  # required for caching_sha2_password
        connect_timeout=5,
        cursorclass=pymysql.cursors.DictCursor,
        autocommit=True
    )

    return conn


def create_table_if_not_exist():
    logging.info("Ensuring customers table exists")

    conn = get_connection()

    query = """
    CREATE TABLE IF NOT EXISTS customers(
        id INT AUTO_INCREMENT PRIMARY KEY,
        first_name VARCHAR(255),
        last_name VARCHAR(255),
        creator VARCHAR(255)
    );
    """

    with conn.cursor() as cursor:
        cursor.execute(query)


def check_customer_exists(first_name, last_name):
    logging.info(f"Checking if {first_name} {last_name} exists")

    conn = get_connection()

    query = """
    SELECT id
    FROM customers
    WHERE first_name=%s AND last_name=%s
    LIMIT 1
    """

    with conn.cursor() as cursor:
        cursor.execute(query, (first_name, last_name))
        result = cursor.fetchone()

    return result is not None


def create_customer(first_name, last_name, creator="admin"):
    logging.info(f"Inserting {first_name} {last_name}")

    conn = get_connection()

    query = """
    INSERT INTO customers (first_name, last_name, creator)
    VALUES (%s, %s, %s)
    """

    with conn.cursor() as cursor:
        cursor.execute(query, (first_name, last_name, creator))
        customer_id = cursor.lastrowid

    logging.info(f"Inserted customer ID {customer_id}")
    return customer_id


def list_customers():
    logging.info("Listing customers")

    conn = get_connection()

    query = "SELECT * FROM customers"

    with conn.cursor() as cursor:
        cursor.execute(query)
        results = cursor.fetchall()

    return results


def lambda_handler(event, context):

    create_table_if_not_exist()

    customers = [
        ("John", "Doe"),
        ("Jane", "Smith")
    ]

    for first, last in customers:
        if not check_customer_exists(first, last):
            create_customer(first, last)

    results = list_customers()

    return {
        "statusCode": 200,
        "body": json.dumps(results)
    }
