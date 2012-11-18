# Scruffy
[![Build Status](https://magnum.travis-ci.com/minefold/scruffy.png?token=yfARxv3oq7ZT3ZbmJWVN)](http://magnum.travis-ci.com/minefold/scruffy) © Mütli Corp. By [Dave Newman](http://github.com/whatupdave).

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


## Usage

    foreman start

### Environment

*Required*

    AWS_ACCESS_KEY
    AWS_SECRET_KEY
    AWS_REGION
    REDIS_URL
    BUGSNAG

*Optional*

    SCRUFFY_ENV (staging|production)
    SCRUFFY_ROOT
