# Crumbs

## What is this?
The Crumbs is a small module that helps you keep a stack of elements similar to a breadcrumb trail.

It's meant ti be used as a user navigation aid. As the user visit different elements the entries as "pushed" into the stack and "poped" as the navigate to earier entries.

## Example

![Crumb Navigation menu](sample/crumb_sample.png)


## Template

There are several way to implement the template, but here's a starting point.

Before Rows

```
<ul class="#COMPONENT_CSS_CLASSES#" id="#LIST_ID#">
```

Current Item

```
<li class="active #A02#" data-crumbid="#A04#">
   <a href="#LINK#" title="#A03#" class="#A01#">
     <span class="t-Icon #ICON_CSS_CLASSES#" #IMAGE_ATTR#></span>
     #TEXT#
   </a>
 </li>
```


Non-Current Item

```
<li class="active #A02#" data-crumbid="#A04#">
   <a href="#LINK#" title="#A03#" class="#A01#">
     <span class="t-Icon #ICON_CSS_CLASSES#" #IMAGE_ATTR#></span>
     #TEXT#
     <span title="Remove from list" class="removeCrumb allow#A05# t-Button t-Button--noUI t-Button--small" data-crumbid="#A04#"><i class="fa fa-times"></i></span>
   </a>
</li>
```


After Rows

```
</ul>
```


