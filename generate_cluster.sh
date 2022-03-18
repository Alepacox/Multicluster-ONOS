#!/bin/bash

#set -e

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

if docker ps -a | grep -q 'cluster'; then
    echo "Cleaning up old containers."
    docker container stop $(docker ps -a -q -f "name=^cluster")
    docker container rm $(docker ps -a -q -f "name=^cluster")
fi

if ! docker network ls | grep -q 'onos_cluster'; then
    docker network create ${name_net} --driver=bridge --subnet=${net}${sub}
    echo "Creating network ${name_net} on subnet ${net}"   
fi

echo -e "\nUsing the following configuration: \n\
# of clusters = ${c} \n\
# of onos instances per cluster = ${o} \n\
# of atomix instances per cluster = ${a}"

onos_nodes=()

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
    onos_cluster=()
    for ((i=1; i<=$o; i++))
    do
        ip_counter=$((ip_counter+1))
        node_ip=${net::-1}$(($ip_counter))
        onos_cluster+=($node_ip)
        onos_nodes+=($node_ip)
    done
    for ((i=0; i<$o; i++))
    do
        echo -e "\nStarting ONOS controllers for cluster $1 with IP:"
        $ONOS_ROOT/tools/test/bin/onos-gen-config ${onos_cluster[$i]} conf/cluster$1/cluster-$i.json -n ${atomix_cluster[@]}
        docker run -d --mount type=bind,source=$(pwd)/conf/cluster$1/cluster-$i.json,target=/root/onos/config/cluster.json --net ${name_net} --ip ${onos_cluster[$i]} --name cluster$1_onos_$i onosproject/onos:latest
    done
}

create_topologies() {
    read -p "Would you like to create a subnet for each ONOS? [y|n]" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        if ! docker image ls | grep -q 'mininet_custom';
        then
            docker build -t mininet_custom .
        fi
        if docker ps -a | grep -q 'mininet_custom'; 
        then
            docker rm mininet_custom
        fi
        read -p "Enter depth: " depth
        read -p "Enter fanout: " fanout
        ip_counter=$((ip_counter+1))
        docker run -it --privileged --name mininet_custom --net onos_clusters --ip ${net::-1}$(($ip_counter))  mininet_custom $depth $fanout ${onos_nodes[@]} 
    else 
        exit 0;
    fi

}

create_cluster() {
    
    for ((myc=1; myc<=$c; myc++))
    do
        mkdir -p conf/cluster$myc
        create_atomix_configs $myc
        create_onos_configs $myc
        create_topologies
    done

}

create_cluster







