#*********************************************************************************************************************
#Author - Nirmallya Mukherjee
#This script will operate on AWS DynamoDB to showcase various APIs
#IMP-> when designing the column names ensure the name does not belong to the reserved words else you will get a client Error
#   https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ReservedWords.html
#*********************************************************************************************************************

import boto3
from botocore.exceptions import ClientError
from boto3.dynamodb.conditions import Key, Attr

# Get the service resource on the cloud
dynamodb = boto3.resource('dynamodb', region_name='us-west-2')

# Get the service resource running on localhost; ensure you have the CLI done with the credentials file in .aws folder
# The nature of the credentials for localhost does not matter; type in any junk for accesskey and secret
# dynamodb = boto3.resource('dynamodb', region_name='us-west-2', endpoint_url='http://localhost:8000')


def create_table():
    print ('\n*************************************************************************')
    print ('Creating table inventory')
    try:
        table = dynamodb.create_table(
            # This is the table that we want to create
            TableName='inventory',
            # category is the PK ie hash and sku is the sort key
            # these two together will uniquely identify a record/row
            KeySchema=[
                { 'AttributeName': 'category', 'KeyType': 'HASH' },
                { 'AttributeName': 'sku', 'KeyType': 'RANGE' }
            ],
            # Specifying the data types for the PK and Sort keys respectively
            # https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBMapper.DataTypes.html
            AttributeDefinitions=[
                { 'AttributeName': 'category', 'AttributeType': 'S' },
                { 'AttributeName': 'sku', 'AttributeType': 'S' }
            ],
            # Planning for capacity units
            ProvisionedThroughput={ 'ReadCapacityUnits': 1, 'WriteCapacityUnits': 1 }
        )
        # Wait until the table exists.
        table.meta.client.get_waiter('table_exists').wait(TableName='inventory')
        print (' DONE')

    except ClientError as e:
        print (' Skipped due to exception ', e.response['Error']['Code'])
        print (' Reason ', e.response['Error']['Message'])



def insert_data(category, sku, description, price, items):
    print ('\n*************************************************************************')
    print ('Inserting data in the table')
    # Instantiate a table resource object without actually creating a DynamoDB table.
    # Note that the attributes of this table are lazy-loaded: a request is not made nor are the attribute
    # values populated until the attributes on the table resource are accessed or its load() method is called.
    table = dynamodb.Table('inventory')
    table.put_item(
       Item={
            # The PK and the sort keys are mandatory
            'category': category,
            'sku': sku,
            # Due to the schemaless nature the following keys are not required in the table definition
            'description': description,
            'price': price,
            'items': items
        }
    )
    # Print out some data about the table.
    print ('Total items in the table are ', table.item_count)



def fetch_all():
    print ('\n*************************************************************************')
    print ('Getting all data from the table (not suited for production envs)')
    table = dynamodb.Table('inventory')
    response = table.scan()
    print ('Total items in the table are ', response['Count'])
    for item in response['Items']:
        print (item)



def fetch_pk(category):
    print ('\n*************************************************************************')
    print ('Getting data from the table based on the PK')
    table = dynamodb.Table('inventory')
    #Different query conditions and select criteria are possible, an example is below
    #ProjectionExpression="#yr, title, info.genres, info.actors[0]",
    #ExpressionAttributeNames={ "#yr": "year" }, # Expression Attribute Names for Projection Expression only.
    #KeyConditionExpression=Key('year').eq(1992) & Key('title').between('A', 'L')
    response = table.query(
        KeyConditionExpression=Key('category').eq(category)
    )
    print (' Total items for this PK is ', response['Count'])
    for item in response['Items']:
        print (item)



def fetch_data(category, sku):
    print ('\n*************************************************************************')
    print ('Getting an individual record from the table based on the PK+Sort key')
    table = dynamodb.Table('inventory')
    response = table.get_item(
        Key={
            'category': category,
            'sku': sku
        }
    )
    try:
        item = response['Item']
        print(item)
    except Exception as e:
        print (' Either no data was returned or there was a problem')
        print (response)



def update_data(category, sku, price):
    print ('\n*************************************************************************')
    print ('Updating data in the table')
    table = dynamodb.Table('inventory')
    table.update_item(
        Key={
            'category': category,
            'sku': sku
        },
        UpdateExpression='SET price = :val1',
        ExpressionAttributeValues={
            ':val1': price
        }
    )
    print (' Done')



def delete_data(category, sku):
    print ('\n*************************************************************************')
    print ('Deleting data in the table')
    table = dynamodb.Table('inventory')
    table.delete_item(
        Key={
            'category': category,
            'sku': sku
        }
    )
    print ('Items left in the table are ', table.item_count)



def main():
    #Create the table
    create_table()
    #Insert some sample data
    insert_data('tv', 'sku00001', 'SONY 52 inch TV', 250000, 100)
    insert_data('tv', 'sku00002', 'Samsung 52 inch TV', 175000, 150)
    #Full table scan and fetch all the data
    fetch_all()
    #Get a single record that does not exist
    fetch_data('tv', 'sku00003')
    #Update a single record
    update_data('tv', 'sku00002', 190000)
    #Fetch a single record that exists and updated recently (careful about eventual consistency)
    fetch_data('tv', 'sku00002')
    #Delete a record that exists
    delete_data('tv', 'sku00001')
    #Table scan and fetch all the data
    fetch_all()

    #Insert some more data for a different partition
    insert_data('laptops', 'sku00010', 'Dell vostro 3000', 45000, 500)
    insert_data('laptops', 'sku00011', 'Dell lattitude 5000', 40000, 400)
    insert_data('laptops', 'sku00012', 'HP pavilion 4500', 42000, 600)
    #Fetch based on only the partition key
    fetch_pk('laptops')

    #Fetch the complete data set
    fetch_all()

main()
