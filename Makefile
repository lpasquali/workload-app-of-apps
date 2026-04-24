KUSTOMIZE ?= $(shell command -v kustomize >/dev/null 2>&1 && echo kustomize || echo "kubectl kustomize")

# All Kustomize roots under examples/ and clusters/ (if you add per-cluster folders).
.PHONY: render
render: render-base render-examples
	@set -e; for d in clusters/*/; do \
	  test -f "$$d/kustomization.yaml" || continue; \
	  echo "== $$d =="; \
	  $(KUSTOMIZE) "$$d" >/dev/null && echo OK || exit 1; \
	done

.PHONY: render-base
render-base:
	@echo "== base =="
	@$(KUSTOMIZE) base >/dev/null && echo OK

.PHONY: render-examples
render-examples:
	@set -e; for d in examples/*/; do \
	  test -f "$$d/kustomization.yaml" || continue; \
	  echo "== $$d =="; \
	  $(KUSTOMIZE) "$$d" >/dev/null && echo OK || exit 1; \
	done

# Quick check of the no-overlay path (full stack).
.PHONY: render-default
render-default:
	$(KUSTOMIZE) examples/default
