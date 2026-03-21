# TODO - Mejoras Opcionales

**Estado**: ✅ Production-Ready. Las mejoras listadas son opcionales.

**Contexto**: Este proyecto es compartido entre múltiples microservicios. Cada proyecto lo consume como módulo.

## Pendientes (aplicar cuando corresponda)

### 1. Terraform Plan en PRs
- [ ] Workflow de GitHub Actions que ejecute `terraform plan` en PRs que toquen `*.tf`
- [ ] Comentar el plan en el PR para revisión
- **Cuándo**: Después del primer `terraform apply` (necesita infra contra qué planear)

### 2. Budget Alerts
- [ ] Configurar alertas de costos en GCP por proyecto
- [ ] Documentar costos estimados por ambiente
- **Cuándo**: Después de 1 mes de operación (necesita datos reales de billing)

### 3. Versionado de Módulos
- [ ] Tags semánticos para módulos (bootstrap, shared-infra, topology, gke, vm-docker, etc.)
- [ ] Consumir módulos por versión: `source = "git::https://...?ref=v1.2.0"`
- [ ] Changelog por release
- **Cuándo**: Cuando el segundo microservicio consuma este proyecto

## Completado

- ✅ CI/CD con GitHub Actions (configurado en proyectos consumidores)
- ✅ Validación de formato (terraform fmt en lint-staged)
- ✅ Seguridad (gitleaks, Trivy)
- ✅ Notificaciones (Slack en deploy/rollback)
- ✅ Bootstrap simplificado (un solo bucket + artifact registry)
- ✅ Documentación completa
