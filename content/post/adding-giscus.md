---
title: Adding giscus and replacing gitalk
date: 2025-03-03
draft: false
summary: Adding giscus to my site. I really wanted the reactions which were lacking from gitalk, and using discussions for the backend instead of issues.
tags:
    - Hugo
---
# Adding Giscus

The [hugo theme](https://themes.gohugo.io/themes/github-style/) used for this website had inbuilt support for gitalk. But after setting it up and realizing that it stored comments using GitHub issues, it felt a little "too hacky". I also saw other hugo built sites that allowed users to add *reactions* to posts, not just comments. The "backend" for giscus is GitHub discussions instead of issues which (very subjectively) feels a lot less hacky.

## But... how do I swap?

Initially I was just reading the [giscus.app](https://giscus.app/) site itself and it told me to add a script block... *I'm still very new to Hugo and was pretty clueless with where to start*. But after some tinkering and combining the solutions of *two* other people I've reached a satisfactory result!

The main source of help I had for initially adding giscus to my site was [this post](https://synfulchaot.github.io/posts/enabling-discourse/) from SynfulChaot.

However, after getting it added I realized that it didn't obey the site light/dark theme switch. Luckily [this post](https://www.brycewray.com/posts/2023/08/making-giscus-less-gabby/) (with a few modifications) from Bryce Wray helped me with making giscus listen to the hugo theme!

I don't think I can write any better guidance than what these two people have provided before me, but I will do my best to share the modifications I did to blend it all together!

## Modified giscus.html

I really liked the site parameters solution to have all configuration for the site stored in the same place. But I had to set the giscus theme when the page loaded based on the user's selected theme. This is why the script tag is dynamically created and then appended once the page is loaded.

```html
{{- if isset .Site.Params "giscus" -}}
    <div class="comments-giscus" style="max-width: 840px; margin: 0 auto;">
        <script>
            document.addEventListener('DOMContentLoaded', function () {
                const giscusAttributes = {
                    "src": "https://giscus.app/client.js",
                    "data-repo": "{{ .Site.Params.giscus.repo }}",
                    "data-repo-id": "{{ .Site.Params.giscus.repoID }}",
                    "data-category": "{{ .Site.Params.giscus.category }}",
                    "data-category-id": "{{ .Site.Params.giscus.categoryID }}",
                    "data-mapping": "{{ .Site.Params.giscus.mapping }}",
                    "data-strict": "{{ .Site.Params.giscus.strict }}",
                    "data-reactions-enabled": "{{ .Site.Params.giscus.reactionsEnabled }}",
                    "data-emit-metadata": "{{ .Site.Params.giscus.emitMetadata }}",
                    "data-input-position": "{{ .Site.Params.giscus.inputPosition }}",
                    "data-theme": getGiscusTheme(),
                    "data-lang": "{{ .Site.Params.giscus.lang }}",
                    "data-loading": "{{ .Site.Params.giscus.loading }}",
                    "crossorigin": "{{ .Site.Params.giscus.crossOrigin }}",
                    "async": "",
                }

                // Dynamically create script tag
                const giscusScript = document.createElement("script")
                Object.entries(giscusAttributes).forEach(([key, value]) => giscusScript.setAttribute(key, value))
                document.querySelector('.comments-giscus').appendChild(giscusScript)
            })
        </script>
        <noscript><p>Apologies, but the giscus-powered comments require JavaScript to view.  Sorry!</p></noscript>
    </div>
{{- end -}}
```

## Modified theme-mode.js
Now, `getGiscusTheme()` wasn't defined in the giscus.html file, and I sadly hid it away in the js of `/themes/github-style/static/js/theme-mode.js`
This is to take advantage of the already existing `setTheme()` function.

```js
function setTheme(style) {
  document.querySelectorAll('.isInitialToggle').forEach(elem => {
    elem.classList.remove('isInitialToggle');
  });
  document.documentElement.setAttribute('data-color-mode', style);
  localStorage.setItem('data-color-mode', style);
  localStorage.setItem('prefers-color-scheme', style)
  setGiscusTheme()
}
```

setting/changing the giscus theme is now called whenever the user swaps between light and dark theme. And here are the functions, simply appended a little lower inside the same file.

```js
function getGiscusTheme() {
	const themeStatus = localStorage.getItem("data-color-mode")
	let
		giscusTheme = "preferred_color_scheme",
		dataThemeLight = "light",
		dataThemeDark = "dark"
  if (themeStatus === "light") {
		giscusTheme = dataThemeLight
	} else if (themeStatus === "dark") {
		giscusTheme = dataThemeDark
	}
	return giscusTheme
}

function setGiscusTheme() {
	function sendMessage(message) {
		const iframe = document.querySelector('iframe.giscus-frame')
		if (!iframe) return
		iframe.contentWindow.postMessage({ giscus: message }, 'https://giscus.app')
	}
	sendMessage({
		setConfig: {
			theme: getGiscusTheme(),
		},
	})
}
```

I'm really happy getting giscus to respect the theme changes, and super happy to now have reactions to my posts!