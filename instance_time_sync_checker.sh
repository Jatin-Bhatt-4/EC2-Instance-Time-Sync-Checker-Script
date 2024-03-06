#!/bin/bash

> Final-UTC.txt

# Getting list of instances & IP of running instances
aws ec2 describe-instances --region us-west-1 --filters "Name=instance-state-name,Values=running" | jq -r '.Reservations[].Instances[] | "\(.Tags[] | select(.Key == "Name").Value):\(.PrivateIpAddress)"' > linux-servers.txt

echo "List of running servers written to linux-servers.txt"

# Removing windows servers IP
grep "^prod-" linux-servers.txt | awk -F: '{print $1 ":" $2}' | grep -v -e "windows" > running_inst.txt

# Loop over each instance and get the current time
for line in $(cat running_inst.txt)
do
  # Extract the instance name and IP address
  name=$(echo $line | cut -d: -f1)
  ip=$(echo $line | cut -d: -f2)

  # Log in to the instance and get the current time
  time=$(timeout 5 ssh -i ~/.ssh/devops -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null devops@$ip "date +'%Y-%m-%d %H:%M:%S'")

  if [ -z "$time" ]; then
    echo "Not able to SSH instance $name ($ip)"
    continue
  fi

  # Get the current UTC time
  current_time=$(date -u +'%Y-%m-%d %H:%M:%S')

  # Convert the times to seconds since epoch
  rst=$(date -d "$time" "+%s")
  lst=$(date -d "$current_time" "+%s")

  # Calculate the time difference in seconds
  diff=$(echo "($lst - $rst)" | bc)

  if [ "$diff" -gt 15 ]; then
    echo "Instance $name ($ip) is $diff seconds behind of current time." >> Final-UTC.txt
  elif [ "$diff" -lt -15 ]; then
    echo "Instance $name ($ip) is $((-diff)) seconds ahead current time." >> Final-UTC.txt
  fi
done

# Check if the diff file is empty
if [ -s "Final-UTC.txt" ]; then
  # If it's not empty, send an email with the contents of the diff file as an attachment
  SUBJECT="Instances out of sync with current time"
  BODY="The following instances are out of sync with the current time:"
  FROM="devops@gmail.com"
  TO="devops_int@gmail.com"
  ATTACHMENT="Final-UTC.txt"

  # Send email with attachment
  mailx -s "$SUBJECT" -a Final-UTC.txt -r "$FROM" "$TO" < Final-UTC.txt
fi
