# Terraform Shared Infrastructure

Módulos compartidos de infraestructura. Reutilizable por cualquier proyecto.

## Proveedores

| Proveedor | Directorio | Contenido |
|-----------|-----------|-----------|
| **GCP** | [`gcp/`](gcp/) | Bootstrap, shared-infra, GKE, VM modules, topology |

## Estructura

```
terraform-shared/
├── gcp/
│   ├── bootstrap/        Bucket de state + artifact registry (paso 1)
│   ├── shared-infra/     Network, security, IAM por ambiente (paso 2)
│   ├── topology/         Módulo vm-topology (N VMs con servicios)
│   ├── instance/modules/ GKE, vm-base, vm-docker, vm-artifact
│   ├── docs/             Documentación completa
│   ├── scripts/          Scripts de automatización
│   └── Makefile          Comandos de operación
└── README.md             Este archivo
```

## Uso

Ver [`gcp/README.md`](gcp/docs/getting-started.md) para la guía completa.

```bash
cd gcp/bootstrap/global
cp tfvars.example terraform.tfvars   # Poner project_id
terraform init && terraform apply    # Crear bucket + artifact registry
```
