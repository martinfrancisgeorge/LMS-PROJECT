# Fieldwork — LMS DevOps Portfolio Project

Fieldwork is a small Learning Management System (LMS) where students can sign up, choose a learning field, access curated learning materials, and track their learning time.

The project started as a simple Flask + MySQL application and has been progressively containerized and deployed using Docker Compose and Kubernetes.

## Application Stack

* **Frontend:** HTML, CSS, JavaScript
* **Backend:** Python / Flask
* **Database:** MySQL 8.4
* **Containerization:** Docker
* **Local multi-container environment:** Docker Compose
* **Container orchestration:** Kubernetes
* **Local Kubernetes cluster:** kind
* **Kubernetes storage:** PersistentVolume + PersistentVolumeClaim
* **Kubernetes configuration:** ConfigMaps + Secrets
* **Kubernetes workload:** Deployment + StatefulSet
* **Kubernetes networking:** ClusterIP + NodePort

---

## Project Structure

```text
lms-project/
├── README.md
├── Dockerfile
├── docker-compose.yml
├── .env
├── config.sh
├── kind-config.yaml
│
├── backend/
│   ├── app.py
│   ├── config.py
│   ├── db.py
│   ├── requirements.txt
│   ├── schema.sql
│   └── seed_data.sql
│
├── frontend/
│   ├── index.html
│   ├── dashboard.html
│   ├── css/
│   │   └── style.css
│   └── js/
│       ├── auth.js
│       ├── dashboard.js
│       └── tracker.js
│
└── k8s/
    ├── lms_data/
    ├── mysql-pv.yaml
    ├── mysql-pvc.yaml
    ├── mysql-secret.yaml
    ├── mysql-statefulset.yaml
    ├── mysql-service.yaml
    ├── backend-configmap.yaml
    ├── backend-deployment.yaml
    └── backend-service.yaml
```

---

# 1. Application Architecture

The basic application flow is:

```text
Browser
   ↓
Frontend
   ↓ HTTP
Flask Backend
   ↓
db.py
   ↓
MySQL
```

The Flask backend serves both the API and the frontend.

The main application components are:

### Authentication

`app.py` provides login and signup APIs.

Passwords are hashed using Werkzeug before being stored in MySQL.

### Learning Fields

Students can select learning fields such as:

* Developer
* DevOps
* Cybersecurity
* Linux
* Cloud Computing

### Learning Materials

Learning resources are stored in the `materials` table.

Resources can include:

* YouTube videos
* Articles
* Courses
* Documentation

### Time Tracking

`frontend/js/tracker.js` sends heartbeat requests while the dashboard is active.

The backend records the student's learning time in the `time_logs` table.

---

# 2. Database

The application uses MySQL 8.4.

The database is:

```text
lms_db
```

Main tables:

```text
users
fields
materials
time_logs
```

The database schema is defined in:

```text
backend/schema.sql
```

Initial learning content is defined in:

```text
backend/seed_data.sql
```

---

# 3. Running the Application with Docker Compose

Docker Compose provides a simple multi-container environment.

The Compose architecture is:

```text
Browser
   ↓
Flask Backend Container
   ↓
MySQL Container
   ↓
Named Docker Volume
```

The Compose file defines:

* Backend container
* MySQL container
* Environment variables
* Container networking
* MySQL persistent storage
* Database initialization scripts

Start the application:

```bash
docker compose up -d
```

Check the containers:

```bash
docker compose ps
```

View logs:

```bash
docker compose logs
```

Open:

```text
http://localhost:5000
```

Stop the application:

```bash
docker compose down
```

To remove the MySQL volume and recreate the database:

```bash
docker compose down -v
docker compose up -d
```

> `docker compose down -v` deletes the MySQL persistent volume, so database data will be lost.

---

# 4. Backend Docker Image

The backend is containerized using:

```text
Dockerfile
```

The image:

* Uses Python 3.12
* Installs the backend dependencies
* Copies the Flask backend
* Copies the frontend
* Exposes port 5000
* Starts the Flask application

Build the image:

```bash
docker build -t lms-backend:latest .
```

The Kubernetes cluster uses this image.

---

# 5. Kubernetes Deployment

The project is also deployed to a local Kubernetes cluster using **kind**.

Current cluster:

```text
lms-cluster
```

Architecture:

