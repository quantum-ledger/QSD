Integration tests were moved into the Go module at **`QSD/source/tests/`** so `go test ./...` from `QSD/source` includes them.

```bash
cd QSD/source
export QSD_METRICS_REGISTER_STRICT=1
CGO_ENABLED=0 go test ./... ./tests/... -short
```
