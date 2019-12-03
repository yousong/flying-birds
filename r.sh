pub0="BkuTYHhS+/bC3V2mOQeu47s+aYyCFqaRdhSSKdtvURE="
pri0="2IcJdVz2aVh+aKxYJrMvqo6teIVeY2Do68cfpjsjr3E="
ip0=169.254.169.1/30
ep0=10.0.0.1
brd0=10.0.0.255
nets0=10.168.222.0/24

pub1="QFCARvYF6M+kJOaB+amhZnDNm6MJJFg/FaDu8tsMcTY="
pri1="gDTS15qa6H9p3vafTCHaV9u9Wgx5vdPGelNLIrUepVU="
ip1=169.254.169.2/30
ep1=10.0.0.2
brd1=10.0.0.255
nets1=192.168.122.0/24,192.168.222.0/24

set -x

cleanup() {
	ip netns del ns0
	ip netns del ns1
}

cleanup &>/dev/null

# NOTES
#
# 1. up lo
# 2. brd addr

ip netns add ns0
ip netns add ns1
ip link add dev veth0 type veth peer name veth1
ip link set veth0 netns ns0
ip link set veth1 netns ns1
ip netns exec ns0 bash -c "
ip link set lo up
ip link set veth0 up
ip addr add $ep0/24 brd $brd0 dev veth0
"
ip netns exec ns1 bash -c "
ip link set lo up
ip link set veth1 up
ip addr add $ep1/24 brd $brd1 dev veth1
"

ip netns exec ns0 bash -c "
ip link add dev wg0 type wireguard
wg set wg0 listen-port 21841 private-key <(echo $pri0) peer $pub1 endpoint $ep1:21841 allowed-ips $nets1,169.254.169.0/30 persistent-keepalive 5
ip link set dev wg0 up
ip addr add $ip0 dev wg0
"

ip netns exec ns1 bash -c "
ip link add dev wg1 type wireguard
wg set wg1 listen-port 21841 private-key <(echo $pri1) peer $pub0 endpoint $ep0:21841 allowed-ips $nets0,169.254.169.0/30 persistent-keepalive 5
ip link set dev wg1 up
ip addr add $ip1 dev wg1
"