```text
                 Kubernetes Cluster
                       │
          ┌────────────┴────────────┐
          │                         │
   Control Plane                 Worker
          │                         │
          │                  ┌──────┴──────┐
          │                  │             │
          │             Backend Pod    MySQL Pod
          │                  │             │
          │                  │             │
          │                  │        Persistent Storage
          │                  │
          └────────── Services ────────────┘
```

The local cluster contains:

* 1 control-plane node
* 1 worker node

The cluster uses Kubernetes version 1.33.1 in the current lab environment.

---

# 6. Kubernetes Resources

The LMS uses several Kubernetes resources.

## Backend Deployment

The Flask backend runs through a Kubernetes `Deployment`.

```text
Deployment
    ↓
ReplicaSet
    ↓
Backend Pod
    ↓
Flask Container
```

The backend image is:

```text
lms-backend:latest
```

The image is loaded into kind using:

```bash
kind load docker-image lms-backend:latest --name lms-cluster
```

The backend receives database configuration from a ConfigMap and database credentials from a Secret.

---

# 7. Kubernetes Services

The backend is exposed through a `NodePort` Service.

```text
Browser
   ↓
localhost:30080
   ↓
NodePort Service
   ↓
Backend Pod
   ↓
Flask :5000
```

The application is available at:

```text
http://localhost:30080
```

The MySQL database uses a `ClusterIP`-style internal service:

```text
Backend Pod
    ↓
mysql Service
    ↓
MySQL Pod
```

The backend therefore connects to MySQL using:

```text
DB_HOST=mysql
DB_PORT=3306
```

The database does not need to be exposed outside the Kubernetes cluster.

---

# 8. Kubernetes Storage

MySQL uses persistent storage instead of relying only on the container's writable layer.

The storage relationship is:

```text
MySQL Pod
    ↓
PVC
    ↓
PV
    ↓
/lms_data
    ↓
~/lms-project/k8s/lms_data
```

The project uses a manually created static `PersistentVolume`.

The PVC requests:

```text
5Gi
ReadWriteOnce
```

The PV uses:

```text
persistentVolumeReclaimPolicy: Retain
```

This means deleting the PVC does not automatically remove the underlying stored data.

---

# 9. MySQL StatefulSet

MySQL runs as a Kubernetes `StatefulSet`.

The StatefulSet provides a stable identity for the database Pod:

```text
mysql-0
```

The database storage is mounted at:

```text
/var/lib/mysql
```

The MySQL Pod also receives its initialization SQL files through a Kubernetes ConfigMap.

---

# 10. Kubernetes ConfigMap and Secret

The project uses a ConfigMap for non-sensitive configuration.

The backend ConfigMap contains values such as:

```text
DB_HOST=mysql
DB_PORT=3306
DB_NAME=lms_db
DB_USER=lms_user
```

Database passwords are stored in:

```text
mysql-secret
```

Sensitive values are therefore kept separate from normal application configuration.

The MySQL initialization files are also provided to the MySQL Pod through the `mysql-init` ConfigMap:

```text
/docker-entrypoint-initdb.d/
├── schema.sql
└── seed_data.sql
```

MySQL executes these initialization scripts when a new MySQL data directory is initialized.

---

# 11. kind Cluster Configuration

The local Kubernetes cluster is configured using:

```text
kind-config.yaml
```

The configuration provides:

* Control-plane node
* Worker node
* Host directory mount for MySQL storage
* NodePort mapping for port `30080`

The worker maps:

```text
localhost:30080
```

to the Kubernetes NodePort:

```text
30080
```

This allows the LMS to be accessed from the browser.

---

# 12. Rebuilding the Kubernetes Lab

The project includes:

```text
config.sh
```

This script helps recreate the local Kubernetes environment.

Run:

```bash
./config.sh
```

The script:

1. Creates the storage directory
2. Creates the kind configuration
3. Removes the existing kind cluster
4. Creates a new kind cluster
5. Loads the backend Docker image
6. Applies Kubernetes storage and MySQL resources
7. Waits for MySQL
8. Applies backend resources
9. Waits for the backend
10. Displays the final Kubernetes status

Check the cluster manually:

```bash
kubectl get nodes
```

Check Pods:

```bash
kubectl get pods -o wide
```

Check Services:

```bash
kubectl get svc
```

---

# 13. Current Kubernetes Architecture

The current LMS Kubernetes deployment can be visualized as:

