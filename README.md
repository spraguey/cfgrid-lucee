# cfgrid-lucee
CFGRID tag for the Lucee CFML engine

This is a BASIC cfgrid and cfgridcolumn implementation for Lucee. It is intended to make most CFGRID code cross-compatible with Adobe CF. It uses a JavaScript library called DataTables.js to mimic the functionality provided by Adobe. If you are writing new code, you should probably do your own implementation of Datatables.js instead of using this project. The real purpose of this project is to accelerate the conversion process from Adobe CF to Lucee for people who have a lot of legacy CFGRID code. I'm happy to consider requests for additions and changes. I tried to focus on the most commonly used features, and did not implement features that were purely visual (e.g. bold="yes") since those can easily be accomplished with CSS anyhow.

## Installation
1. Download and copy the files to your context directory ('/lucee-server/context/library' for server, or '/WEB-INF/lucee/library' for a single site/context). Works for both the server or an individual web context.
1. cfgrid.cfc and cfgridcolumn.cfc go in the 'tag' directory, and QueryConvertForDatatables.cfm goes in the 'function' directory
1. Restart Lucee.

## &lt;CFGRID&gt;

Supported Attributes

- format (html only1)
- name
- bind 
- pageSize
- width
- style
- query
- autoWidth
- href (see notes below)
- hrefKey
- maxrows (with query only)
- onLoad
- sort

Notes for href attribute:
This can be a standard URL, or you can use href="javascript:myfunction();" to have it run your own JavaScript function on click. In addition, you can optionally use {key} to get it to pass your hrefKey into a function - href="javascript:myfunction({key});"

See http://cfdocs.org/cfgrid for usage details.

Custom Attributes for Lucee!

- search="yes/no", show or hide the search box (default, yes)
- jsAtBottom="yes/no", place JavaScript inside bottom BODY tag (default, yes)
- cssAtBottom="yes/no", place CSS inside bottom BODY tag (default, yes)
- includeJQuery="yes/no", if you already have jQuery on your page, set to no (default, yes)
- includeDatatables="yes/no", if you already have DataTables.js on your page, set to no (default, yes)
- includeBootstrap="yes/no", if you already have Bootstrap on your page, set to no (default, yes)
  * Bootstrap is just the default for styling. You can include other styles if you want.
- customJS="path or array of paths", custom JavaScript files to include on the page. For example, jQuery UI. (default, none)
- customCSS="path or array of paths", custom CSS files to include on the page. For example, your custom Datatables styles. (default, none)

You can use includeBootstrap="no" and then customCSS="//cdn.datatables.net/1.10.13/css/jquery.dataTables.min.css", for example, to use the default Datatables styles.


## &lt;CFGRIDCOLUMN&gt;

Supported Attributes

- name
- header
- display
- width
- type (numeric, date, string only)
- dataAlign

See http://cfdocs.org/cfgridcolumn for usage details.

## QueryConvertForDatatables()

This is the equivalent of QueryConvertForGrid() in Adobe CF. You will need to use this if you are binding (using ajax) for your dataset. 

QueryConvertForDatatables(query,datatables form scope)

It will pass in all of the Datatables parameters needed and produce the JSON object that is used by datatables.

## EXAMPLE

In your cfm file...
```html
<cfgrid format="html"
      name="maingrid" 
      bind="cfc:dealers.getGrid()" 
      pagesize="10" 
      autowidth="true" 
      href="thispage.cfm?action=form&amp;id="
      hrefKey="id" 
      sort="yes"
      cssAtBottom="false"
      >
      <cfgridcolumn name="id" display="no" />
      <cfgridcolumn name="name" header="Name" />
      <cfgridcolumn name="city" header="City" />
      <cfgridcolumn name="state" header="State" />
</cfgrid>
```

In dealers.cfc, you would have a function...

```html
<cffunction name="getGrid" output="false" access="remote">

        <cfquery name="returnQry" datasource="mydsn">
        SELECT id,name,city,state FROM dealers
        ORDER BY #form.gridsortcolumn# #form.gridsortdir#
        </cfquery>
                
        <cfreturn QueryConvertForDatatables(returnQry,form)> 
</cffunction>
```

So, this should be cross-compatible with Adobe CF, EXCEPT for switching out your QueryConvertForGrid with QueryConvertForDatatables.
