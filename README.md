# Multicluster-ONOS
This script allows you to dinamically generate ONOS clusters with variable number of Atomix instances, ONOS controllers and Mininet nets.

It automatically generates configuration files for both Atomix and ONOS, that will be then runned into Docker containers.

The script takes in input:
- (-c) The number of clusters you want to generate.
- (-o) The number of Onos controllers for each cluster.
- (-a) The number of Atomix nodes for each cluster.

The configuration files are generated using the scripts provided within the ONOS project.
For this reason, you should have a local copy of that repository and which should be pointed by the $ONOS_ROOT env variable.

Once generated the clusters, the script will ask for generating Mininet nets.
After choosing the net size, a separated net with same size will be attached to each of the ONOS controllers of each cluster.
A custom docker for Mininet will be generated handling all the nets, and that will let you attach to each of them by spawning a CLI at runtime.


### In this branch, each ONOS has mapped ports on the host, so that this cluster can be accessed remotely.


## How to use
Just run: `./generate_cluster.sh -c 2 -o 2 -a 3`

With this command, you are going to generate 2 separate clusters, each running 2 ONOS instances and 3 Atomix nodes.
