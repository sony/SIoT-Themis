apiVersion: apps/v1
kind: StatefulSet
metadata:
  namespace: default
  name: ${sys_name}-${env}-postgresql
  labels:
    app: postgres
spec:
  serviceName: "${sys_name}-${env}-postgresql-svc"
  replicas: 2
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      initContainers:
      - name: init
        image: postgres:16.3
        command:
        - /bin/bash
        - -c
        - |
          set -e
          if [[ ! -d /data/pgdata ]] ; then
            mkdir -v /data/pgdata
            chmod -v 700 /data/pgdata
            chmod -v 700 /data
            chown -v -R 999:999 /data
          fi
        volumeMounts:
        - name: postgres-pvc-pgdata
          mountPath: "/data"
      containers:
      - name: ${sys_name}-${env}-postgresql
        image: postgres:16.3
        env:
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: postgresql-secret
              key: postgresql_user
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgresql-secret
              key: postgresql_password
        - name: POSTGRES_DB
          value: "postgres"
        - name: PGDATA
          value: "/data/pgdata"
        ports:
        - containerPort: 5432
          name: postgres-svc
          protocol: TCP
        livenessProbe:
          exec:
            command: ["pg_isready"]
          failureThreshold: 10
          initialDelaySeconds: 30
          periodSeconds: 15
          successThreshold: 1
          timeoutSeconds: 10
        readinessProbe:
          exec:
            command: ["psql", "-h", "127.0.0.1", "-U", "postgres",  "-c", "SELECT 1"]
          failureThreshold: 10
          initialDelaySeconds: 30
          periodSeconds: 15
          successThreshold: 1
          timeoutSeconds: 10
        command:
        - /bin/bash
        - -c
        - |
          set -e
          export PATH=$${PATH}:/usr/lib/postgresql/16/bin
          if [[ ! -s ${pg_data}/PG_VERSION ]]; then
            echo 'Initializing database...'
            initdb
            cp /mnt/configmap/postgresql.conf ${pg_data}
            cp /mnt/configmap/pg_hba.conf ${pg_data}
          fi
          if [[ $(hostname) == '${sys_name}-${env}-postgresql-0' ]]; then
            echo 'Starting as master'
            exec postgres -D ${pg_data} -c config_file=${pg_data}/postgresql.conf
            exec postgres -D ${pg_data}
          else
            echo 'Starting as slave'
            until pg_isready -h ${sys_name}-${env}-postgresql-0.${sys_name}-${env}-postgresql-svc.default.svc.cluster.local -p 5432; do
              sleep 1
            done
            rm -rf ${pg_data}/*
            pg_basebackup -D ${pg_data} -h ${sys_name}-${env}-postgresql-0.${sys_name}-${env}-postgresql-svc.default.svc.cluster.local -p 5432 -U postgres -Xs -R -P
            exec -- postgres -D ${pg_data} -c hot_standby=on
          fi
        volumeMounts:
        - name: postgres-pvc-pgdata
          mountPath: "/data"
        - name: postgres-pvc-pgconf
          mountPath: "/mnt/configmap/pg_hba.conf"
          subPath: pg_hba.conf
        - name: postgres-pvc-pgconf
          mountPath: "/mnt/configmap/postgresql.conf"
          subPath: postgresql.conf
        securityContext:
          runAsNonRoot: true
          runAsGroup: 999
          runAsUser: 999
      volumes:
      - name: postgres-pvc-pgconf
        configMap:
          name: postgres-conf
  volumeClaimTemplates:
  - metadata:
      name: postgres-pvc-pgdata
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 30Gi
      storageClassName: "gp2"
