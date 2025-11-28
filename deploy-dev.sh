#!/bin/bash

set -e  # Si falla un comando, se corta el script
set -o pipefail

# -----------------------------
# CONFIGURACIÓN
# -----------------------------

REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

ENV="dev"

CLUSTER_NAME="stockwiz"
SERVICE_NAME="stockwiz-svc"

# Imagenes (mismo naming que ECR)
API_IMAGE="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/stockwiz-api-gateway-$ENV:latest"
PRODUCT_IMAGE="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/stockwiz-product-service-$ENV:latest"
INVENTORY_IMAGE="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/stockwiz-inventory-service-$ENV:latest"
REDIS_IMAGE="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/stockwiz-redis-$ENV:7-alpine"
POSTGRES_IMAGE="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/stockwiz-postgres-$ENV:latest"

echo "==============================================="
echo " 🔐 1. Login a ECR"
echo "==============================================="

aws ecr get-login-password --region $REGION \
  | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

echo ""

# -----------------------------
# BUILD & PUSH: API GATEWAY
# -----------------------------
echo "==============================================="
echo " 🚀 2. Build/tag/push API Gateway"
echo "==============================================="

docker build -t api-gateway ./api-gateway
docker tag api-gateway:latest $API_IMAGE
docker push $API_IMAGE

# -----------------------------
# BUILD & PUSH: PRODUCT SERVICE
# -----------------------------
echo "==============================================="
echo " 🚀 3. Build/tag/push Product Service"
echo "==============================================="

docker build -t product-service ./product-service
docker tag product-service:latest $PRODUCT_IMAGE
docker push $PRODUCT_IMAGE

# -----------------------------
# BUILD & PUSH: INVENTORY SERVICE
# -----------------------------
echo "==============================================="
echo " 🚀 4. Build/tag/push Inventory Service"
echo "==============================================="

docker build -t inventory-service ./inventory-service
docker tag inventory-service:latest $INVENTORY_IMAGE
docker push $INVENTORY_IMAGE

# -----------------------------
# PULL+TAG+PUSH REDIS (NO BUILD)
# -----------------------------
echo "==============================================="
echo " 🚀 5. Pull/tag/push Redis"
echo "==============================================="

docker pull redis:7-alpine
docker tag redis:7-alpine $REDIS_IMAGE
docker push $REDIS_IMAGE

# -----------------------------
# BUILD & PUSH POSTGRES
# -----------------------------
echo "==============================================="
echo " 🚀 6. Build/tag/push Postgres"
echo "==============================================="

docker build -t stockwiz-postgres ./postgres
docker tag stockwiz-postgres:latest $POSTGRES_IMAGE
docker push $POSTGRES_IMAGE

# -----------------------------
# FORCE NEW DEPLOYMENT
# -----------------------------
echo "==============================================="
echo " 🔁 7. Actualizando ECS Service (force deployment)"
echo "==============================================="

aws ecs update-service \
  --cluster $CLUSTER_NAME \
  --service $SERVICE_NAME \
  --force-new-deployment \
  --region $REGION > /dev/null

echo "ECS: deployment iniciado."

# -----------------------------
# ESPERAR A QUE ECS ESTÉ RUNNING
# -----------------------------
echo ""
echo "==============================================="
echo " ⏳ 8. Esperando a que ECS tenga tareas RUNNING"
echo "==============================================="

aws ecs wait services-stable \
  --cluster $CLUSTER_NAME \
  --services $SERVICE_NAME \
  --region $REGION

echo "ECS: servicio estable."

# -----------------------------
# ESPERAR HEALTHCHECK DEL ALB
# -----------------------------
echo ""
echo "==============================================="
echo " ❤️ 9. Esperando a que el ALB esté healthy"
echo "==============================================="
echo ""

ALB_DNS=$(aws elbv2 describe-load-balancers \
  --region $REGION \
  --names stockwiz-alb \
  --query "LoadBalancers[0].DNSName" \
  --output text)

TARGET_ARN=$(aws elbv2 describe-target-groups \
  --region $REGION \
  --query "TargetGroups[0].TargetGroupArn" \
  --output text)

echo "ALB DNS: $ALB_DNS"
echo "TG ARN:  $TARGET_ARN"
echo "Esperando healthcheck..."

while true; do
  STATE=$(aws elbv2 describe-target-health \
    --region $REGION \
    --target-group-arn "$TARGET_ARN" \
    --query "TargetHealthDescriptions[0].TargetHealth.State" \
    --output text)

  if [ "$STATE" == "healthy" ]; then
    echo ""
    echo "🎉 ALB está healthy!"
    break
  fi

  echo "Aún no healthy... estado actual: $STATE"
  sleep 5
done

# -----------------------------
# OUTPUT FINAL
# -----------------------------
echo ""
echo "==============================================="
echo " 🎯 DEPLOY COMPLETO"
echo "==============================================="
echo "URL de la aplicación:"
echo ""
echo "   http://$ALB_DNS"
echo ""
echo "Healthcheck:"
echo ""
echo "   http://$ALB_DNS/health"
echo ""
echo "==============================================="
echo " 🚀 StockWiz DEV desplegado con éxito"
echo "==============================================="
