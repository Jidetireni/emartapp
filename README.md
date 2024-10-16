# EmartApp

**EmartApp** is an e-commerce web application designed using a microservices architecture that integrates multiple services seamlessly. 

## Architecture Overview

- The **API Gateway** utilizes an Nginx configuration to route various endpoints.
- The **frontend** client is built using Angular.
- The **main API** is developed with Node.js and connected to a MongoDB database.
- For the **Books API**, we are using Java with a MySQL database.

## Project Goal

The goal of this project is to build a full DevOps lifecycle, Involving everything from Minikube cluster deployment to full cloud migration. The project is divided into two main sections:

### 1. Minikube Cluster Deployment

#### Build and Containerize the Microservices

- Utilized Docker best practices when writing the Dockerfiles.
- Employed Docker Compose to connect all services using a Docker network and volumes for database data persistence.

To build and use Docker Compose, ensure you have Docker and Docker Compose installed on your local machine. You can find the Dockerfiles in the following locations:

- **Client:** `emartapp/client/Dockerfile`
- **Main Web API:** `emartapp/nodeapi/Dockerfile`
- **Books API:** `emartapp/javaapi/Dockerfile`
- **Docker Compose file:** `emartapp/compose.yml`

To run the services, execute the following command:

```bash
docker compose up -d
```

#### CI Pipeline

- Built a simple CI pipeline using GitHub Actions to publish images to Docker Hub.
- The workflow is located at: `.github/workflow/emart-ci.yml`

#### Minikube Local Cluster Deployment

- Created manifest files for each service, including deployments for pods and services for each object to communicate with each other within the cluster.
- Utilized Kubernetes Secrets for sensitive information, Persistent Volume Claims (PVC) for data persistence, and ConfigMaps for Nginx API Gateway configuration.

You can check all the manifests in the `emartapp/k8s` directory. A dedicated namespace, `emartapp-ns`, is used to group all objects together. 

To set up the Minikube environment, ensure you have Minikube installed on your local machine. Follow these steps:

1. Enter the `emartapp/k8s` directory.
2. Create the namespace:

   ```bash
   kubectl create ns emartapp-ns
   ```

3. Apply the manifests to create all objects in the namespace:

   ```bash
   kubectl apply -f .
   ```

4. Check the status of all objects:

   ```bash
   kubectl get all -n emartapp-ns
   ```