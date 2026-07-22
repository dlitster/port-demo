# Development Environment Chart

This chart creates policy resources and a one-replica sample HTTP workload for a
development environment. It requires root `owner`, `service`, `expiration`,
`profile`, and `image` values. `service` is a DNS-safe catalog service
identifier.

The workload's requests and limits are fixed by the selected `small`, `medium`,
or `large` profile. Selector labels use chart identity, owner, and service only;
profile and expiration are intentionally excluded so a profile or expiration
change does not replace the Deployment selector.

Set `httpService.enabled=true` to create a Service on `httpService.port`. Its
default type is `ClusterIP`; set `httpService.type` to `NodePort` or
`LoadBalancer` when needed. All namespaced resources use the Helm release
namespace.

```sh
helm upgrade --install demo ./charts/development-environment \
  --namespace demo --create-namespace \
  --set owner=platform-team \
  --set-string service=example-service \
  --set expiration=2099-01-01T00:00:00Z \
  --set profile=small \
  --set image=nginx:1.27-alpine \
  --set httpService.enabled=true
```
