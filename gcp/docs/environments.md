# Gestión de Entornos

## Entornos Existentes

### Shared Infrastructure

- **`shared-infra/environments/development/`**
  - ✅ Configurado y funcional
  - Backend configurado en `main.tf` (revisa el archivo para ver bucket y prefix específicos)

### Terraform State Buckets

- **`terraform-state/environments/staging/`** - Bucket de estado para staging
- **`terraform-state/environments/production/`** - Bucket de estado para producción
- **`terraform-state/global/`** - Bucket de estado global

## Crear Entornos Adicionales

Si necesitas crear entornos adicionales en `shared-infra/environments/`:

### Estructura Recomendada

```
shared-infra/environments/
├── development/
│   ├── main.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   └── tfvars.example
├── staging/
│   └── [misma estructura]
└── production/
    └── [misma estructura]
```

### Pasos

1. **Copiar estructura de development**

   ```bash
   cp -r shared-infra/environments/development shared-infra/environments/staging
   cp -r shared-infra/environments/development shared-infra/environments/production
   ```

2. **Ajustar backends**

   - Edita el `main.tf` de cada ambiente para configurar el bucket y prefix apropiados
   - Ejemplo: `bucket = "TU-PROYECTO-terraform-state"`, `prefix = "stg/shared/terraform"`

3. **Ajustar variables por ambiente**
   - Modificar `terraform.tfvars` con valores apropiados
   - Actualizar `project_id`, `env`, etc.

### Diferencias Esperadas entre Entornos

**⚠️ IMPORTANTE**: Development y Staging NO son iguales. Staging es más parecido a producción y sirve para validar configuraciones antes de desplegar a producción.

| Configuración                      | Development                         | Staging                                 | Production              |
| ---------------------------------- | ----------------------------------- | --------------------------------------- | ----------------------- |
| **Propósito**                      | Desarrollo activo y experimentación | Validación pre-producción               | Producción real         |
| `project_id`                       | `*-dev-*`                           | `*-stg-*` o `*-staging-*`               | `*-prod-*`              |
| `env`                              | `"dev"`                             | `"stg"`                                 | `"prod"`                |
| **Seguridad**                      |
| `enable_dev_reader`                | `true`                              | `false`                                 | `false`                 |
| `enable_vpc_service_controls`      | `false`                             | `false` (opcional: `true` para testing) | `true`                  |
| `break_glass_max_session_duration` | `7200` (2 horas)                    | `3600` (1 hora)                         | `3600` (1 hora)         |
| **Red**                            |
| `enable_gke`                       | Opcional (puede ser `false`)        | `true` (si se usa en prod)              | `true`                  |
| `enable_public_http`               | Opcional (puede ser `false`)        | `true`                                  | `true`                  |
| `enable_restricted_http`           | Opcional (puede ser `true`)         | `false`                                 | `false`                 |
| **Estado de Terraform**            |
| `prevent_destroy` (buckets)        | `false`                             | `true`                                  | `true`                  |
| `retention_period_days`            | `30`                                | `60`                                    | `90`                    |
| `retention_locked`                 | `false`                             | `true`                                  | `true`                  |
| **Backend prefix**                 | `dev/shared/terraform`              | `stg/shared/terraform`                  | `prod/shared/terraform` |

### Filosofía de los Ambientes

**Development (Desarrollo)**:

- 🎯 **Propósito**: Desarrollo activo, experimentación, testing de features
- ✅ **Flexibilidad**: Configuración permisiva para facilitar desarrollo
- ✅ **Acceso**: Desarrolladores tienen acceso directo
- ⚠️ **Estabilidad**: Menos crítica, puede cambiar frecuentemente
- 💰 **Costos**: Puede usar recursos más económicos

**Staging (Pre-producción)**:

- 🎯 **Propósito**: Validar configuraciones y cambios antes de producción
- ✅ **Similitud con Prod**: Debe ser lo más parecido a producción posible
- ✅ **Testing**: Validar integraciones, performance, configuración
- ⚠️ **Estabilidad**: Más estable que dev, similar a prod
- 💰 **Costos**: Similar a producción para pruebas realistas

