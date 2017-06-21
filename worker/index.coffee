# Ok, this is our Kue queue, which will handle how jobs are handled by our workers
queue = require('../util/queue')

# Import the logger
logger = require('../util/logger')

# Rollbar
handle = require('../util/rollbar').handle

# Variables
variables = require '../util/variables'

# Redis client
client = require '../util/redis'

# Create our leadership testing server
logger.debug "[index.coffee] Setting up web server for worker process..."
app = require('express')()
app.get '/', (req, res) ->
  res.end process.env.HOSTNAME # Return the hostname that Flynn has generated for us, which should be unique
app.listen variables.port, (err) ->
  if err then throw err
  logger.debug "[index.coffee] Web server now up and running on port #{variables.port}"

# The request client
request = require 'request'

# The function to determine that returns whether or not we are the leader
getIfLeader = (done) ->
  logger.debug "[getIfLeader] Getting if we are the leader..."
  request "http://leader.#{process.env.FLYNN_APP_NAME}-worker-web.discoverd:8080/", (err, res, body) ->
    if err
      logger.error "[getIfLeader] We got an error while trying to figure out if our process is the leader"
      return done err
    if res.statusCode isnt 200
      logger.error "[getIfLeader] The response code from the leader process wasn't 200 for some reason"
      return done Error "Response code wasn't 200! Was #{res.statusCode}"
    result = if body is process.env.HOSTNAME then true else false
    logger.debug "[getIfLeader] Leader Result: #{result}"
    return done result # If the response we get is equal to our randomString, then we are the leader
