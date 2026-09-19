#!/bin/bash

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
K8S_DIR="$PROJECT_DIR/k8s"
DATA_DIR="$K8S_DIR/lms_data"
CLUSTER_NAME="lms-cluster"

echo "======================================"
echo " LMS Kubernetes Setup"
echo "======================================"

echo "Creating data directory..."
mkdir -p "$DATA_DIR"

echo "Creating kind configuration..."

cat > "$PROJECT_DIR/kind-config.yaml" <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4

nodes:

  - role: control-plane
    extraMounts:
      - hostPath: $DATA_DIR
        containerPath: /lms_data

  - role: worker
    extraPortMappings:

      - containerPort: 30080
        hostPort: 30080
        protocol: TCP

      - containerPort: 80
        hostPort: 80
        protocol: TCP

    extraMounts:
      - hostPath: $DATA_DIR
        containerPath: /lms_data
EOF

echo "======================================"
echo " Recreating kind cluster"
echo "======================================"

kind delete cluster --name "$CLUSTER_NAME" || true

kind create cluster \
  --name "$CLUSTER_NAME" \
  --config "$PROJECT_DIR/kind-config.yaml"

echo "Loading backend image into kind..."

kind load docker-image lms-backend:latest \
  --name "$CLUSTER_NAME"

echo "======================================"
echo " Creating MySQL initialization ConfigMap"
echo "======================================"

kubectl create configmap mysql-init \
  --from-file=schema.sql="$PROJECT_DIR/backend/schema.sql" \
  --from-file=seed_data.sql="$PROJECT_DIR/backend/seed_data.sql" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "======================================"
echo " Deploying MySQL storage"
echo "======================================"

kubectl apply -f "$K8S_DIR/mysql-pv.yaml"
kubectl apply -f "$K8S_DIR/mysql-pvc.yaml"

echo "======================================"
echo " Deploying MySQL Secret"
echo "======================================"

kubectl apply -f "$K8S_DIR/mysql-secret.yaml"

echo "======================================"
echo " Deploying MySQL Service"
echo "======================================"

kubectl apply -f "$K8S_DIR/mysql-service.yaml"

echo "======================================"
echo " Deploying MySQL StatefulSet"
echo "======================================"

kubectl apply -f "$K8S_DIR/mysql-statefulset.yaml"

kubectl rollout status statefulset/mysql \
  --timeout=300s

echo "======================================"
echo " Deploying Backend"
echo "======================================"

kubectl apply -f "$K8S_DIR/backend-configmap.yaml"
kubectl apply -f "$K8S_DIR/backend-deployment.yaml"
kubectl apply -f "$K8S_DIR/backend-service.yaml"

kubectl rollout status deployment/lms-backend \
  --timeout=300s

echo "======================================"
echo " Deploying HPA"
echo "======================================"

kubectl apply -f "$K8S_DIR/backend-hpa.yaml"

echo "======================================"
echo " Installing Metrics Server"
echo "======================================"

kubectl apply -f \
  https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

echo "Configuring Metrics Server for kind..."

kubectl patch deployment metrics-server \
  -n kube-system \
  --type='json' \
  -p='[
    {
      "op": "add",
      "path": "/spec/template/spec/containers/0/args/-",
      "value": "--kubelet-insecure-tls"
    }
  ]'

kubectl rollout status deployment/metrics-server \
  -n kube-system \
  --timeout=300s

echo "======================================"
echo " Installing NGINX Ingress Controller"
echo "======================================"

kubectl apply -f \
  https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.13.2/deploy/static/provider/kind/deploy.yaml

echo "Waiting for NGINX Ingress Controller..."

kubectl wait \
  --namespace ingress-nginx \
  --for=condition=Ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

echo "======================================"
echo " Creating LMS Ingress"
echo "======================================"

kubectl apply -f "$K8S_DIR/lms-ingress.yaml"

echo "======================================"
echo " Kubernetes Setup Complete"
echo "======================================"

echo ""
echo "Nodes:"
kubectl get nodes

echo ""
echo "Pods:"
kubectl get pods -A

echo ""
echo "Services:"
kubectl get svc

echo ""
echo "Ingress:"
kubectl get ingress

echo ""
echo "HPA:"
kubectl get hpa

echo ""
echo "Metrics:"
kubectl top pods || true

echo ""
echo "======================================"
echo " LMS URLs"
echo "======================================"

echo "Ingress:  http://localhost"
echo "NodePort: http://localhost:30080"

echo "======================================"
