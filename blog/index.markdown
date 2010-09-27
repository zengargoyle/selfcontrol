---
layout: default
title: SelfControl
---

<h2>Latest Posts</h2>

{% assign first_post = site.posts.first %}
<div id="first_post">
  <h2>{{ first_post.title }}</h2>
  <div>
    {{ first_post.content }}
  </div>
</div>

<ul>
  {% for post in site.posts limit: 3 %}
    <li>{{ post.date }} <a href="{{ post.url }}">{{ post.title }}</a></li>
  {% endfor %}
</ul>

