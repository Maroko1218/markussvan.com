---
title: Setting Up Wireguard
date: 2025-08-22
draft: false
summary: A somewhat detailed description of how to host your own Wireguard VPN server. As well as some basic wireguard configs.
tags:
    - Linux
    - VPN
    - Wireguard
---
# Hosting My Own Wireguard VPN Server
At my home network, I have a a blacklist of websites that I don't want to be able to access. This is purely to help me avoid doom-scrolling things like YouTube/Twitter/Reddit/etc... When I'm using my phone in any place that isn't my home, the block no longer works, since the way it is implemented is as self defined DNS posts that return 0.0.0.0 for anything I put in the blacklist. This exploration into setting up my own VPN was inspired by wanting to:
1. Have websites blocked even when not at home
2. Reach websites or other API's I have hosted in my home network from *outside* without forwarding their ports!

## Initial Setup
- As I am using Arch Linux the package I installed was `wireguard-tools`.
- I had to create a private/public key pair for two machines. `(umask 077 && wg genkey > key.priv) && wg pubkey < key.priv > key.pub`
With the keys generated on both machines we can now start configuring wireguard on both computers. To start with, we'll do the case where both computers are under the same LAN first.

## Lan config
`/etc/wireguard/wg0.conf` of computer 1
```
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = COMPUTER_1_PRIVATE_KEY

[Peer]
PublicKey = COMPUTER_2_PUBLIC_KEY
AllowedIPs = 10.0.0.2/32
Endpoint = COMPUTER_2_IPv4_ADDRESS:51820
```

`/etc/wireguard/wg0.conf` of computer 2
```
[Interface]
Address = 10.0.0.2/24
ListenPort = 51820
PrivateKey = COMPUTER_2_PRIVATE_KEY

[Peer]
PublicKey = COMPUTER_1_PUBLIC_KEY
AllowedIPs = 10.0.0.1/32
Endpoint = COMPUTER_1_IPv4_ADDRESS:51820
```

These configs can then be loaded on the respective computers by running `wg-quick up wg0` on both machines.
They should now be able to ping one another on the respective 10.0.0.1 and 10.0.0.2 addresses!

## Wan Config
From now on I will be referring to "computer 1" as the *Server* and any other connection, such as computer 2, as a "Client".
When under the lan, the computers can find each other thanks to the `Endpoint` line of the configuration. But in the scenario where I'm using my phone away from home, what would the server write down as an endpoint for my phone? Since it can change at any point, we now ommit writing down the endpoint of our clients connecting to the server.
While on the client side we will be writing down the public IP of the Server, (a domain name helps here), but since we also won't be listening for any *incoming* connections, we can ommit the ListenPort field.

`/etc/wireguard/wg0.conf` of the Server
```
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = SERVER_PRIVATE_KEY

[Peer]
PublicKey = CLIENT_PUBLIC_KEY
AllowedIPs = 10.0.0.2/32
```

`/etc/wireguard/wg0.conf` of a client
```
[Interface]
Address = 10.0.0.2/24
PrivateKey = CLIENT_PRIVATE_KEY

[Peer]
PublicKey = SERVER_PUBLIC_KEY
AllowedIPs = 10.0.0.1/32
Endpoint = PUBLIC_IP_OR_DOMAIN_NAME:51820
```
You will of course have to port forward the UDP traffic from your router to the server.

Now the computers are able to communicate through the VPN even though they're not on the same network. Now on to the hard part. *forwarding traffic through the VPN*.

