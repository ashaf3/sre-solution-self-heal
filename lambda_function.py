import boto3
import datetime
import logging

# Initialize boto3 clients
ecs_client = boto3.client('ecs')
dynamodb_client = boto3.resource('dynamodb')

CLUSTER_NAME = "demo-cluster"
TABLE_NAMES = ["card-events-dev", "cash-events-dev"]
KEY_NAME = "id"  # primary key name for the DynamoDB tables

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    try:
        # 1. Stop the ecs service
        logger.info("Stopping service1...")
        ecs_client.update_service(cluster=CLUSTER_NAME, service='svc1', desiredCount=0)
        logger.info("Service stopped successfully.")

        # 2. Fetching the current task definition ,more of copying the conf
        logger.info("Fetching the current task definition...")
        task_def = ecs_client.describe_task_definition(taskDefinition='demo-task-def')
        container_definitions = task_def['taskDefinition']['containerDefinitions']

        # 3. Add ROLLBACK_TO env var (temporarily we putting one hour before - in terms of lambda fn awake)
        rollback_time = (datetime.datetime.utcnow() - datetime.timedelta(hours=1)).strftime('%Y-%m-%dT%H:%M:%S-06:00')
        container_definitions[0]['environment'].append({'name': 'ROLLBACK_TO', 'value': rollback_time})
        logger.info(f"Added ROLLBACK_TO environment variable with value: {rollback_time}")

        # 4. Register the new task def
        logger.info("Registering new task definition...")
        new_task_def = ecs_client.register_task_definition(
            family='demo-task-def',
            containerDefinitions=container_definitions,
            requiresCompatibilities=['FARGATE'], 
            cpu='256',    
            memory='0.5GB', 
            networkMode='awsvpc'  
        )
        new_task_def_arn = new_task_def['taskDefinition']['taskDefinitionArn']
        logger.info(f"Registered new task definition: {new_task_def_arn}")

        # 5. Delete all items from DynamoDB tables
        logger.info("Deleting items from DynamoDB tables...")
        for table_name in TABLE_NAMES:
            table = dynamodb_client.Table(table_name)
            scan = table.scan()
            for item in scan['Items']:
                table.delete_item(Key={KEY_NAME: item[KEY_NAME]})
            logger.info(f"Items deleted from {table_name}.")

        # 6. Start the  ECS svc with the new task def
        logger.info("Restarting test-subscriber-service with new task definition...")
        ecs_client.update_service(cluster=CLUSTER_NAME, service='svc1', taskDefinition=new_task_def_arn, desiredCount=1)
        logger.info("Service restarted successfully.")

        return {
            'statusCode': 200,
            'body': f'Updated service with task definition: {new_task_def_arn}'
        }

    except Exception as e:
        logger.error(f"Error: {e}")
        return {
            'statusCode': 500,
            'body': f"Error: {e}"
        }
