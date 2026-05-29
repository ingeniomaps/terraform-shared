# Seguridad — pendientes y decisiones del equipo

**Contexto**: auditoría de seguridad + arquitectura sobre `gcp/` (2026-05-29). El
proyecto es **compartido y multi-proyecto** y corre en producción. Lo accionable
del lado del código ya se aplicó; lo que queda **depende de datos o decisiones
del equipo** (no se puede resolver desde el código sin esos inputs).

> Regla del proyecto: `terraform-shared` es genérico. Lo único que un consumidor
> cambia al adoptarlo es el **nombre del bucket** de estado. No agregar nada
> específico de un proyecto acá.

---

## ✅ Ya aplicado (hardening)

| Cambio | Dónde |
| --- | --- |
| SSH directo `0.0.0.0/0` → gateado (`enable_direct_ssh`, default off) + validación anti-`0.0.0.0/0` | `modules/network/firewall/allow.tf` |
| GKE Shielded Nodes (Secure Boot + integrity) on; Binary Authorization opt-in | `instance/modules/gke/{cluster,node_pool}.tf` |
| Workload Identity: ya no `[default/default]`, parametrizado + validación | `modules/security/gke/gke_workload_identity.tf` |
| Secret Manager opt-in para secretos de microservicios (no embeber `.env` en metadata) | `instance/modules/vm-docker/` (`secret_id` opcional) |
| Split del god-module: org-policies + VPC-SC a state propio | `shared-infra/security-global/` |
| `ci_cd_writer` least-privilege (sin `instanceAdmin.v1` ni `serviceAccountUser`) | `modules/security/iam/iam_service_accounts.tf` |

---

## 📋 Pendiente — requiere decisión o datos del equipo

### 1. Endurecer la postura de prod (org-policies + VPC-SC)
Hoy `enable_org_policies`, `enable_vpc_service_controls` y `enforce_prod_hardening`
están en `false` (postura transicional del prod mono con HTTP directo). Ya no hay
conflicto para prenderlos (viven en `security-global`, singleton del proyecto).
- **Qué**: poner los tres en `true` y migrar a Load Balancer + `enable_restricted_http`.
- **Cuándo**: cuando prod pase de la VM mono a LB / k8s real.
- **Dónde**: `shared-infra/security-global/terraform.tfvars`.

### 2. Acotar el egress de VPC Service Controls
La `egress_policies` permite hoy `ANY_IDENTITY` → `storage.googleapis.com` con
`method="*"`. No se puede acotar desde el código: depende del **inventario real de
salidas** que necesitan los workloads (pull de AR/GCS, APIs externas).
- **Qué**: reemplazar `ANY_IDENTITY` por las SAs concretas y acotar `method_selectors`/`resources`.
- **Cuándo**: al prender VPC-SC, con la lista de egress legítimo en mano.
- **Dónde**: `modules/security/security/vpc_service_controls.tf`.

### 3. Canales de notificación de alertas
Las alertas existen pero `alert_notification_channels = []` (no hay canales aún),
así que **no notifican a nadie** — incluido uso de break-glass y creación de SA keys.
- **Qué**: poblar con IDs reales (PagerDuty/Slack/email); evaluar habilitar
  `iam_policy_changes`/`firewall_rule_changes` también en stg/qa.
- **Cuándo**: cuando exista un canal de on-call.
- **Dónde**: tfvars del entorno (`alert_notification_channels`), `modules/security/logging/`.

### 4. `gke_admin` SA — roles amplios (latente)
`gke_admin_sa` tiene `container.admin` + `compute.networkAdmin` + `serviceAccountUser`
a nivel proyecto. Hoy **no se crea** (`create_admin_sa=false` en todos los entornos).
- **Qué**: si se activa, acotar `serviceAccountUser` con condición IAM a la SA específica.
- **Cuándo**: antes de poner `create_admin_sa=true`.
- **Dónde**: `modules/security/gke/gke_admin_sa.tf`.

### 5. Supply chain del Artifact Registry
El repo global se crea con `immutable_tags=false` y topology deploya por tag mutable
(`:latest`/`:dev`). Un push erróneo/malicioso al tag se propaga al próximo boot.
- **Qué**: `immutable_tags=true` y deployar por **digest** o tag versionado; habilitar
  el análisis de vulnerabilidades de Artifact Registry; (opcional) Binary Authorization.
- **Dónde**: `bootstrap/global/main.tf`, `topology` (`default_image_tag`).

### 6. CI gate de IaC
`tfsec`/`checkov` corren best-effort (`|| true`, solo si están instalados localmente).
- **Qué**: pipeline (Cloud Build/GitHub Actions) que falle ante findings High.
- **Cuándo**: junto con el workflow de `terraform plan` (ver `TODO.md` #1).

---

## ⚙️ Notas operativas / migración

- **Orden de apply**: `bootstrap/global` → entornos. El binding de IAM del registry
  por entorno requiere que el repo lo haya creado bootstrap antes. Y `security-global`
  se aplica aparte (una vez por proyecto).
- **Consumidores ya aplicados (p.ej. roax)**: el split del god-module y el cambio de
  dueño del Artifact Registry requieren **migración de estado** (`terraform state mv/rm`
  + re-aplicar `security-global`). Para un proyecto nuevo (sin `apply` previo) no aplica.
- **`terraform validate`**: los cambios se verificaron con `terraform fmt` (sintaxis);
  falta correr `validate`/`plan` contra providers reales.
- **Higiene menor**: `data.google_project.current` quedó sin uso en
  `modules/security/data.tf` tras el split — se puede limpiar.

---

## 🔗 Específico de cada proyecto consumidor (NO va en `terraform-shared`)

- **Secretos en metadata del startup**: si un consumidor inyecta tokens en el
  `metadata_startup_script` (p.ej. un token de Cloudflare para el edge), moverlos a
  Secret Manager y leerlos en runtime — el mismo patrón que `vm-docker` ya soporta
  con `secret_id` para microservicios. Se resuelve en el repo del consumidor, no acá.
