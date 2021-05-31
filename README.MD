# openshift-config
This is a script which has some configuration modules for a fresh and clean OpenShift installation. If you've been using 
the Single Node OpenShift installation, you need some persistant volumens and you need to make the internal registry
able to store your images. 

This is what the script does right now:

- Creating 30 persistant volumens (locally on the OpenShift VM)
- Configuring the internal registry to be able to store images
- Installing some operators (namely gitops and pipelines) for demo purposes
- Setting up a 'ci' namespace with nexus and Gogs ready to use

## Usage
### persistant-volumes
```bash
$> ./config-snc.sh persistant-volumes -h 192.168.2.23
```

This creates 30 volumens within /mnt/pv-data on the SNO host at 192.168.2.23. Make sure, you're able to ssh into the machine. By default you should be able to do so without password, as the installer has your public key. 

```bash
$> ssh core@192.168.2.23
```

### registry
```bash
$> ./config-snc.sh registry 
```

This switches the internal registry to "Managed" and binds it to a PV called pv0001. For this module, you must be logged in as kube:admin in your cluster. 

### operators
```bash
$> ./config-snc.sh operators
```

This installs the gitops and the pipelines operators. Please make sure to be logged into the openshift instance as cluster-admin. And you already should have persistant volumes available.

### ci
```bash
$> ./config-snc.sh ci
```

This installs a nexus and Gogs into a newly created namespace called ci. After that it prints out the access to both instances. By default, we are using

Nexus: admin/admin123
Gogs: gogs/gogs

