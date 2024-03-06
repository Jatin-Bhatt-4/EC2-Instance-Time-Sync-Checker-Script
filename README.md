# Instance Time Sync Checker Script

## Overview
This bash script checks the time synchronization of running Linux instances on AWS. It logs into each instance, retrieves its current time, and compares it with the current UTC time. If an instance's time is more than 15 seconds behind or ahead of the current time, it logs this information and sends an email notification.

## Dependencies
- AWS CLI
- `jq` command-line JSON processor
- `mailx` command-line tool for sending emails

## Setup
1. Ensure you have the AWS CLI configured with appropriate permissions to describe EC2 instances.
2. Install the `jq` and `mailx` packages if not already installed.
3. Ensure SSH key `devops` is available and has proper permissions.
4. Update the email configuration (`FROM`, `TO`, `SUBJECT`) as per your requirement.

## Usage
1. Run the script `./instance_time_sync_checker.sh`.
2. Check the output for instances that are out of sync with the current time.
3. If any instances are out of sync, an email will be sent with the details.

## Notes
- This script assumes that the instances are accessible via SSH using the `devops` key.
- Adjust the region and filters as needed for your environment.
- Ensure that the `mailx` configuration is properly set up to send emails.
- It's recommended to schedule this script to run periodically using cron or any other scheduler.

## Update Correct time on Instance
1. SSH into the instance & check for `/etc/ntp.conf` or `/etc/chrony.conf`
2. Remove the server pool lines from the above conf files.
3. Add the below lines in place of the removed server pool file-
   
   **server 169.254.169.123 prefer iburst minpoll 4 maxpoll 4**
   **pool time.aws.com iburst**
5. Restart ntpd/chrony service.

## Author
- Created by Jatin Bhatt
