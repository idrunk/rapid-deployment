#!/bin/bash

source "`dirname "$0"`/../.libs/env.sh"
source "$LIB_DIR/gui.sh"
source "$LIB_DIR/lib.sh"
source "$SYSTEM_DIR/lib.sh"


deploy_node_exporter() {
    rewrite_to "$INSTL_SUBJ_DIR/exporters/docker-node-exporter/docker-compose.yml" "$SUBJ_RES_DIR/exporters/docker-node-exporter/docker-compose.yml"
    docker compose -f "$INSTL_SUBJ_DIR/exporters/docker-node-exporter/docker-compose.yml" up -d
}

undeploy_node_exporter() {
    docker compose -f "$INSTL_SUBJ_DIR/exporters/docker-node-exporter/docker-compose.yml" down
}

deploy_kube_node_exporter() {
    rewrite_to "$INSTL_SUBJ_DIR/exporters/kube-node-exporter/deployment.yml" "$SUBJ_RES_DIR/exporters/kube-node-exporter/deployment.yml"
    kubectl apply -f "$INSTL_SUBJ_DIR/exporters/kube-node-exporter/deployment.yml"
}

undeploy_kube_node_exporter() {
    kubectl delete -f "$INSTL_SUBJ_DIR/exporters/kube-node-exporter/deployment.yml"
}

deploy_kube_state_metrics() {
    /bin/cp/ -rfv "$SUBJ_RES_DIR/exporters/kube-state-metrics" "$INSTL_SUBJ_DIR/exporters/kube-state-metrics"
    kubectl apply -k "$INSTL_SUBJ_DIR/exporters/kube-state-metrics"
}

undeploy_kube_state_metrics() {
    kubectl delete -k "$INSTL_SUBJ_DIR/exporters/kube-state-metrics"
}

menu_route_or_rendor '
    ### Choose one job:
    deploy_node_exporter            "Deploy node exporter"
    undeploy_node_exporter          "Undeploy node exporter"
    deploy_kube_node_exporter       "Deploy kube node exporter"
    undeploy_kube_node_exporter     "Undeploy kube node exporter"
    deploy_kube_state_metrics       "Deploy kube state metrics"
    undeploy_kube_state_metrics     "Undeploy kube state metrics"
    return                          "0. Return to parent menu"
    ##1 Your choice:
'