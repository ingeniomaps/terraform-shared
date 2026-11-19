# De dónde salen los módulos

La VM de `topology` sale de `instance/modules/vm-docker`, en este mismo repo. Así un solo tag de
terraform-shared versiona juntos `topology` y el módulo de la VM.

## Reglas (las verifica `scripts/check-module-sources.sh`)

1. Un `source` remoto fija un tag semver: `?ref=vX.Y.Z`. No se acepta rama (`ref=main`), commit suelto
   ni `source` sin `ref`.
2. Ningún `source` lleva credenciales en la URL.
3. Un `source` local tiene que existir.
4. `module "vm"` de `topology/main.tf` sale de `../instance/modules/vm-docker` (lista `PINNED_SOURCES`).
5. Los `*_override.tf` no se versionan.

Corre en `make check-sources` (incluido en `make lint`), en el pre-commit de lefthook y en CI
(`.github/workflows/module-sources.yml`). El que bloquea es el de CI, con el job `check` marcado como
requerido en la protección de `develop` y `main`.

## Proyectos que consumen terraform-shared

Siempre con tag (el número es de ejemplo):

```hcl
module "topology" {
  source = "git::https://github.com/ingeniomaps/terraform-shared.git//gcp/topology?ref=v2.1.0"
}
```

Sin `ref`, cada `terraform init` toma lo que haya en `main` en ese momento.

## Probar un cambio del módulo sin subirlo

Un override local. El proyecto consumidor tiene que tener `*_override.tf` en su `.gitignore`:

```hcl
# topology/main_override.tf  (en el proyecto consumidor)
module "topology" {
  source = "../../../terraform-shared/gcp/topology"
}
```

Terraform reemplaza el `source` sin tocar `main.tf`. Se borra al terminar la prueba.
