# StockWiz – Despliegue y Configuración

Este documento explica **únicamente** los pasos necesarios para configurar el entorno y desplegar StockWiz en AWS utilizando Terraform, Docker y GitHub.

---

# Prerrequisitos

Antes de comenzar, necesitás contar con lo siguiente:

### 1. Cuenta de AWS  
Se requiere acceso activo a una cuenta de AWS.
Este proyecto se realizó con una cuenta de AWS Academy, utilizando LabRole

### 2. Bucket S3 creado previamente  
Debe existir un bucket con el siguiente nombre obligatorio: 180358-stockwiz-backend

### 3. Repositorio clonado
El usuario debe tener el repositorio https://github.com/jdb93/devops_obligatorio clonado localmente. 

# Despliegue Manual
1- Hacer log in en cuenta de AWS mediante el siguiente comando en terminal:
```
aws configure
```

2-Completar con las credenciales de aws solicitadas. Las ultimas dos se pueden dejar como por defecto

3-En terminal, estando posicionado sobre la carpeta root del proyecto, ejecutar los siguientes comandos dependiendo del ambiente que se quiera probar:

DEV:

```
cd infra

terraform init -reconfigure \
            -backend-config="bucket=180358-stockwiz-backend" \
            -backend-config="key=dev/terraform.tfstate" \
            -backend-config="region=us-east-1"

terraform plan -var-file="envs/dev.tfvars"


terraform apply -var-file="envs/dev.tfvars" -auto-approve

cd ..
chmod +x deploy.sh
./deploy.sh dev
```

STAGING: 
```
cd infra

terraform init -reconfigure \
            -backend-config="bucket=180358-stockwiz-backend" \
            -backend-config="key=staging/terraform.tfstate" \
            -backend-config="region=us-east-1"

terraform plan -var-file="envs/staging.tfvars"


terraform apply -var-file="envs/staging.tfvars" -auto-approve

cd ..
chmod +x deploy.sh
./deploy.sh staging
```

PROD:
```
cd infra

terraform init -reconfigure \
            -backend-config="bucket=180358-stockwiz-backend" \
            -backend-config="key=prod/terraform.tfstate" \
            -backend-config="region=us-east-1"

terraform plan -var-file="envs/prod.tfvars"


terraform apply -var-file="envs/prod.tfvars" -auto-approve

cd ..
chmod +x deploy.sh
./deploy.sh prod
```

Luego de ejecutado deploy.sh, en consola se mostrará la url para acceder al recurso.

# Destruir ambiente manualmente
1-En consola, ejecutar el que corresponda:

```

terraform destroy -var-file="envs/dev.tfvars" -auto-approve
terraform destroy -var-file="envs/staging.tfvars" -auto-approve
terraform destroy -var-file="envs/prod.tfvars" -auto-approve
```
Luego de finalizado, el ambiente queda destruido

# Despliegue via GitHub Actions
1-Acceder al repositorio clonado en GitHub
2-Agregar las credenciales de AWS como secretos en GitHub

Settings -> Secrets and Variables -> Actions 

```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY 
AWS_SESSION_TOKEN
```
3-Ir a Actions
4-En el menú de la izquierda, seleccionar uno de los siguientes:

-Despliegue de dev a AWS
-Despliegue de staging a AWS
-Despliegue de Prod a AWS

5-Seleccionar "Run Workflow"
6-Elegir la branch "main"
7-Clickear "Run Workflow"

Luego de ello, se ejecuta el mismo flujo que en el despliegue manual.

En caso de querer destruir el ambiente creado, repetir el proceso, pero en el paso 4 seleccionar el que corresponda:

# Destruir ambiente via GitHub Actions
Ejecutar alguno de los siguientes flujos en Github Actions:
-Destruir AWS infra en dev
-Destruir AWS infra en staging
-Destruir AWS infra en prod