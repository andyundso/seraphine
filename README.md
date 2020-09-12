# Seraphine

Seraphine provides a way to display all messages from your Netdata server on one single page.

## How does it work?

Seraphine expects a configuration file named "netdata.yml" in the root folder of the application with a list of Netdata servers where you want to fetch alarms (see netdata.sample.yml).

Uponing starting the application, Seraphine spawns a background job for each Netdata server listed and periodically pulls all alarms (configurable in the netdata.yml). The alarms are cached in MongoDB, so the frontend always gets an immediate response from our backend.