**Production (Producción)**:

- 🎯 **Propósito**: Carga de trabajo real, usuarios finales
- ✅ **Seguridad**: Máxima seguridad y controles
- ✅ **Estabilidad**: Crítica, cambios controlados
- ⚠️ **Restricciones**: Máximas restricciones y validaciones
- 💰 **Costos**: Optimizado para producción

## Notas Importantes

- **Development ≠ Staging**: Staging debe ser similar a producción para validar cambios
- **Flujo típico**: Development → Staging → Production
- Los entornos en `terraform-state/environments/` son solo para gestionar los buckets de estado
- Los entornos en `shared-infra/environments/` son para la infraestructura compartida real
- Puedes empezar con solo `development/` y agregar otros cuando los necesites

### ¿Cuándo Crear Staging?

**Sí, crea staging si**:

- ✅ Tienes un proceso de releases estructurado
- ✅ Necesitas validar cambios antes de producción
- ✅ Quieres probar configuraciones de producción de forma segura
- ✅ Tienes integraciones críticas que necesitan testing

**Puedes saltarte staging si**:

- ✅ Solo tienes un equipo pequeño
- ✅ Los cambios se despliegan directamente a producción con testing automatizado
- ✅ No necesitas un ambiente intermedio de validación

### 💰 Consideraciones de Costos: Staging vs Producción

**Pregunta común**: ¿Debo tener GKE en staging si lo tengo en producción? ¿O es mejor usar solo VMs para reducir costos?

#### Opción 1: Staging con Misma Arquitectura que Producción (Recomendado)

**Ventajas**:

- ✅ **Validación real**: Detectas problemas de configuración antes de producción
- ✅ **Testing de integración**: Pruebas reales de Kubernetes, networking, etc.
- ✅ **Menos sorpresas**: Si funciona en staging, funcionará en producción
- ✅ **CI/CD realista**: Pipeline de despliegue idéntico
- ✅ **Debugging más fácil**: Problemas de infraestructura se detectan antes

**Desventajas**:

- ❌ **Mayor costo**: GKE en staging aumenta costos
- ❌ **Mantenimiento**: Dos clusters que mantener

**Recomendación**: **Sí, usa la misma arquitectura** si:

- Tienes presupuesto para staging
- La aplicación es crítica
- Necesitas validar configuraciones complejas
- El costo de un error en producción es alto

#### Opción 2: Staging Simplificado (Solo VMs)

**Ventajas**:

- ✅ **Menor costo**: Solo pagas por VMs
- ✅ **Más simple**: Menos recursos que mantener
- ✅ **Suficiente para**: Testing funcional básico

**Desventajas**:

- ❌ **No valida arquitectura real**: Problemas de GKE no se detectan
- ❌ **Diferencias de configuración**: Staging y prod son diferentes
- ❌ **Riesgo en producción**: Cambios no probados en arquitectura real
- ❌ **CI/CD diferente**: Pipeline puede no reflejar producción

**Recomendación**: **Usa solo VMs** si:

- Presupuesto muy limitado
- Aplicación simple que no depende de características de GKE
- Puedes validar GKE en desarrollo antes de producción
- El riesgo de problemas en producción es aceptable

#### Opción 3: Staging Reducido (GKE más pequeño)

**Mejor de ambos mundos**:

- ✅ **Misma arquitectura**: GKE pero con menos nodos/recursos
- ✅ **Menor costo**: Cluster más pequeño que producción
- ✅ **Validación real**: Detecta problemas de configuración

**Configuración típica**:

- **Producción**: 3+ nodos, auto-scaling, alta disponibilidad
- **Staging**: 1-2 nodos, sin auto-scaling, suficiente para testing

**Recomendación**: **Esta es la mejor opción** para la mayoría de casos.

### Ejemplo de Configuración para Staging

#### Opción A: Staging con GKE (Recomendado)

