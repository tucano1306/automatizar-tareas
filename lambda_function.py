import boto3

ec2 = boto3.resource('ec2')

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')

    # Describe instances
    response = ec2.describe_instances()
    print("EC2 Instances: ", response)

    # Start instances (example, you can replace with stop or other actions)
    # Replace 'instance_ids' with your actual EC2 instance IDs
    ec2.start_instances(InstanceIds=['i-0123456789abcdef0'])

    return {
        'statusCode': 200,
        'body': 'EC2 Instances started successfully'
    }
