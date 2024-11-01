import boto3

def main():
    # Configure the boto3 EC2 client
    ec2_client = boto3.client('ec2')

    # Explain the purpose of the application
    print("""
--------------------------------------------------------------------------------------------------------------------------------------
This application allows you to create an EBS snapshot by providing the Volume ID and specifying how many snapshots you wish to retain.
--------------------------------------------------------------------------------------------------------------------------------------
""")

    # Prompt for EBS volume ID and validate its existence
    while True:
        EBS_ID = input("Enter EBS Volume ID: ")
        try:
            response = ec2_client.describe_volumes(VolumeIds=[EBS_ID])
            if response['Volumes']:
                break  
        except Exception:
            print("Error: EBS volume ID not found. Please try again.")

    # Prompt for a name for the snapshot
    SNAPSHOT_NAME = input("Enter New Snapshot Name: ")

    # Prompt for the desired number of snapshots to keep
    while True:
        ARCHIVE_SIZE = input("Enter the number of snapshots to keep (must be a positive integer): ")
        if ARCHIVE_SIZE.isdigit() and int(ARCHIVE_SIZE) > 0:
            break
        print("Invalid input. Please enter a positive integer greater than zero.")

    # Create a snapshot of the specified EBS volume
    create_snapshot(ec2_client, EBS_ID, SNAPSHOT_NAME)
    # Clean up old snapshots if necessary
    clean_archive(ec2_client, EBS_ID, ARCHIVE_SIZE)

# Function to create a snapshot
def create_snapshot(ec2_client, EBS_ID, SNAPSHOT_NAME):
    try:
        snapshot = ec2_client.create_snapshot(
            VolumeId=EBS_ID,
            TagSpecifications=[{
                'ResourceType': 'snapshot',
                'Tags': [{'Key': 'Name', 'Value': SNAPSHOT_NAME}]
            }]
        )
        print(f"Snapshot created successfully: {snapshot['SnapshotId']}")
    except Exception as e:
        print(f"Error creating snapshot: {e}")

# Function to clean up old snapshots
def clean_archive(ec2_client, EBS_ID, ARCHIVE_SIZE):
    try:
        # Retrieve snapshots for the specified EBS volume
        snapshots = ec2_client.describe_snapshots(Filters=[{'Name': 'volume-id', 'Values': [EBS_ID]}])['Snapshots']
        
        # Sort snapshots by creation time (oldest first)
        snapshots.sort(key=lambda x: x['StartTime'])

        # Check if the number of snapshots exceeds the desired archive size
        if len(snapshots) > int(ARCHIVE_SIZE):
            # Identify snapshots to delete to maintain the archive size
            snapshots_to_delete = snapshots[:-int(ARCHIVE_SIZE)]
            
            # Delete the old snapshots
            for snapshot in snapshots_to_delete:
                ec2_client.delete_snapshot(SnapshotId=snapshot['SnapshotId'])
    
    except Exception as e:
        print(f"Error cleaning snapshots: {e}")

if __name__ == "__main__":
    main()
