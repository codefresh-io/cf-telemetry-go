VERSION=v0.1.0

.PHONY: all
all: build

.PHONY: lint
lint: golangci-lint
	$(GOLANGCI_LINT) run

.PHONY: lint-fix
lint-fix: golangci-lint
	$(GOLANGCI_LINT) run --fix

.PHONY: test
test:
	go test ./... -v

## Location to install dependencies to
LOCALBIN ?= $(shell pwd)/bin
$(LOCALBIN):
	mkdir -p $(LOCALBIN)

## Tool Binaries
GOLANGCI_LINT = $(LOCALBIN)/golangci-lint
MOCKERY = $(LOCALBIN)/mockery

## Tool Versions
GOLANGCI_LINT_VERSION ?= v2.6.2
MOCKERY_VERSION ?= v3.6.1

.PHONY: golangci-lint
golangci-lint: $(GOLANGCI_LINT)-$(GOLANGCI_LINT_VERSION) ## Download golangci-lint locally if necessary.
$(GOLANGCI_LINT)-$(GOLANGCI_LINT_VERSION): $(LOCALBIN)
	$(call go-install-tool,$(GOLANGCI_LINT),github.com/golangci/golangci-lint/v2/cmd/golangci-lint,$(GOLANGCI_LINT_VERSION))

.PHONY: mock
mock: mockery ## Generate mocks for interfaces
	$(MOCKERY)

# Generate mock struct from interface
# example: make mock PKG=./pkg/runtime NAME=Runtime
.PHONY: mockery
mockery: $(MOCKERY) ## Download mockery locally if necessary.
$(MOCKERY):
	$(call go-install-tool,$(MOCKERY),github.com/vektra/mockery/v3,$(MOCKERY_VERSION))

# go-install-tool will 'go install' any package with custom target and name of binary, if it doesn't exist
# $1 - target path with name of binary
# $2 - package url which can be installed
# $3 - specific version of package
define go-install-tool
@[ -f "$(1)-$(3)" ] || { \
set -e; \
package=$(2)@$(3) ;\
echo "Downloading $${package}" ;\
rm -f $(1) || true ;\
GOBIN=$(LOCALBIN) go install $${package} ;\
mv $(1) $(1)-$(3) ;\
} ;\
ln -sf $(1)-$(3) $(1)
endef
