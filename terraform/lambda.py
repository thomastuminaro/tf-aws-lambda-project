import json

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
    if get_user_name(event):
        msg = f"User {get_user_name(event)} will do some operations."

        return {
            'statusCode': 200,
            'body': json.dumps(msg)
        }
    else:
        raise ValueError("Cannot get username from the request.")