```hcl
# shared-infra/environments/staging/terraform.tfvars
project_id = "mi-proyecto-stg-123456"
workspace  = "platform"
env        = "stg"
region     = "us-central1"

# Security - Similar a producción pero sin VPC Service Controls
enable_dev_reader           = false
enable_vpc_service_controls = false  # Opcional: true para testing
break_glass_max_session_duration = 3600

# Network - Misma arquitectura que producción
vm_subnet_cidr = "10.0.0.0/24"
enable_gke     = true  # Misma arquitectura que producción

gke_subnet_cidr    = "10.0.10.0/24"
gke_pods_cidr      = "10.1.0.0/16"
gke_services_cidr  = "10.2.0.0/16"
gke_master_cidr    = "172.16.0.0/28"

# HTTP Access - Público (como producción)
enable_public_http     = true
enable_restricted_http = false
```

**Nota**: El cluster GKE en staging puede ser más pequeño (menos nodos, menos recursos) pero con la misma configuración de red y seguridad.

#### Opción B: Staging Simplificado (Solo VMs)

```hcl
# shared-infra/environments/staging/terraform.tfvars
project_id = "mi-proyecto-stg-123456"
workspace  = "platform"
env        = "stg"
region     = "us-central1"

# Security
enable_dev_reader           = false
enable_vpc_service_controls = false
break_glass_max_session_duration = 3600

# Network - Sin GKE (más económico)
vm_subnet_cidr = "10.0.0.0/24"
enable_gke     = false  # Sin GKE para reducir costos

# HTTP Access - Público (como producción)
enable_public_http     = true
enable_restricted_http = false
```

**⚠️ Advertencia**: Con esta configuración, no validarás:

- Configuración de GKE
- Networking de pods/services
- Integraciones específicas de Kubernetes
- CI/CD pipeline completo

### 📊 Matriz de Decisión

| Escenario                | Recomendación           | Razón                                          |
| ------------------------ | ----------------------- | ---------------------------------------------- |
| **Aplicación crítica**   | GKE en staging          | El costo de errores en prod > costo de staging |
| **Presupuesto limitado** | Solo VMs en staging     | Validar funcionalidad básica es suficiente     |
| **Aplicación simple**    | Solo VMs en staging     | No depende de características avanzadas de GKE |
| **Equipo grande**        | GKE en staging          | Múltiples desarrolladores necesitan validación |
| **CI/CD complejo**       | GKE en staging          | Pipeline debe ser idéntico a producción        |
| **Presupuesto medio**    | GKE reducido en staging | Balance entre costo y validación               |

### 💡 Mejores Prácticas

1. **Empieza simple**: Si el presupuesto es limitado, empieza con VMs y escala a GKE cuando sea necesario

2. **GKE reducido**: Si decides usar GKE en staging, hazlo más pequeño:

   - 1-2 nodos en lugar de 3+
   - Máquinas más pequeñas (e2-small en lugar de e2-medium)
   - Sin auto-scaling agresivo
   - Menos réplicas de aplicaciones

3. **Validación incremental**:

   - Desarrollo: VMs (más barato, más flexible)
   - Staging: GKE reducido (validación real, costo controlado)
   - Producción: GKE completo (alta disponibilidad, performance)

4. **Monitoreo de costos**: Usa Cloud Billing para comparar costos de staging vs producción y ajusta según necesidad

### 📈 Estimación de Costos (Aproximada)

**Opción 1: Solo VMs en staging**

- 2-3 VMs e2-small: ~$30-50/mes
- Total staging: ~$50-100/mes

**Opción 2: GKE reducido en staging**

- Cluster GKE (1-2 nodos e2-small): ~$100-150/mes
- Total staging: ~$150-200/mes

**Opción 3: GKE completo en staging**

- Cluster GKE (3+ nodos): ~$300-500/mes
- Total staging: ~$400-600/mes

**Producción típica**:

- Cluster GKE (3+ nodos, auto-scaling): ~$500-2000+/mes
- Depende del tamaño y tráfico

**Conclusión**: El costo adicional de GKE en staging (~$100-150/mes) generalmente vale la pena para evitar problemas costosos en producción.
