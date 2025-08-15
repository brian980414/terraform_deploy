# 🚀 Deploy end-to-end: Terraform + Docker Compose + Nginx

Este documento cubre **todo el flujo** para desplegar una aplicación completa: desde la infraestructura con **Terraform**, pasando por la orquestación de contenedores con **Docker Compose**, hasta la configuración de **Nginx** en una instancia EC2 para servir un frontend tipo SPA y hacer *reverse proxy* al backend.

---

## 🔧 Requisitos previos

* Cuenta y credenciales de **AWS** configuradas localmente.
* **Terraform** 1.5+ instalado.
* **SSH key** válida para conexión a la EC2.
* Repositorio con archivo `docker-compose.yml`.

  * El servicio `web` copia automáticamente el *build* del frontend en `/var/www/web` en el host.

> **Puertos recomendados en el Security Group (SG)**:
>
> * 22 (SSH)
> * 80 (HTTP)
> * 443 (HTTPS)
> * Puertos internos solo si son necesarios (8000, 8081, 5173, etc.).

---

## 1️⃣ Despliegue de infraestructura con Terraform

Desde el directorio donde se encuentran los archivos `.tf`:

```bash
terraform init
terraform apply -auto-approve
```

Conectar por SSH a la EC2:

```bash
ssh -i <tu-clave.pem> ubuntu@<IP_PUBLICA>
```

Verificar que el build del frontend está disponible:

```bash
ls -lah /var/www/web
```

---

## 2️⃣ Instalación y configuración de Nginx

```bash
sudo apt update
sudo apt install -y nginx
```

Crear el archivo de configuración:

```bash
sudo nano /etc/nginx/sites-available/proportfolio.conf
```

**Configuración para Frontend (SPA):**

```nginx
server {
    listen 80;
    server_name web.tudominio.com; # Cambiar por el dominio del frontend

    root /var/www/web;
    index index.html;

    location / {
        try_files $uri /index.html;
    }

    # Cache ligera de estáticos
    location ~* \.(?:js|mjs|css|png|jpg|jpeg|gif|svg|ico|woff2?)$ {
        expires 7d;
        add_header Cache-Control "public, max-age=604800, immutable";
        try_files $uri =404;
    }
}
```

**Configuración para Backend (API - Reverse Proxy):**

```nginx
server {
    listen 80;
    server_name api.tudominio.com; # Cambiar por el dominio del backend

    location / {
        proxy_pass         http://127.0.0.1:8000;
        proxy_http_version 1.1;

        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;

        proxy_set_header   Upgrade           $http_upgrade;
        proxy_set_header   Connection        "upgrade";
    }
}
```

---

## 3️⃣ Activar configuración y reiniciar Nginx

```bash
# Activar el nuevo sitio
sudo ln -sf /etc/nginx/sites-available/proportfolio.conf /etc/nginx/sites-enabled/proportfolio.conf

# Desactivar configuración por defecto
sudo rm -f /etc/nginx/sites-enabled/default

# Verificar y reiniciar
sudo nginx -t
sudo systemctl reload nginx
sudo systemctl restart nginx
```

---

## 4️⃣ Certificados SSL con Certbot

Instalar Certbot y habilitar HTTPS:

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d web.tudominio.com -d api.tudominio.com
```

Configurar en el proveedor DNS:

* **A** `web.tudominio.com` → IP pública de la EC2
* **A** `api.tudominio.com` → IP pública de la EC2

Volver a ejecutar Certbot si es necesario:

```bash
sudo certbot --nginx -d web.tudominio.com -d api.tudominio.com
```

---

## 📌 Notas finales

* Asegúrate de que los puertos 80 y 443 estén abiertos en el Security Group.
* Si usas dominios distintos a los de ejemplo, actualiza la configuración de Nginx.
* El build del frontend debe estar generado antes de levantar los contenedores para que `web` lo copie a `/var/www/web`.
* Para actualizaciones, basta con redeployar Docker Compose y reiniciar Nginx.

---

✅ Con esto tu infraestructura estará lista: **Terraform** para provisionar, **Docker Compose** para orquestar, y **Nginx** con **Certbot** para servir de forma segura tu aplicación.
