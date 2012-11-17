# Scruffy

![Scruffy](http://www.harshil.in/fun/scruffy/scruffy.png)

1. collect the state of the world
  - collect AWS state (query AWS)
  - collect pinky state (read from redis)
  - collect prism state (read from redis)
  
2. look for problems
  - duplicate servers running
  - aws box appeared
  - aws box disappeared
  - server appeared
  - server disappeared
  
3. rebalance (potentially move to brain)
  - shutdown empty Shared servers
  - bring up new boxes when at capacity
  - shut down boxes when excess capacity
  - rebalance servers for player counts

4. save new state

    /pinky/* /state
    /pinky/* /servers/*state
    /prism/*/players/
    /server/*/state
    /server/*/allocation (ram/ecus)

    /scruffy/cache/boxes

    /scruffy/cache/servers
    /scruffy/cache/pinkies
    /scruffy/cache/prisms


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
  - state (importing|starting|up|stopping|exporting)

Player
  - id
  
## pinky coming up
* (scruffy creates EC2 instance - gets instance id)
* (scruffy sets box to starting)
* box - starting
* box - up
* (scruffy sets pinky state to starting)
* pinky - starting
* pinky - up


## pinky going down
* (scruffy sets pinky state to stopping)
* (scruffy sets box state to stopping)
* (scruffy terminates box)

## Config Vars
AWS_SECRET_KEY
AWS_ACCESS_KEY
AWS_REGION

CLUSTER (default:fog)  # use local for testing with local VM
LOGFMT (default:human) # also supports json