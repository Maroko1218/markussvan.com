---
title: "Using Obsidian for posts"
date: 2025-03-10
draft: False
summary: "Details of how I enabled using Obsidian and wikilinks for making posts on my website!"
---
## Using Obsidian for posts
I have a sort of goal/dream where I could just edit these posts inside of Obsidian, save my vault, and have the website update.

I think it is very much possible and that I should have the skills needed to make this possible.

## A *very* rough estimate of things needed
- GitHub Actions to have some sort of auto deployment when new posts are pushed... (Or a periodic pull using the already existing systemd timer?)
- A script which will convert the `[[obsidian]]` style links to `[hugo]({{</* relref path="style" */>}})` links.

# I have implemented it. And everything above was entirely clueless!
What a ride, I kept searching for "obsidian to hugo converter" or similar things. But what I really needed was "wikilinks to hugo". This search made me find the [hugo-wikilinks](https://github.com/milafrerichs/hugo-wikilinks) repository by [Mila Frerichs](https://github.com/milafrerichs) and it did everything I needed from it!

## Implementation
The instructions from the github repo seems to assume the user has a decent knowledge of how to build hugo partials. I did *not* have this knowledge. But taking the time to add this and modifying it to my liking gave me a much better understanding of how hugo works!

I copied the `content-wikilinks.html` partial into my theme's `/layouts/partials/` directory. And to use it I replaced where my theme added `{{- .Content -}}` with `{{ partial "content-wikilinks" . }}`! This alone is *almost* enough to add wikilinks to the hugo theme. But there were some issues.

### Problems to solve
1. There was a missing `{` at the start of the partial. That's an easy enough fix
2. The partial adds an `<a>` tag directly into the text content, and hugo by default does *not* like this. Since, if I would allow user generated content on my site, that would allow for a post to have other html tags, like a script tag... And suddenly I have XSS vulnerabilities. Not ideal.
3. If the wikilink doesn't exist (like in the example above) the site build fails. So I wanted to add a way to skip making a link to sites which don't exist and to not have the build fail.

### Solutions
#### Missing bracket
I simply added the missing `{`
#### Avoid XSS
The line in question which causes this error is the following: `{{ $link := printf "%s%s%s%s%s" "<a href=\"" $rel "\">" $content "</a>"  }}`. The solution was rather simple, I just replaced the building of an html tag with the building of a hugo link: `{{ $link := printf "%s%s%s%s%s" "[" $content "]({{</* relref path=\"" $rel "\"*/>}})" }}`.
#### Don't make a link if no post exists
This was rather complicated for me to figure out as I hadn't played around with hugo much before. But I feel pretty happy with my solution! It required some modification of the `content-wikilinks.html` file. Specifically the following code block:
```
{{ $pageexists := $page.GetPage $content}}
{{ if $pageexists }}
    <!--Build the link!-->
{{ end }}
```
By slotting this logic check in before calling relref, if a page doesn't exist where the wikilink points... it'll simply skip it!

## Backlinks...?
The github repo also included a function for backlinks... And this really appeals to me. Being able to show all the posts which have mentioned the current post really gives the *obsidian feel* to the posts which feels like such a good way to traverse the website on related content, __related thoughts__. Now, this was a little difficult to implement and I don't think my solution is the cleanest or prettiest *yet*. (I am very likely going to update this snippet with time.) But I will still document what I did to add the backlinks!

### The simple solution
I added the `backlinks.html` partial into `/layouts/partials/funcs/`. This time the file itself needed no modifications to make it function, but it takes a little bit of effort to actually have the expected result. Right below where I added `{{ partial "content-wikilinks" . }}` (that's this text you're reading right now!) I placed the following code block.
```
{{ $backlinks := partial "funcs/backlinks.html" . }}
{{ if $backlinks }}
    <h2>Backlinks</h2>
    {{ range $backlinks }}
        {{ range $link, $title := . }}
            {{ $hugolink := printf "%s%s%s%s%s" "[" $title "]({{</* relref path=\"" $link "\"*/>}})" }}
            {{ $hugolink | markdownify }}<br>
        {{ end }}
    {{ end }}
{{ end }}
```
So, we define `$backlinks` which is a list of everything that has referenced whatever page/post is currently being built. After that I added an if statement to first check, *am I referenced by anything at all?* Because, if nothing is linking to us, we don't have any backlinks! However, if we did have a link then we add the `<h2>Backlinks</h2>` section. (That line is very likely to change in the future as I don't think it looks the cleanest)
Then we loop through all the backlinks using `{{ range $backlinks }}`. And this is where it got a little confusing. The $backlinks list is full of *maps* which to me is what I'd think of as a Python dictionary. The important takeaway is that *in this case* it's just a singular item with a key value pair. The "key" is `$link` and the "value" is `$title`. Then I use the same trick from the wikilinks code to build the hugo link, markdownify it to make hugo process it, and add a simple br at the end to make it a sort of list!
The result is a pretty ugly header which for now looks like the continuation of the post. But it should have fully functional backlinks!

I will add a link here to [[adding-giscus]] so you can go look at the bottom and see the backlink!
If anyone found this useful, or if you have any questions, I would love to see a reaction or a comment under this post and I will do my best to try and help!