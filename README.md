# Seraphine

Seraphine provides a way to display all messages from your Netdata server on one single page.

## How does it work?

Seraphine expects a configuration file named "netdata.yml" in the root folder of the application with a list of Netdata servers where you want to fetch alarms (see netdata.sample.yml).

Uponing starting the application, Seraphine spawns a background job for each Netdata server listed and periodically pulls all alarms (configurable in the netdata.yml). The alarms are cached in MongoDB, so the frontend always gets an immediate response from our backend.

## A note about the database

Seraphine uses MongoDB as a caching database. MongoDB is heavier than Redis, but allows to easily insert JSON data. Plus, alarms from servers can be grouped into collections instead of extending lists for the same behaviour in Redis.

Again, MongoDB is only here for caching. Don't access the database with another application and instead use the provided WebSocket endpoint. Seraphine frequently deletes data:

* On each startup of the application, the database gets dropped so no old systems are present.
* On each API fetch, each collection gets emptied so resolved alarms are not longer present.
* Seraphine drops the database every hour as well to make sure no old systems are present.
