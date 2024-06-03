import boto3

def create_table(table_name):
    # Initialize DynamoDB resource
    dynamodb = boto3.resource('dynamodb')

    try:
        # Create the table
        table = dynamodb.create_table(
            TableName=table_name,
            KeySchema=[
                {
                    'AttributeName': 'LockID',
                    'KeyType': 'HASH'  # Partition key
                }
            ],
            AttributeDefinitions=[
                {
                    'AttributeName': 'LockID',
                    'AttributeType': 'S'  # String data type for LockID
                }
            ],
            ProvisionedThroughput={
                'ReadCapacityUnits': 5,
                'WriteCapacityUnits': 5
            }
        )

        # Wait until the table is created
        table.meta.client.get_waiter('table_exists').wait(TableName=table_name)

        print("Table created successfully:", table_name)
        return table

    except dynamodb.meta.client.exceptions.ResourceInUseException:
        print("Table already exists:", table_name)
        return dynamodb.Table(table_name)
    except Exception as e:
        print("An unexpected error occurred:", e)
        return None

def send_data(table, lock_id, other_attribute):
    try:
        # Define the item to be put into the table
        item = {
            'LockID': lock_id,
            'OtherAttribute': other_attribute
        }

        # Put the item into the table
        response = table.put_item(Item=item)
        print("Item added successfully:", response)

    except table.meta.client.exceptions.ClientError as e:
        error_code = e.response['Error']['Code']
        error_message = e.response['Error']['Message']
        print(f"An error occurred ({error_code}): {error_message}")
    except Exception as e:
        print("An unexpected error occurred:", e)

def main():
    # Define the table name
    table_name = 'new_table'
    
    # Create or get the DynamoDB table
    table = create_table(table_name)

    if table:
        # Send data to the table
        lock_id = 'example_lock_id'
        other_attribute = 'example_value'
        send_data(table, lock_id, other_attribute)

if __name__ == "__main__":
    main()

