```text
                         Browser
                            │
                            │ http://localhost:30080
                            ▼
                     ┌──────────────┐
                     │   NodePort   │
                     │    :30080    │
                     └──────┬───────┘
                            │
                            ▼
                 ┌─────────────────────┐
                 │   Backend Service   │
                 │     lms-backend     │
                 └──────────┬──────────┘
                            │
                            ▼
                 ┌─────────────────────┐
                 │    Backend Pod      │
                 │                     │
                 │ Flask :5000         │
                 └──────────┬──────────┘
                            │
                            │ mysql:3306
                            ▼
                 ┌─────────────────────┐
                 │    MySQL Service    │
                 │       mysql         │
                 └──────────┬──────────┘
                            │
                            ▼
                 ┌─────────────────────┐
                 │      mysql-0        │
                 │   StatefulSet Pod   │
                 └──────────┬──────────┘
                            │
                            ▼
                 ┌─────────────────────┐
                 │     MySQL PVC       │
                 └──────────┬──────────┘
                            │
                            ▼
                 ┌─────────────────────┐
                 │      MySQL PV       │
                 └──────────┬──────────┘
                            │
                            ▼
                 ~/lms-project/k8s/lms_data
```

---

# 14. Useful Kubernetes Commands

Check cluster nodes:

```bash
kubectl get nodes
```

Check Pods:

```bash
kubectl get pods
```

Check Pods with node and IP information:

```bash
kubectl get pods -o wide
```

Check Deployments:

```bash
kubectl get deployments
```

Check StatefulSets:

```bash
kubectl get statefulsets
```

Check Services:

```bash
kubectl get svc
```

Check PVs:

```bash
kubectl get pv
```

Check PVCs:

```bash
kubectl get pvc
```

View backend logs:

```bash
kubectl logs deployment/lms-backend
```

View MySQL logs:

```bash
kubectl logs mysql-0
```

Open a shell inside a Pod:

```bash
kubectl exec -it mysql-0 -- bash
```

---

# 15. Development Workflow

The current development workflow is:

```text
Modify Application
       ↓
Test Locally
       ↓
Build Docker Image
       ↓
Load Image into kind
       ↓
Deploy to Kubernetes
       ↓
Test Application
       ↓
Troubleshoot Kubernetes Resources
```

For backend code changes:

```bash
docker build -t lms-backend:latest .
kind load docker-image lms-backend:latest --name lms-cluster
kubectl rollout restart deployment/lms-backend
```

---

# 16. What This Project Demonstrates

This project is being used as a practical DevOps learning project rather than only as an application.

It currently demonstrates:

### Application Development

* HTML/CSS/JavaScript
* Python Flask
* REST APIs
* MySQL
* Database schema and seed data

### Docker

* Dockerfile
* Docker images
* Containers
* Environment variables
* Bind mounts
* Named volumes
* Docker Compose
* Container networking

### Kubernetes

* Cluster
* Nodes
* Pods
* Deployments
* ReplicaSets
* StatefulSets
* Services
* ClusterIP
* NodePort
* ConfigMaps
* Secrets
* PersistentVolumes
* PersistentVolumeClaims
* kind
* `kubectl`
* Kubernetes troubleshooting

---

# 17. Current Status

The LMS is currently running successfully on the local Kubernetes cluster.

Current application endpoint:

```text
http://localhost:30080
```

The application has been tested through the Kubernetes NodePort, and the Flask backend successfully connects to MySQL through the Kubernetes Service.

The MySQL database is initialized with:

```text
users
fields
materials
time_logs
```

---

# 18. Next Kubernetes Learning Steps

The Kubernetes implementation will continue to be used as a practical learning environment.

Planned learning areas include:

1. Pods
2. Deployments
3. ReplicaSets
4. Services
5. Labels and selectors
6. ConfigMaps
7. Secrets
8. PersistentVolumes and PersistentVolumeClaims
9. StatefulSets
10. Probes
11. Resource requests and limits
12. Namespaces
13. Jobs and CronJobs
14. RBAC
15. Ingress
16. Helm
17. Autoscaling
18. Kubernetes troubleshooting

The goal is to understand each Kubernetes component by implementing and troubleshooting it against the LMS rather than only studying YAML examples.

---

# 19. Known Limitations

* Sessions are currently cookie-based and intended for a small portfolio application.
* Learning materials are manually curated rather than fetched dynamically from the YouTube API.
* There is no password reset or email verification flow.
* The current Kubernetes environment is a local kind cluster rather than a production cluster.
* The current storage implementation is designed for local learning and is not intended to represent production-grade database storage.

---

# License

This project is intended as a personal learning and DevOps portfolio project.

