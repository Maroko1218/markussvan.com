---
title: "Obsidian for Posts"
date: 2025-03-10
draft: False
summary: "I want to use the power of Obsidian to tag and link between my posts"
---
I have a sort of goal/dream where I could just edit these posts inside of Obsidian, save my vault, and have the website update.

I think it is very much possible and that I should have the skills needed to make this possible.

## A *very* rough estimate of things needed
- GitHub Actions to have some sort of auto deployment when new posts are pushed... (Or a periodic pull using the already existing systemd timer?)
- A script which will convert the `[[obsidian]]` style links to `[hugo]({*{< relref path="style" >}})` links. ~~The * is there simply to make hugo build not complain about actually trying to make a link.~~
