import logging
import pymysql
import boto3
import ssl
import json
from botocore.exceptions import ClientError


PROXY_ENDPOINT = "proxy-1772033829361-database-1.proxy-cqedc7azcz8o.eu-west-3.rds.amazonaws.com"
DB_USER = "admin"
DB_NAME = "db_customers"

def get_secret():

    logging.error("I am in get secret")
    secret_name = "testsecret"
    region_name = "eu-west-3"

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    logging.error("I created the session")
    try:
        logging.error("I am getting the secret")
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
        #get_secrets_list = client.list_secrets()
        logging.error("I got the secret")
    except ClientError as e:
        # For a list of exceptions thrown, see
        # https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
        logging.error(e)
        raise e
    except Exception as e:
        logging.error(e)
        raise e
    except:
        logging.error("I failed")

    return get_secret_value_response['SecretString']
    #return get_secrets_list

def get_connection():

    username, password = get_secret()
    context = ssl.create_default_context()

    return pymysql.connect(
        host=PROXY_ENDPOINT,
        #user=DB_USER,
        #password="adminadmin",
        user=username,
        password=password,
        database=DB_NAME,
        port=3306,
        ssl=context,
        cursorclass=pymysql.cursors.DictCursor
    )

def list_customers():
    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT * FROM customers;")
            results = cursor.fetchall()
            return {
                'statusCode': 200,
                'body': json.dumps(results)
            }
            #for row in results:
            #    print(row)
    finally:
        conn.close()

def lambda_handler(event, context):
    #return list_customers()
    return {
        'status': 200,
        'body': json.dumps(get_secret())
    }
    #return get_db_credentials()



