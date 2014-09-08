# Poirot Web Interface

This repository contains the web frontend for visualising and querying data stored by Poirot in an ElasticSearch cluster. It makes use of the [hercule](https://bitbucket.org/instedd/hercule) gem for managing log entries and activities.

## Deployment

The Poirot web interface is a standard Rails web application. It requires a relational database for configuration storage and a connection to the ElasticSearch cluster where the log data is stored. You can deploy it as any other Rails app, or by making use of the Poirot Chef [cookbook](https://github.com/instedd-cookbooks/poirot).

## Settings

Refer to `config/settings.yml` file for customisable settings, such as connection to the ElasticSearch cluster or mailer configuration for delivering alerts.

## Authentication

This interface currently does not support authentication. Authentication modules can be used directly in the web server configuration for securing the site.
