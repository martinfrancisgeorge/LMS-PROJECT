#!/bin/bash

set -e

CLUSTER_NAME="lms-cluster"
PROJECT_DIR="/home/martin/lms-project"
K8S_DIR="$PROJECT_DIR/k8s"
DATA_DIR="$K8S_DIR/lms_data"

echo "========================================"
echo " LMS Kubernetes Lab Setup"
echo "========================================"

echo ""
echo "[1/8] Creating storage directory..."
mkdir -p "$DATA_DIR"

echo ""
echo "[2/8] Creating kind cluster configuration..."

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
    extraMounts:
      - hostPath: $DATA_DIR
        containerPath: /lms_data
EOF

echo ""
echo "[3/8] Removing existing kind cluster..."
kind delete cluster --name "$CLUSTER_NAME" 2>/dev/null || true

echo ""
echo "[4/8] Creating kind cluster..."
kind create cluster \
  --name "$CLUSTER_NAME" \
  --config "$PROJECT_DIR/kind-config.yaml"

echo ""
echo "[5/8] Loading LMS backend image..."
kind load docker-image lms-backend:latest --name "$CLUSTER_NAME"

echo ""
echo "[6/8] Applying Kubernetes resources..."

kubectl apply -f "$K8S_DIR/mysql-pv.yaml"
kubectl apply -f "$K8S_DIR/mysql-pvc.yaml"
kubectl apply -f "$K8S_DIR/mysql-secret.yaml"
kubectl apply -f "$K8S_DIR/mysql-service.yaml"
kubectl apply -f "$K8S_DIR/mysql-statefulset.yaml"

echo ""
echo "Waiting for MySQL..."
kubectl wait \
  --for=condition=ready pod/mysql-0 \
  --timeout=180s

echo ""
echo "[7/8] Deploying backend..."

kubectl apply -f "$K8S_DIR/backend-configmap.yaml"
kubectl apply -f "$K8S_DIR/backend-deployment.yaml"
kubectl apply -f "$K8S_DIR/backend-service.yaml"

echo ""
echo "Waiting for backend..."
kubectl wait \
  --for=condition=available deployment/lms-backend \
  --timeout=180s

echo ""
echo "[8/8] Final Kubernetes status..."

echo ""
echo "=== Nodes ==="
kubectl get nodes

echo ""
echo "=== Pods ==="
kubectl get pods -o wide

echo ""
echo "=== Services ==="
kubectl get svc

echo ""
echo "========================================"
echo " LMS Kubernetes Lab Ready"
echo "========================================"

echo ""
echo "Open the LMS in your browser:"
echo "http://localhost:30080"
