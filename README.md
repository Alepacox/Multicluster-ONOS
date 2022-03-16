# Multicluster-ONOS
This script allows you to dinamically generate ONOS clusters with variable number of Atomix instances and ONOS controllers.

It automatically generates configuration files for both Atomix and Onos, that will be then runned into Docker containers.

The script takes in input:
- (-c) The number of clusters you want to generate.
- (-o) The number of Onos controllers for each cluster.
- (-a) The number of Atomix nodes for each cluster.

The configuration files are generated using the script provided whitin the ONOS project.
For this reason, you should have a local copy of that repository and which should be pointed by the $ONOS_ROOT env variable.
