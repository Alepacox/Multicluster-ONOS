#!/bin/bash

set -e

name_net=onos_clusters
net=172.168.7.0
sub=/24
ip_counter=1

usage() { echo -e "Usage: $0 [-c >1&<10] [-o >1&<10] [-a >1&<10] \n \
-c --> number of clusters to be generated \n \
-o --> number of onos controllers per cluster \n \
-a --> number of atomix nodes per cluster" 1>&2; exit 1; }

while getopts ":c:o:a:" s; do
    case "${s}" in
        c)
            c=${OPTARG}
            ((c > 0 && c < 10)) || usage
            ;;
        o)
            o=${OPTARG}
            ((o > 0 && o < 10)) || usage
            ;;
        a)
            a=${OPTARG}
            ((a > 0 && a < 10)) || usage
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${c}" ] || [ -z "${o}" ] || [ -z "${a}" ]; then
    usage
fi

if docker ps -a -f "name=^cluster" | grep -q 'cluster'; then
    read -p "Found old containers beloging to one or more ONOS clusters. Do you want to restart it or create a new one? [y|n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        echo "Restarting previous clusters."
        docker container start $(docker ps -a -q -f "name=^cluster")
        exit 0
    else 
        echo "Removing previous clusters."
        docker container stop $(docker ps -a -q -f "name=^cluster")
        docker container rm $(docker ps -a -q -f "name=^cluster")
    fi
else
    docker network create ${name_net} --driver=bridge --subnet=${net}${sub}
    echo "Creating network ${name_net} on subnet ${net}"   
fi

echo -e "\nUsing the following configuration: \n\
# of clusters = ${c} \n\
# of onos instances per cluster = ${o} \n\
# of atomix instances per cluster = ${a}"


create_atomix_configs() {
    atomix_cluster=()
    for ((i=1; i<=$a; i++))
    do
        ip_counter=$((ip_counter+1))
        node_ip=${net::-1}$(($ip_counter))
        export OC$i=$node_ip
        atomix_cluster+=($node_ip)
    done
    for ((i=0; i<$a; i++))
    do
        echo -e "\nStarting Atomix nodes for cluster $1:"
        $ONOS_ROOT/tools/test/bin/atomix-gen-config ${atomix_cluster[$i]} conf/cluster$1/atomix-$i.conf ${atomix_cluster[@]}
        docker run -d --mount type=bind,source=$(pwd)/conf/cluster$1/atomix-$i.conf,target=/opt/atomix/conf/atomix.conf --net ${name_net} --ip ${atomix_cluster[$i]} --name cluster$1_atomix_$i atomix/atomix:3.1.5
    done
}

create_onos_configs() {
    local onos_cluster=()
    for ((i=1; i<=$o; i++))
    do
        ip_counter=$((ip_counter+1))
        node_ip=${net::-1}$(($ip_counter))
        onos_cluster+=($node_ip)
    done
    for ((i=0; i<$o; i++))
    do
        echo -e "\nStarting ONOS controllers for cluster $1 with IP:"
        $ONOS_ROOT/tools/test/bin/onos-gen-config ${onos_cluster[$i]} conf/cluster$1/cluster-$i.json -n ${atomix_cluster[@]}
        docker run -d --mount type=bind,source=$(pwd)/conf/cluster$1/cluster-$i.json,target=/root/onos/config/cluster.json --net ${name_net} --ip ${onos_cluster[$i]} --name cluster$1_onos_$i onosproject/onos:latest
    done
}

create_cluster() {
    
    for ((myc=1; myc<=$c; myc++))
    do
        mkdir -p conf/cluster$myc
        create_atomix_configs $myc
        create_onos_configs $myc
    done

}

create_cluster







