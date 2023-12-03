# *********************************************************************************************************************
# Author - Nirmallya Mukherjee
# This script will operate on AWS DynamoDB to showcase alternate fetch criteria using index
# *********************************************************************************************************************

import boto3
from botocore.exceptions import ClientError
from boto3.dynamodb.conditions import Key, Attr


dynamodb = boto3.resource(
    "dynamodb", region_name="us-east-1", endpoint_url="http://localhost:8000"
)
# dynamodb = boto3.resource("dynamodb", region_name="us-east-1")


def create_table():
    print("\n*************************************************************************")
    print("Creating table orders")
    try:
        table = dynamodb.create_table(
            TableName="orders",
            KeySchema=[
                {"AttributeName": "user_id", "KeyType": "HASH"},
                {"AttributeName": "order_id", "KeyType": "RANGE"},
            ],
            AttributeDefinitions=[
                {"AttributeName": "user_id", "AttributeType": "S"},
                {"AttributeName": "order_id", "AttributeType": "S"},
            ],
            ProvisionedThroughput={"ReadCapacityUnits": 1, "WriteCapacityUnits": 1},
        )
        table.meta.client.get_waiter("table_exists").wait(TableName="orders")
        print(" DONE")

    except ClientError as e:
        print(" Skipped due to exception ", e.response["Error"]["Code"])
        print(" Reason ", e.response["Error"]["Message"])


# Overloaded method with tax being the optional param
def insert_data(user_id, order_id, address, city, order_details, price, tax=None):
    print("\n*************************************************************************")
    print("Inserting data in the table")
    # A map which contains all the KV that represents the data to be inserted
    order_data = {
        "user_id": user_id,
        "order_id": order_id,
        "address": address,
        "city": city,
        "order_details": order_details,
        "price": price,
    }
    if tax:
        order_data["tax"] = tax

    table = dynamodb.Table("orders")
    try:
        ret_val = table.put_item(
            Item=order_data,
            # Let us force a read before write - exercise caution wrt performance
            ConditionExpression="attribute_not_exists(user_id) AND attribute_not_exists(order_id)",
            ReturnConsumedCapacity="TOTAL",
            ReturnValues="ALL_OLD",
        )
        print(ret_val)
    except ClientError as e:
        print(" Skipped due to exception ", e.response["Error"]["Code"])
        print(" Reason ", e.response["Error"]["Message"])

    print("Total items in the table are ", table.item_count)


def fetch_all():
    print("\n*************************************************************************")
    print("Getting all data from the table (not suited for production envs)")
    table = dynamodb.Table("orders")
    response = table.scan()
    print("Total items in the table are ", response["Count"])
    for item in response["Items"]:
        print(item)


def main():
    create_table()
    insert_data(
        "scotty",
        "R0000001",
        "#1 Engineering drive",
        "FortBaker",
        "Matter antimatter fusion controller",
        2000,
        200,
    )
    insert_data(
        "scotty",
        "R0000002",
        "#1 Engineering drive",
        "FortBaker",
        "External inertial damper",
        3100,
        180,
    )
    insert_data(
        "kirk", "R0000003", "#4 Captain drive", "FortBaker", "Type X phaser", 500, 35
    )
    insert_data(
        "nirmallya",
        "R0000004",
        "#402 Harlur road",
        "Bangalore",
        "2MW Fusion reactor",
        1200,
        85,
    )
    insert_data(
        "spock",
        "R0000005",
        "#1221 Forest Glenn ave",
        "HighlandPark",
        "Transporter base dial",
        850,
    )

    fetch_all()


main()
