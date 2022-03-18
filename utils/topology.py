from mininet.topo import Topo
from mininet.net import Mininet
from mininet.log import setLogLevel
from mininet.node import RemoteController
from mininet.cli import CLI
from mininet.node import RemoteController
import argparse

class MyTreeTopo( Topo ):
    hostNum = 1
    switchNum = 1
    def build( self, depth, fanout):
        self.addTree( depth, fanout )

    def addTree( self, depth, fanout ):
        isSwitch = depth > 0
        if isSwitch:
            node = self.addSwitch( 's%s' % MyTreeTopo.switchNum, dpid="00000000000000"+str(self.switchNum), protocols="OpenFlow13" )
            MyTreeTopo.switchNum += 1
            for _ in range( fanout ):
                child = self.addTree( depth - 1, fanout )
                self.addLink( node, child)
        else:
            node = self.addHost( 'h%s' % MyTreeTopo.hostNum )
            MyTreeTopo.hostNum += 1
        return node


def run(controllers, depth, fanout):
    nets= []
    try:
        for controller in controllers:
            netname="net"+str(len(nets))
            print("\n********Strarting "+netname+" with attached to controller "+controller+"********")
            c = RemoteController(controller, controller)
            topo = MyTreeTopo(depth, fanout) 
            net = Mininet(topo=topo, controller=c)
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
        print("********Stopping all nets********\n")
        for net in nets:
            net[1].stop()

# if the script is run directly (sudo custom/optical.py):
if __name__ == '__main__':
    parser = argparse.ArgumentParser("topology.py")
    parser.add_argument("depth", help="The IP of the ONOS controller.", type=int)
    parser.add_argument("fanout", help="The IP of the ONOS controller.", type=int)
    parser.add_argument("controllers", help="The IP of the ONOS controller.", type=str, nargs="+")
    setLogLevel('info')
    args = parser.parse_args()
    print(args.controllers)
    run(args.controllers, args.depth, args.fanout)
