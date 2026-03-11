import os
import pymysql
import pymysql.cursors
import boto3
import ssl
import json
import logging

db_user = os.environ["db_user"]
db_secret = os.environ["db_secret"]
db_endpoint = os.environ["proxy_endpoint"]
db_port = 3306
db_name = os.environ["db_name"]

logging.basicConfig(level=logging.INFO)

class GetSecretWrapper:
    def __init__(self, secretsmanager_client):
        self.client = secretsmanager_client


    def get_secret(self, secret_name):
        """
        Retrieve individual secrets from AWS Secrets Manager using the get_secret_value API.
        This function assumes the stack mentioned in the source code README has been successfully deployed.
        This stack includes 7 secrets, all of which have names beginning with "mySecret".

        :param secret_name: The name of the secret fetched.
        :type secret_name: str
        """
        try:
            get_secret_value_response = self.client.get_secret_value(
                SecretId=secret_name
            )
            logging.info("Secret retrieved successfully.")
            return json.dumps(get_secret_value_response["SecretString"])["password"] #type: ignore
        except self.client.exceptions.ResourceNotFoundException:
            msg = f"The requested secret {secret_name} was not found."
            logging.info(msg)
            return msg
        except Exception as e:
            logging.error(f"An unknown error occurred: {str(e)}.")
            raise

def get_creds(secret_name):
    """
    Retrieve a secret from AWS Secrets Manager.

    :param secret_name: Name of the secret to retrieve.
    :type secret_name: str
    """
    try:
        # Validate secret_name
        if not secret_name:
            raise ValueError("Secret name must be provided.")
        # Retrieve the secret by name
        client = boto3.client("secretsmanager")
        wrapper = GetSecretWrapper(client)
        secret = wrapper.get_secret(secret_name)
        # Note: Secrets should not be logged.
        return secret
    except Exception as e:
        logging.error(f"Error retrieving secret: {e}")
        raise

def get_connection():
    return pymysql.connect(host=db_endpoint, user=db_user, password=get_creds(db_secret), database=db_name, charset="utf8mb4", cursorclass=pymysql.cursors.DictCursor)

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
