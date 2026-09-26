# Laboratorio de aprovisionamiento

Laboratorio enfocado en utilizar Terraform con buenas prácticas para aprovisionar, con Docker, un frontend (nginx), un backend (node) y una base de datos (PostgreSQL) en los ambientes **dev** y **qa**.

## Arquitectura

### Contenedores y puertos

| Ambiente | Contenedor | Tecnología | Puertos (externo:interno) |
|---|---|---|---|
| dev | `web-dev-1` | nginx | `4001:80` |
| dev | `api-dev-1` | node | `4002:3000` |
| dev | `bd-dev` | postgresql | `4003:5432` |
| qa | `web-qa-1` / `web-qa-2` | nginx | `5001:80` / `5011:80` |
| qa | `api-qa-1` / `api-qa-2` | node | `5002:3000` / `5012:3000` |
| qa | `bd-qa` | postgresql | `5003:5432` |

La réplica 1 usa el puerto del diagrama; cada réplica adicional suma 10 al puerto externo, porque en un mismo Docker local dos contenedores no pueden publicar el mismo puerto. El frontend llama al backend en su propio puerto + 1 (4001 → 4002, 5001 → 5002, 5011 → 5012).

### Redes

| Contenedor | `red-frontend-<ambiente>` | `red-backend-<ambiente>` |
|---|---|---|
| web (frontend) | Sí | No |
| api (backend) | Sí | Sí |
| bd (base de datos) | No | Sí |

El backend es el único contenedor conectado a las dos redes. Así, el frontend se comunica con el backend y el backend con la base de datos, pero **el frontend nunca se comunica con la base de datos**: no comparten red y ni siquiera puede resolver su nombre.

## Réplicas por ambiente

El frontend y el backend son replicables; la base de datos no.

| Componente | dev | qa | Justificación |
|---|---|---|---|
| Frontend (nginx) | 1 | 2 | **dev**: ambiente de desarrollo, prioriza rapidez y bajo consumo de recursos; una instancia basta para programar y probar. **qa**: debe parecerse más a producción; 2 réplicas permiten validar que el frontend funciona igual en varias instancias. |
| Backend (node) | 1 | 2 | **dev**: igual que el frontend, una instancia es suficiente. **qa**: 2 réplicas para comprobar que la API es *stateless* (no guarda estado local) y responde igual desde cualquier instancia antes de pasar a producción. |
| Base de datos (postgres) | 1 | 1 | Es un componente con estado; replicar PostgreSQL requiere configurar replicación, lo cual está fuera del alcance. Una sola instancia por ambiente. |

## Requisitos

- Docker Desktop (abierto y con el engine en ejecución)
- Terraform
- Git

Imágenes utilizadas:

```powershell
docker pull nginx:alpine
docker pull node:20-alpine
docker pull postgres:16-alpine
```

## Estructura del proyecto

```
/
├── README.md
├── .gitignore
├── app/
│   ├── frontend/
│   │   └── index.html
│   └── backend/
│       └── index.js
└── iac/
    ├── providers.tf
    ├── variables.tf
    ├── terraform.tfvars
    ├── network.tf
    ├── database.tf
    ├── backend.tf
    └── frontend.tf
```

Buenas prácticas aplicadas:

- **Un archivo `.tf` por recurso lógico**: `providers.tf` solo configura el provider y cada componente (redes, base de datos, backend, frontend) tiene su archivo con su imagen, contenedor y output.
- **Variables tipo mapa por ambiente** declaradas en `variables.tf` con valores en `terraform.tfvars` (por ejemplo `frontend_port = { dev = 4001, qa = 5001 }`). Al leer el código se ve cuántos ambientes existen.
- **Workspaces** para separar los ambientes: cada workspace tiene su propio estado, y el nombre del workspace se usa como parte del nombre de cada recurso para que dev y qa puedan convivir en el mismo Docker.

## Instrucciones de despliegue

Se trabaja **solo con los workspaces `dev` y `qa`**. No se usa el workspace `default` (los mapas no tienen esa clave).

```powershell
git clone https://github.com/dsmaurod-gif/prueba-01.git
cd prueba-01
cd iac
terraform init
```

Crear y desplegar dev:

```powershell
terraform workspace new dev
terraform plan
terraform apply            # confirmar con: yes
```

Crear y desplegar qa:

```powershell
terraform workspace new qa
terraform plan
terraform apply            # confirmar con: yes
```

Para ver los workspaces y cambiar a uno ya creado:

```powershell
terraform workspace list
terraform workspace select dev
```

## Verificación

```powershell
docker ps --format "table {{.Names}}\t{{.Ports}}"
docker network ls --filter name=red-

# frontend -> backend (misma red): responde JSON
docker exec web-dev-1 wget -qO- http://api-dev-1:3000/

# backend -> base de datos (misma red): responde "conectado"
docker exec api-dev-1 wget -qO- http://localhost:3000/db

# frontend -> base de datos (redes distintas): debe fallar con "bad address"
docker exec web-dev-1 wget -qO- -T 3 http://bd-dev:5432
```

En el navegador:

- dev: http://localhost:4001
- qa: http://localhost:5001 y http://localhost:5011

Cada página muestra el ambiente, la instancia del backend que respondió y el estado de la base de datos. Para probar por consola en PowerShell usar `curl.exe` (no `curl`).

## Destruir los ambientes

`terraform destroy` elimina solo el ambiente del workspace activo:

```powershell
terraform workspace select dev
terraform destroy          # confirmar con: yes

terraform workspace select qa
terraform destroy          # confirmar con: yes
```

## Nota de seguridad

`terraform.tfvars` se incluye en el repositorio solo para fines del laboratorio, para que el proyecto funcione al clonarlo. En un entorno real `db_password` no se versionaría: se inyectaría desde el pipeline.

## Convención de commits

Se usa [Conventional Commits](https://www.conventionalcommits.org/):

- `feat`: nueva funcionalidad o recurso
- `fix`: corrección de un error
- `docs`: cambios en la documentación
- `chore`: tareas de mantenimiento (por ejemplo, `.gitignore`)
