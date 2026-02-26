import json
import pymysql
import sys
import boto3
import os

ENDPOINT="proxy-1772017341034-database-1.proxy-cqedc7azcz8o.eu-west-3.rds.amazonaws.com"
PORT="3306"
USER="admin"
REGION="eu-west-3"
DBNAME="customer_db"
os.environ['LIBMYSQL_ENABLE_CLEARTEXT_PLUGIN'] = '1'

def get_user_name(event):
    userArn = event.get("requestContext").get("identity").get("userArn") 
    return userArn.split("/")[1]

def add_user():
    pass

def remove_user():
    pass

def get_users():
    pass

def get_user():
    pass

def delete_all():
    pass

def lambda_handler(event, context):
    # TODO implement

    session = boto3.Session()
    client = session.client('rds')

    token = client.generate_db_auth_token(DBHostname=ENDPOINT, Port=PORT, DBUsername=USER, Region=REGION)


    try:
        conn =  pymysql.connect(host=ENDPOINT, user=USER, password=token, port=int(PORT), database=DBNAME)
        cur = conn.cursor()
        cur.execute("""SELECT now()""")
        query_results = cur.fetchall()
        return {
            'statusCode': 200,
            'body': json.dumps(query_results)
        }
        #print(query_results)
    except Exception as e:
        #print("Database connection failed due to {}".format(e))
        raise ValueError(f"Database connection failed due to {e}")

    """ if get_user_name(event):
        msg = f"User {get_user_name(event)} will do some operations."

        return {
            'statusCode': 200,
            'body': json.dumps(msg)
        }
    else:
        raise ValueError("Cannot get username from the request.") """


