#!/bin/bash
# This script sets up a single node cluster (SNC) which was created by 
# the Cloud Installer (https://cloud.redhat.com/openshift/assisted-installer/clusters/~new)
#
# First, you have to install the SNC in your network. Then you are logging into it with kubeadmin
# THEN you can let this script run, which will create PVs in the VM and configures the 
# internal registry to use one of the PVs for storing everything.
# 
# Please see README.MD for more details.
#
set -e -u -o pipefail

declare HOST=192.168.2.23 # set it to your IP
declare NUM_PVs=30

declare -r SCRIPT_DIR=$(cd -P $(dirname $0) && pwd)
declare COMMAND="help"


valid_command() {
  local fn=$1; shift
  [[ $(type -t "$fn") == "function" ]]
}

info() {
    printf "\n# INFO: $@\n"
}

err() {
  printf "\n# ERROR: $1\n"
  exit 1
}

while (( "$#" )); do
  case "$1" in
    persistant-volumes|registry|operators|ci|create-users|all)
      COMMAND=$1
      shift
      ;;
    -h|--host-name)
      HOST=$2
      shift 2
      ;;
    --)
      shift
      break
      ;;
    -*|--*)
      err "Error: Unsupported flag $1"
      ;;
    *) 
      break
  esac
done


function generate_pv() {
  local pvdir="${1}"
  local name="${2}"
cat <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${name}
  labels:
    volume: ${name}
spec:
  capacity:
    storage: 100Gi
  accessModes:
    - ReadWriteOnce
    - ReadWriteMany
    - ReadOnlyMany
  hostPath:
    path: ${pvdir}
  persistentVolumeReclaimPolicy: Recycle
EOF
}

function setup_pv_dirs() {
    local dir="${1}"
    local count="${2}"

    ssh core@$HOST 'sudo bash -x -s' <<EOF
    for pvsubdir in \$(seq -f "pv%04g" 1 ${count}); do
        mkdir -p "${dir}/\${pvsubdir}"
    done
    if ! chcon -R -t svirt_sandbox_file_t "${dir}" &> /dev/null; then
        echo "Failed to set SELinux context on ${dir}"
    fi
    chmod -R 770 ${dir}
EOF
}

function create_pvs() {
    local pvdir="${1}"
    local count="${2}"

    setup_pv_dirs "${pvdir}" "${count}"

    for pvname in $(seq -f "pv%04g" 1 ${count}); do
        if ! oc get pv "${pvname}" &> /dev/null; then
            generate_pv "${pvdir}/${pvname}" "${pvname}" | oc create -f -
        else
            echo "persistentvolume ${pvname} already exists"
        fi
    done
}

command.help() {
  cat <<-EOF
  Provides some functions to make an OpenShift Single Node Cluster usable
  Usage:
      config-snc.sh [command] [options]
  
  Example:
      snc all -h 192.168.2.23
  
  COMMANDS:
      persistant-volumes             Setup 30 persistant volumes on SNC host
      registry                       Setup internal image registry to use a PVC and accept requests
      operators                      Install gitops and pipeline operators
      ci                             Install Nexus and Gogs in a ci namespace
      create-users                   Creates two users: admin/admin123 and developer/developer
      all                            call all modules
      help                           Help about this command

  OPTIONS:
      -h --host-name                 SNC host name
      
EOF
}

command.persistant-volumes() {
    create_pvs "/mnt/pv-data" $NUM_PVs
}

command.registry() {
    # Apply registry pvc to bound with pv0001
    cat > /tmp/claim.yaml <<EOF 
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: snc-image-registry-storage	
  namespace: openshift-image-registry
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 100Gi
  selector:
    matchLabels:
      volume: "pv0001"
EOF

    cat /tmp/claim.yaml | oc apply -f -
    
    # Add registry storage to pvc
    oc patch config.imageregistry.operator.openshift.io/cluster --patch='[{"op": "add", "path": "/spec/storage/pvc", "value": {"claim": "snc-image-registry-storage"}}]' --type=json
    
    # Remove emptyDir as storage for registry
    oc patch config.imageregistry.operator.openshift.io/cluster --patch='[{"op": "remove", "path": "/spec/storage/emptyDir"}]' --type=json

    # set registry to Managed in order to make use of it!
    oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"managementState":"Managed"}}'
}

command.operators() {
    cat << EOF > /tmp/operators.yaml 
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-gitops
  namespace: openshift-operators 
spec:
  channel: stable 
  name: openshift-gitops-operator
  source: redhat-operators 
  sourceNamespace: openshift-marketplace 
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-pipelines
  namespace: openshift-operators 
spec:
  channel: stable 
  name: openshift-pipelines-operator-rh
  source: redhat-operators 
  sourceNamespace: openshift-marketplace 

EOF

    cat /tmp/operators.yaml | oc apply -f -
}

command.ci() {
    oc get ns ci 2>/dev/null  || {
      info "Creating CI project" 
      oc new-project ci > /dev/null

      oc apply -f $SCRIPT_DIR/support/nexus.yaml --namespace ci
      oc apply -f $SCRIPT_DIR/support/gogs.yaml --namespace ci
      GOGS_HOSTNAME=$(oc get route gogs -o template --template='{{.spec.host}}')
      info "Gogs Hostname: $GOGS_HOSTNAME"

      info "Initiatlizing git repository in Gogs and configuring webhooks"
      sed "s/@HOSTNAME/$GOGS_HOSTNAME/g" support/gogs-configmap.yaml | oc apply --namespace ci -f - 
      oc rollout status deployment/gogs --namespace ci
      oc create -f support/gogs-init-taskrun.yaml --namespace ci
    }
}

command.create-users() {
    oc get secret htpass-secret -n openshift-config 2>/dev/null || {
      info "No htpass provider availble, creating new one"
      # create a secret
      oc create secret generic htpass-secret --from-file=htpasswd=$SCRIPT_DIR/support/htpasswd -n openshift-config

      # create the CR
      oc apply -f $SCRIPT_DIR/support/htpasswd-cr.yaml -n openshift-config
    } && {
      info "Changing existing htpass-secret file to add devel/devel and admin/admin123"
      oc get secret htpass-secret -ojsonpath={.data.htpasswd} -n openshift-config | base64 --decode > /tmp/users.htpasswd
      
      info "Existing users"
      cat /tmp/users.htpasswd 
      echo >> /tmp/users.htpasswd

      htpasswd -bB /tmp/users.htpasswd admin admin123
      htpasswd -bB /tmp/users.htpasswd devel devel

      cat /tmp/users.htpasswd

      oc create secret generic htpass-secret --from-file=htpasswd=/tmp/users.htpasswd --dry-run=client -o yaml -n openshift-config | oc replace -f -

    }

    # we want admin be cluster-admin
    oc adm policy add-cluster-role-to-user cluster-admin admin
}


command.all() {
    command.persistant-volumes
    command.registry
    command.create-users
    command.operators
    command.ci
}

main() {
  local fn="command.$COMMAND"
  valid_command "$fn" || {
    err "invalid command '$COMMAND'"
  }

  cd $SCRIPT_DIR
  $fn
  return $?
}

main

