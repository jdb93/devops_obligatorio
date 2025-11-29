# --- AWS Settings ---
region     = "us-east-1"
profile    = "default"

# --- App name ---
app_name = "stockwiz"

# --- Environment ---
environment = "staging"

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

database_url = "postgresql://stockwizdb:admin123@localhost:5432/microservices_db?sslmode=disable"
bucket_name = "180358-stockwiz-backend"
desired_count = 1