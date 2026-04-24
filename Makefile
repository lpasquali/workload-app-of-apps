# Render all cluster overlays (optional local check; requires kustomize v5+)
.PHONY: render
render:
	@set -e; for d in clusters/*/; do \
	  test -f "$$d/kustomization.yaml" || continue; \
	  echo "== $$d =="; \
	  kustomize build "$$d" >/dev/null && echo OK || exit 1; \
	done

.PHONY: render-example
render-example:
	kustomize build clusters/capi-quickstart
