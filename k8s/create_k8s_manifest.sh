#!/bin/bash

# Create and write to client.yml file
cat <<EOF > client.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: client
  namespace: emartapp-ns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: emartclient
  template:
    metadata:
      labels:
        app: emartclient
    spec:
      containers:
      - name: emartapp-client
        image: tireni/emartapp-client
        ports:
          - name: client-port
            containerPort: 4200
---
apiVersion: v1
kind: Service
metadata:
  name: client
  namespace: emartapp-ns
spec:
  selector:
    app: emartclient
  ports:
  - port: 4200
    targetPort: client-port
    protocol: TCP
  type: LoadBalancer
EOF

echo "client.yml has been created."

# Create and write to secret.yml file
cat <<EOF > secret.yml
apiVersion: v1
kind: Secret
metadata:
  name: db-cret
  namespace: emartapp-ns
type: Opaque
data:
  MYSQL_ROOT_PASSWORD: ZW1hcnRkYnBhc3M=  # base64 encoded value
  MONGO_INITDB_DATABASE: ZXBvYw==         # base64 encoded value
  MYSQL_DATABASE: Ym9va3M=                # base64 encoded value
EOF

echo "secret.yml has been created."

# Create and write to pvc.yml file
cat <<EOF > pvc.yml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: emongo-pvc
  namespace: emartapp-ns
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: emartdb-pvc
  namespace: emartapp-ns
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
EOF

echo "pvc.yml has been created."

# Create and write to webapi.yml file
cat <<EOF > webapi.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapi
  namespace: emartapp-ns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: emartwebapi
  template:
    metadata:
      labels:
        app: emartwebapi
    spec:
      containers:
      - name: emartapp-webapi
        image: tireni/emartapp-webapi
        ports:
          - name: webapi-port
            containerPort: 9000
---
apiVersion: v1
kind: Service
metadata:
  name: webapi
  namespace: emartapp-ns
spec:
  selector:
    app: emartwebapi
  ports:
  - port: 9000
    targetPort: webapi-port
    protocol: TCP
  type: ClusterIP
EOF

echo "webapi.yml has been created."

# Create and write to emongo.yml file
cat <<EOF > emongo.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: emongo
  namespace: emartapp-ns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: emongo
  template:
    metadata:
      labels:
        app: emongo
    spec:
      containers:
      - name: emongo
        image: mongo:4.4.8-focal
        volumeMounts:
          - name: emongo-storage
            mountPath: /data/db       
        ports:
          - name: emongo-port
            containerPort: 27017
        env:
          - name: MONGO_INITDB_DATABASE
            valueFrom:
              secretKeyRef:
                name: db-cret
                key: MONGO_INITDB_DATABASE
      volumes:
        - name: emongo-storage
          persistentVolumeClaim: 
            claimName: emongo-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: emongo
  namespace: emartapp-ns
spec:
  selector:
    app: emongo
  ports:
  - port: 27017
    targetPort: emongo-port
    protocol: TCP
  type: ClusterIP
EOF

echo "emongo.yml has been created."

# Create and write to emartdb.yml file
cat <<EOF > emartdb.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: emartdb
  namespace: emartapp-ns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: emartdb
  template:
    metadata:
      labels:
        app: emartdb
    spec:
      containers:
      - name: mysql
        image: mysql:8.0.33
        volumeMounts:
          - name: emartdb-storage
            mountPath: /var/lib/mysql
        ports:
          - name: emartdb-port
            containerPort: 3306
        env:
          - name: MYSQL_DATABASE
            valueFrom:
              secretKeyRef:
                name: db-cret
                key: MYSQL_DATABASE
          - name: MYSQL_ROOT_PASSWORD
            valueFrom:
              secretKeyRef:
                name: db-cret
                key: MYSQL_ROOT_PASSWORD
      volumes:
        - name: emartdb-storage
          persistentVolumeClaim:
            claimName: emartdb-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: emartdb
  namespace: emartapp-ns
spec:
  selector:
    app: emartdb
  ports:
  - port: 3306
    targetPort: emartdb-port
    protocol: TCP
  type: ClusterIP
EOF

echo "emartdb.yml has been created."

# Create and write to nginx-config.yml file
cat <<EOF > nginx-config.yml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
  namespace: emartapp-ns
data:
  default.conf: |
    upstream client {
        server client:4200;
    }
    server {
        listen 80;
        location / {
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;

            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_pass http://client/;
        }
        location /api {
            proxy_pass http://api:5000;
        }
        location /webapi {
            proxy_pass http://webapi:9000;
        }
    }
EOF

echo "nginx-config.yml has been created."

# Create and write to nginx.yml file
cat <<EOF > nginx.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: emartapp-ns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: emartnginx
  template:
    metadata:
      labels:
        app: emartnginx
    spec:
      containers:
      - name: emart-nginx
        image: nginx:alpine-slim
        ports:
          - name: nginx-port
            containerPort: 80
        volumeMounts:
          - name: nginx-config-volume
            mountPath: /etc/nginx/conf.d/default.conf
            subPath: default.conf
      volumes:
      - name: nginx-config-volume
        configMap:
          name: nginx-config
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
  namespace: emartapp-ns
spec:
  selector:
    app: emartnginx
  ports:
  - port: 80
    targetPort: nginx-port 
    protocol: TCP
  type: LoadBalancer
EOF

echo "nginx.yml has been created."

# Create and write to api.yml file
cat <<EOF > api.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api  
  namespace: emartapp-ns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: emartapi 
  template:
    metadata:
      labels:
        app: emartapi
    spec:
      containers:
      - name: emartapp-api  
        image: tireni/emartapp-api
        ports:
          - name: api-port
            containerPort: 5000 
---
apiVersion: v1
kind: Service
metadata:
  name: api
  namespace: emartapp-ns
spec:
  selector:
    app: emartapi
  ports:
    - port: 5000
      targetPort: api-port
      protocol: TCP
  type: ClusterIP
EOF

echo "api.yml has been created."

echo "All Kubernetes manifest files have been generated."
