# Module: mesh
```bash
$> ./setup.sh mesh
```
Installs Red Hat OpenShift ServiceMesh and adds the grumpycat application to the mesh.

This can be uninstalled by executing 
```bash
$> oc delete -k config/mesh
```

If you want to add other namespaces to the mesh, please edit the file `config/mesh/sm-members.yaml`. Please also note, that - in order to let the mesh inject the sidecar - you need to add the following annotation to the `Deployment` of a - well - deployment:

```yaml
spec:
  template:
    metadata:
      annotations:  
        sidecar.istio.io/inject: 'true'
```
