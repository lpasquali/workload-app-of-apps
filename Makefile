KUSTOMIZE ?= $(shell command -v kustomize >/dev/null 2>&1 && echo kustomize || echo "kubectl kustomize")

# Render all cluster overlays (optional local check)
.PHONY: render
render:
	@set -e; for d in clusters/*/; do \
	  test -f "$$d/kustomization.yaml" || continue; \
	  echo "== $$d =="; \
	  $(KUSTOMIZE) "$$d" >/dev/null && echo OK || exit 1; \
	done

.PHONY: render-example
render-example:
	$(KUSTOMIZE) clusters/capi-quickstart
