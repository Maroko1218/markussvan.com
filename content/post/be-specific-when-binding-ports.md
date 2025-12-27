---
title: Be Specific When Binding Ports!
date: 2025-12-18
draft: false
summary: General rantings and thoughts about binding ports. Idea had from running into issues with Docker containers and Waydroid.
---
# Be specific when binding ports!
Most Docker tutorials I've seen, mention to bind ports by simply specifying `-p 80`.
This *will* work for most people getting started with containers. However, I when I was trying to run a Pi-hole docker container, it didn't start... I restarted my computer and tried again, unsure what other program would've been binding to port 53. And this time the container started!... *But Waydroid didn't* with the following error `dnsmasq: failed to create listening socket for 192.168.250.1: Address already in use`

I was confused. How was I **ever** supposed to run my Pi-hole container at the same time as I get to run android apps through Waydroid?! Since "port 53" would be occupied, *right?*

# Several services on the *"same port"?*
This is where we have to analyze the error message more closely. Why does it mention an ipaddress and not just the port number? It's because when binding a port, you bind *to an interface*. Our Docker port bindings are too broad, we can be even more specific about what we want to bind! `-p 192.168.0.2:53:53/udp` is the actual specific binding I should pass to Docker. By omitting the interface and protocol you'll be binding `0.0.0.0:53:53/tcp` *and* `:::53:53/tcp` (IPv6) by default.