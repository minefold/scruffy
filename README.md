# Sweeper

One box has one pinky, both identified by the instance-id from Amazon (eg i-fb0c3287)

Box - Amazon ec2 instance
  id
  started_at
  instance_type
  state (starting|up|stopping) # this is the state of the Amazon instance
  
Pinky
  id # same as Box#id
  state (starting|up|stopping)
  servers
  players
  freeDiskMb
  freeRamMb
  idleCpu

Server
  - id
  - state (starting|up|stopping)

Player
  - id