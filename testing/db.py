import os
import pymysql
import pymysql.cursors
import boto3
import ssl
import json

db_user = "admin"
db_password = "adminadmin"
db_endpoint = "proxy-1772700903603-database-2.proxy-cqedc7azcz8o.eu-west-3.rds.amazonaws.com"
db_port = 3306
db_name = "db_customers"

def get_connection():
    return pymysql.connect(host=db_endpoint, user=db_user, password=db_password, database=db_name, charset="utf8mb4", cursorclass=pymysql.cursors.DictCursor)

def list_customers():
    connection = get_connection()
    with connection:
        with connection.cursor() as cursor:
            sql = "select * from customers"
            cursor.execute(sql)
            result = cursor.fetchall()
    return result

def lambda_handler(event, context):
    return{
        'statusCode': 200,
        'body': json.dumps(list_customers())
    }


