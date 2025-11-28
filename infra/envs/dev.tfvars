# --- AWS Settings ---
region     = "us-east-1"
profile    = "default"
account_id = "339713009539"

# --- App name ---
app_name = "stockwiz"

# --- Environment ---
environment = "dev"

# --- VPC Networking ---
cidr            = "10.0.0.0/16"
public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

# --- Tags ---
tags = {
  Environment = "dev"
  Project     = "StockWiz"
}

# --- DB (dev) ---
db_name     = "microservices_db"
db_username = "stockwizdb"
db_password = "admin123"

ecr_repo_urls = {
  "api-gateway"       = "339713009539.dkr.ecr.us-east-1.amazonaws.com/stockwiz-api-gateway-dev"
  "product-service"   = "339713009539.dkr.ecr.us-east-1.amazonaws.com/stockwiz-product-service-dev"
  "inventory-service" = "339713009539.dkr.ecr.us-east-1.amazonaws.com/stockwiz-inventory-service-dev"
  "redis"             = "339713009539.dkr.ecr.us-east-1.amazonaws.com/stockwiz-redis-dev"
  "postgres"          = "339713009539.dkr.ecr.us-east-1.amazonaws.com/stockwiz-postgres-dev"
}

database_url = "postgresql://stockwizdb:admin123@localhost:5432/microservices_db?sslmode=disable"
bucket_name = "180358-stockwiz-backend"
# esto era: db_url      = "postgresql://stockwizdb:admin123@stockwiz-postgres:5432/microservices_db?sslmode=disable"
db_url = "postgresql://stockwizdb:admin123@10.0.4.237:5432/microservices_db"
desired_count = 1