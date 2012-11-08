# causes:
#   ec2 request stalls or fails
#   ec2 instance starts without tags

# smell:
#   box in starting state for longer than 5 minutes

# cleanup:
#   terminate instance
#   delete pinky key

# report:
#   instance affected