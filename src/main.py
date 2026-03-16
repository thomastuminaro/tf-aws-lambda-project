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
    logging.info(f"Found secret : {DB_PASSWORD}")
    return DB_PASSWORD


def get_connection():
    global conn

    if conn and conn.open:
        return conn

    logging.info(f"Creating new DB connection to {PROXY_ENDPOINT} as {DB_USER} on DB {DB_NAME}.")

    try: 
        conn = pymysql.connect(
        host=PROXY_ENDPOINT,
        user=DB_USER,
        password=get_secret(),
        database=DB_NAME,
        port=3306,
        ssl={"check_hostname": False},  # required for caching_sha2_password
        connect_timeout=5,
        cursorclass=pymysql.cursors.DictCursor,
        autocommit=True
        )
    except Exception as e:
        logging.error(f"ERROR: Could not connect to DB {e}")
        raise e

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

    if check_customer_exists(first_name, last_name):
        logging.info(f"Customer {first_name} {last_name} already exists.")
        return

    query = """
    INSERT INTO customers (first_name, last_name, creator)
    VALUES (%s, %s, %s)
    """

    with conn.cursor() as cursor:
        cursor.execute(query, (first_name, last_name, creator))
        customer_id = cursor.lastrowid

    logging.info(f"Inserted customer ID {customer_id}")
    return customer_id


def list_customers(api_user):
    logging.info("Listing customers")

    conn = get_connection()

    if api_user == "admin":
        query = "SELECT * FROM customers"
    else:
        query = "SELECT * FROM customers where creator=%s"

    with conn.cursor() as cursor:
        cursor.execute(query, (api_user))
        results = cursor.fetchall()

    return results

def get_user(event):
    try:
        user_arn = event["requestContext"]["authorizer"]["iam"]["userArn"]
        username = user_arn.split("/")[-1]
        if "@" in username:
            username = username.split("@")[0]
        return username
    except Exception as e:
        logging.error(f"Could not extract username : {e}")
        raise e

def lambda_handler(event, context):
    path = event["requestContext"]["http"]["path"]
    caller_user = get_user(event)
    #create_customer("Thomas", "Tuminaro", caller_user)
    #api_customers = list_customers(caller_user)
    if path == "/list-users":
        return {
            "statusCode": 200,
            "body": json.dumps(list_customers(caller_user))
        }
    elif path == "/create-user":
        try :
            body = json.loads(event["body"])
            logging.info(f"Request to create user {body["first_name"]} {body["last_name"]}")
            create_customer(body["first_name"], body["last_name"], caller_user)
        except Exception as e:
            return {
                "statusCode": 400,
                "body": json.dumps(str(e))
            }
        else:
            return {
                "statusCode": 200,
                "body": json.dumps(f"Successfully created user {body["first_name"]} {body["last_name"]}")
            }

    return {
        "statusCode": 200,
        "body": json.dumps(event)
    }