## Using The VPN For All Traffic
In the configs we specified, we put `/32` as the subnet mask, meaning there is no flexibility in the ip addresses where we send traffic through the VPN. But if you want "all" (with a caveat that I'll introduce later) traffic through the VPN you instead specify `AllowedIPs = 0.0.0.0/0` on your client config this indicates that all traffic goes through the VPN instead of anywhere else.

Our server will now receive this traffic, but since it isn't configured to act as a router it'll just drop the packets. To make the server actually pass traffic on we'll have to set the `net.ipv4.ip_forward` and `net.ipv4.conf.all.forwarding` options to `1`. You can do this on the server by running `sysctl net.ipv4.ip_forward=1 net.ipv4.conf.all.forwarding=1`

There is still 1 crucial step, and it's to set up forwarding rules using iptables.
- `iptables -A FORWARD -i wg0 -j ACCEPT` Add a rule to forward traffic from the wireguard interface.
- `iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT` Add a rule to forward traffic if it's related to already established traffic.
- `iptables -t nat -A POSTROUTING -o SERVERS_NETWORK_INTERFACE -j MASQUERADE` Add a rule to route the VPN traffic without interfering/disrupting the original connection.

Now, this gave me the biggest headache. Because if you have Docker installed, these iptables rules are different. 

- [Where I first saw this mentioned after struggling for a week](https://gist.github.com/nealfennimore/92d571db63404e7ddfba660646ceaf0d?permalink_comment_id=4336598#gistcomment-4336598)
- [Docker documentation](https://docs.docker.com/engine/network/packet-filtering-firewalls/#docker-on-a-router)
- [Archlinux Wiki](https://wiki.archlinux.org/title/Internet_sharing#Enable_NAT)

The rules if you have Docker installed on your server become the following.
- `iptables -I DOCKER-USER -i wg0 -j ACCEPT` Add a rule to forward traffic from the wireguard interface.
- `iptables -I DOCKER-USER -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT` Add a rule to forward traffic if it's related to already established traffic.
- `iptables -t nat -A POSTROUTING -o SERVERS_NETWORK_INTERFACE -j MASQUERADE` Add a rule to route the VPN traffic without interfering/disrupting the original connection.
Make sure to change `SERVERS_NETWORK_INTERFACE` into the actual interface your server is using for it to use internet. In my case it was `enp3s0`. Check `ip a` to help figure out which one should be written down in your case.

It's possible to add these iptables rules as part of a "PostUp" and "PostDown" clause on the servers wg0.conf so that you don't have to re-add these rules whenever you restart your server. *Or* you can make the changes persistent by saving the current iptables configuration to a file. `iptables-save /etc/iptables/iptables.rules` and enabling the iptables service to restore the saved rules. `systemctl enable iptables`

The majority of guides I've seen opt for the PostUp and PostDown method, so I will also show the final configurations with these rules added.

### THE CAVEAT!
Remeber long ago when I said routing "all" traffic... well... it was *almost* true. By default it seems wireguard won't try to forward traffic intended for your current lan, which, honestly, sounds quite sane. But since I wanted to access my *home router* through the VPN... and it has an IP address of `192.168.0.1`... I also need to add this to allowed IPs. The result looks like this `AllowedIPs = 0.0.0.0/0, 192.168.0.0/24
It's possible there are other addresses like these (I'd assume wireguard doesn't try to forward 127.0.0.1...), and by also forwarding what usually is LAN traffic through the VPN it *could* cause some issues connecting to some public WiFi...? (I think?) We're a bit in speculation land here. I haven't had any issues with it so far, but it's something to be cautious of. I also don't think I'd recommend this solution to others. It's much better to have the router as a predefined peer, I couldn't do this due to _proprietary_ reasons. 😞

## Final Configs for Server and Client
`/etc/wireguard/wg0.conf` on the server
```
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = SERVER_PRIVATE_KEY
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT; iptables -t nat -A POSTROUTING -o SERVERS_NETWORK_INTERFACE -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT; iptables -t nat -D POSTROUTING -o SERVERS_NETWORK_INTERFACE -j MASQUERADE


[Peer]
PublicKey = CLIENT_PUBLIC_KEY
AllowedIPs = 10.0.0.2/32
```

`/etc/wireguard/wg0.conf` on the client
```
[Interface]
Address = 10.0.0.2/24
PrivateKey = CLIENT_PRIVATE_KEY

[Peer]
PublicKey = SERVER_PUBLIC_KEY
AllowedIPs = 0.0.0.0/0
Endpoint = PUBLIC_IP_OR_DOMAIN_NAME:51820
```
