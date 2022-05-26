from mininet.topo import Topo
from mininet.net import Mininet
from mininet.log import setLogLevel
from mininet.node import RemoteController
from mininet.cli import CLI
from mininet.node import RemoteController, Intf, Link
import argparse
import os

vethlists = [
    "veth0",
]

vethpairs = {
    "n0_s1": ["veth0a"],
    "n1_s1": ["veth0b"]
}

class MyTreeTopo( Topo):
    switchNum = 1
    subnet = 0
    first = True

    def addIntfPair(self, switch):
        if (vethpairs.get(switch)):
            for veth in vethpairs[switch]:
                self.addLink(switch, switch, cls=NullLink, intfName1=veth, cls2=NullIntf)
    
    def build( self, depth, fanout, net):
        self.net=net
        self.addTree(depth, fanout)
        MyTreeTopo.subnet+=1

    def addTree( self, depth, fanout):
        isSwitch = depth > 0
        if isSwitch:
            mydpid = str(self.net)+str(self.switchNum).rjust(16, '0')[len(str(self.net)):]
            name = "n"+self.net+"_s"+str(self.switchNum)
            node = self.addSwitch(name, dpid=mydpid, protocols="OpenFlow13" )
            self.addIntfPair(name)
            self.switchNum += 1
            for _ in range( fanout ):
                child = self.addTree( depth - 1, fanout)
                if child != None:
                    self.addLink( node, child)
            return node

class NullIntf( Intf ):
    def __init__( self, name, **params ):
        self.name = ''

class NullLink( Link ):
    def makeIntfPair( cls, intf1, intf2, *args, **kwargs ):
        pass
    def delete( self ):
        pass
    

def createVeth():
    for item in vethlists:
        os.system("ip link add "+item+"a type veth peer name "+item+"b")

def deleteVeth():
    for item in vethlists:
        os.system("sudo ip link delete "+item+"a")


def run(controllers, cluster_size, depth=1, fanout=1):
    nets= []
    output=[controllers[i:i + cluster_size] for i in range(0, len(controllers), cluster_size)]
    createVeth()
    try:
        for cluster in output:
            netname="net"+str(len(nets))
            print("\n********Strarting "+netname+" with attached to controllers "+str(cluster)+" ********")
            topo = MyTreeTopo(depth, fanout, str(len(nets)))
            controller = RemoteController(cluster[0],cluster[0])
            net = Mininet(topo=topo, controller=controller)
            for controller in cluster[1:]:
                net.addController(RemoteController(controller, controller))
            net.start()
            nets.append((netname,net))

        while True:
            print("\nHere is the list of nets currectly loaded:")
            for i in range(len(nets)):
                print(str(i)+") ---- "+nets[i][0])
            try:
                sec = input('\nTo which net you want to access? [0,..]: ')
                if int(sec) in range(len(nets)):
                    cli= CLI(nets[int(sec)][1])
                else:
                    raise ValueError
            except ValueError:
                print("Please provide a valid net number.\n")
                pass
    except KeyboardInterrupt:
        print('\n********Stopping all nets********\n')
        for net in nets:
            net[1].stop()
        deleteVeth()
        os.system("mn -c")

if __name__ == '__main__':
    parser = argparse.ArgumentParser("topology.py")
    parser.add_argument("depth", help="Depth of the network to generate.", type=int)
    parser.add_argument("fanout", help="Fanout of the network to generate ", type=int)
    parser.add_argument("onos_cluster_size", help="Number of ONOS node per controllers", type=int)
    parser.add_argument("controllers", help="The IP of the ONOS controllers.", type=str, nargs="+")
    setLogLevel('info')
    args = parser.parse_args()
    run(args.controllers, args.onos_cluster_size, args.depth, args.fanout)
