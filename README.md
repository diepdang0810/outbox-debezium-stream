Copyright Debezium Authors. Licensed under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).

# Outbox pattern with debezium, kafka stream

This repository contains multiple examples for using Debezium, e.g. configuration files, Docker Compose files, OpenShift templates.


## Getting Started
1. Copy .env `cp example.env .env`
2. Start docker
```
docker-compose up -d
```
3. Create connector:
```
curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" 127.0.0.1:8083/connectors/ --data "@connector.json"
```
4. View topic: `http://localhost:8089`