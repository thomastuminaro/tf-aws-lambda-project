import boto3
import os 
import pymysql
import ssl

def get_connection():

    context = ssl.create_default_context()

    return pymysql.connect(
        host=os.environ["proxy_endpoint"],
        #user=DB_USER,
        #password="adminadmin",
        user=os.environ["db_user"],
        password=">P_IMqRik4iP5F9rA5EqkRh)ZyPV",
        database=os.environ["db_name"],
        port=3306,
        ssl=context,
        cursorclass=pymysql.cursors.DictCursor
    )

def lambda_handler(event, context):
    return {
        'statusCode': 200,
        'body': f'Hello from Lambda ! - The DB name is {os.environ["db_name"]}'
    }