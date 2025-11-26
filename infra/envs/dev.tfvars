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
db_username     = "stockwizdb"
db_password = "admin123"

