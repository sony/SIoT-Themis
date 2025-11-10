apiVersion: v1
kind: ConfigMap
metadata:  
  namespace: default
  name: cygnus-agent-conf
data:
  agent.conf: |
    # Fixed by Abelsoft 2025
    cygnus-ngsi.sources = http-source-mongo 
    cygnus-ngsi.sinks = mongo-sink sth-sink 
    cygnus-ngsi.channels = mongo-channel sth-channel 
       
    # Mongo http-source
    cygnus-ngsi.sources.http-source-mongo.type = org.apache.flume.source.http.HTTPSource
    cygnus-ngsi.sources.http-source-mongo.channels = mongo-channel sth-channel
    cygnus-ngsi.sources.http-source-mongo.port = 5051
    cygnus-ngsi.sources.http-source-mongo.handler = com.telefonica.iot.cygnus.handlers.NGSIRestHandler
    cygnus-ngsi.sources.http-source-mongo.handler.notification_target = /notify
    cygnus-ngsi.sources.http-source-mongo.handler.default_service = default
    cygnus-ngsi.sources.http-source-mongo.handler.default_service_path = /
    cygnus-ngsi.sources.http-source-mongo.interceptors = ts nmi
    cygnus-ngsi.sources.http-source-mongo.interceptors.ts.type = timestamp
    cygnus-ngsi.sources.http-source-mongo.interceptors.nmi.type = com.telefonica.iot.cygnus.interceptors.NGSINameMappingsInterceptor$Builder
    cygnus-ngsi.sources.http-source-mongo.interceptors.nmi.name_mappings_conf_file = /opt/apache-flume/conf/name_mappings.conf
    
    # Mongo sink using mongo_uri
    cygnus-ngsi.sinks.mongo-sink.type = com.telefonica.iot.cygnus.sinks.NGSIMongoSink
    cygnus-ngsi.sinks.mongo-sink.channel = mongo-channel
    cygnus-ngsi.sinks.mongo-sink.enable_encoding = true
    cygnus-ngsi.sinks.mongo-sink.data_model = dm-by-service-path
    cygnus-ngsi.sinks.mongo-sink.attr_persistence = column
    cygnus-ngsi.sinks.mongo-sink.mongo_uri = mongodb://${username}:${password}@${host}/?replicaSet=rs0&retryWrites=false
    cygnus-ngsi.sinks.mongo-sink.mongo_ssl = true
    cygnus-ngsi.sinks.mongo-sink.mongo_ssl_truststore_path_file = /usr/lib/jvm/java-17-openjdk-amd64/lib/security/cacerts
    cygnus-ngsi.sinks.mongo-sink.mongo_ssl_truststore_password = ${mongo_ssl_truststore_password}

    cygnus-ngsi.sinks.sth-sink.type = com.telefonica.iot.cygnus.sinks.NGSISTHSink
    cygnus-ngsi.sinks.sth-sink.channel = sth-channel
    cygnus-ngsi.sinks.sth-sink.mongo_uri = mongodb://${username}:${password}@${host}/?replicaSet=rs0&retryWrites=false
    cygnus-ngsi.sinks.sth-sink.collections_size = 536870912
    cygnus-ngsi.sinks.sth-sink.mongo_ssl = true
    cygnus-ngsi.sinks.sth-sink.mongo_ssl_truststore_path_file = /usr/lib/jvm/java-17-openjdk-amd64/lib/security/cacerts
    cygnus-ngsi.sinks.sth-sink.mongo_ssl_truststore_password = ${mongo_ssl_truststore_password}

    # Channels
    cygnus-ngsi.channels.mongo-channel.type = com.telefonica.iot.cygnus.channels.CygnusMemoryChannel
    cygnus-ngsi.channels.mongo-channel.capacity = 100000
    cygnus-ngsi.channels.mongo-channel.transactionCapacity = 10000
    
    cygnus-ngsi.channels.sth-channel.type = com.telefonica.iot.cygnus.channels.CygnusMemoryChannel
    cygnus-ngsi.channels.sth-channel.capacity = 100000
    cygnus-ngsi.channels.sth-channel.transactionCapacity = 10000
