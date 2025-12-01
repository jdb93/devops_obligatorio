#!/bin/bash

set -e
set -o pipefail

# -----------------------------
# PARAMETROS
# -----------------------------
if [ -z "$1" ]; then
  echo "Uso: ./deploy.sh <dev|staging|prod>"
  exit 1
fi

ENV="$1"  # dev, staging o prod

# -----------------------------
# CONFIGURACIÓN BASE
# -----------------------------
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

APP_NAME="stockwiz"

# Nombres generados (COHERENTES CON TERRAFORM)
CLUSTER_NAME="${APP_NAME}-${ENV}"
SERVICE_NAME="${APP_NAME}-svc-${ENV}"
ALB_NAME="${APP_NAME}-alb-${ENV}"
TG_NAME="${APP_NAME}-api-tg-${ENV}"

# -----------------------------
# IMAGENES ECR (MISMO NAMING QUE TERRAFORM)
# -----------------------------
API_IMAGE="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/${APP_NAME}-api-gateway-${ENV}:latest"
PRODUCT_IMAGE="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/${APP_NAME}-product-service-${ENV}:latest"
INVENTORY_IMAGE="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/${APP_NAME}-inventory-service-${ENV}:latest"
REDIS_IMAGE="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/stockwiz-redis-${ENV}:latest"
POSTGRES_IMAGE="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/${APP_NAME}-postgres-${ENV}:latest"

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
# PULL+TAG+PUSH REDIS
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

docker build -t ${APP_NAME}-postgres ./postgres
docker tag ${APP_NAME}-postgres:latest $POSTGRES_IMAGE
docker push $POSTGRES_IMAGE

# -----------------------------
# FORCE NEW DEPLOYMENT
# -----------------------------
echo "==============================================="
echo " 🔁 7. Actualizando ECS Service (${SERVICE_NAME})"
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
echo " ⏳ 8. Esperando servicio ECS estable"
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
  --names $ALB_NAME \
  --query "LoadBalancers[0].DNSName" \
  --output text)

TARGET_ARN=$(aws elbv2 describe-target-groups \
  --region $REGION \
  --names $TG_NAME \
  --query "TargetGroups[0].TargetGroupArn" \
  --output text)

echo "ALB DNS: $ALB_DNS"
echo "TG ARN:  $TARGET_ARN"
echo ""

echo "Esperando healthcheck..."

while true; do
  HEALTHY_COUNT=$(aws elbv2 describe-target-health \
    --region $REGION \
    --target-group-arn "$TARGET_ARN" \
    --query "length(TargetHealthDescriptions[?TargetHealth.State=='healthy'])" \
    --output text)

  if [ "$HEALTHY_COUNT" -ge 1 ]; then
    echo ""
    echo "🎉 ALB está healthy!"
    break
  fi

  STATES=$(aws elbv2 describe-target-health \
    --region $REGION \
    --target-group-arn "$TARGET_ARN" \
    --query "TargetHealthDescriptions[*].TargetHealth.State" \
    --output text)

  echo "Aún no healthy... estados actuales: $STATES"

  sleep 5
done

# -----------------------------
# OUTPUT FINAL
# -----------------------------
echo ""
echo "==============================================="
echo " 🎯 DEPLOY COMPLETO - ENV: $ENV"
echo "==============================================="
echo "URL de la aplicación:"
echo ""
echo "http://$ALB_DNS"
echo ""
echo "Healthcheck:"
echo ""
echo "http://$ALB_DNS/health"
echo ""
echo "==============================================="

# -----------------------------
# LAMBDA HEALTHCHECK POST-DEPLOY
# -----------------------------
echo "==============================================="
echo " 🔔 Ejecutando Lambda de healthcheck post-deploy"
echo "==============================================="

LAMBDA_NAME="${APP_NAME}-${ENV}-healthcheck"

aws lambda invoke \
  --function-name $LAMBDA_NAME \
  --region $REGION \
  lambda_response.json > /dev/null

echo "Lambda response:"
cat lambda_response.json
echo ""

echo ""
echo "==============================================="
echo " 🌐  URL de acceso del entorno $ENV"
echo "==============================================="
echo "API Gateway:"
echo "   http://$ALB_DNS"
echo ""
echo "Productos:"
echo "   http://$ALB_DNS/api/products"
echo ""
echo "Inventario:"
echo "   http://$ALB_DNS/api/inventory"
echo ""
echo "Healthcheck:"
echo "   http://$ALB_DNS/health"
echo "==============================================="