apiVersion: v1
kind: ConfigMap
metadata:
  namespace: default
  name: postgres-conf
  labels:
    app: postgres
    type: file
data:
  pg_hba.conf: |
    # TYPE  DATABASE        USER            ADDRESS                 METHOD
    # "local" is for Unix domain socket connections only
    local   all             all                                     trust
    # IPv4 local connections:
    host    all             all             127.0.0.1/32            trust
    # IPv6 local connections:
    host    all             all             ::1/128                 trust
    # Allow replication connections from localhost, by a user with the
    # replication privilege.
    local   replication     all                                     trust
    host    replication     all             127.0.0.1/32            trust
    host    replication     all             ::1/128                 trust
    host    all             all             10.0.0.0/8              trust
    host    replication     all             10.0.0.0/8              trust
  postgresql.conf: |
    # PostgreSQL configuration file
    listen_addresses = '*'
    max_wal_senders = 2
    max_wal_size = 10GB
    wal_level = replica
    synchronous_commit = on
    wal_sender_timeout = 1s
    synchronous_standby_names = '*'
    recovery_target_timeline = 'latest'
