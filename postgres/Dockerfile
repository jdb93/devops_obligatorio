FROM postgres:15-alpine

# Variables por defecto (se pueden cambiar desde ECS)
ENV POSTGRES_USER=stockwizdb \
    POSTGRES_PASSWORD=admin123 \
    POSTGRES_DB=microservices_db

# Copiamos el archivo de inicialización
COPY init.sql /docker-entrypoint-initdb.d/init.sql
