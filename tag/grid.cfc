<cfcomponent name="grid">
	<cfset this.metadata.attributetype="mixed">
	<cfset this.metadata.attributes={
		// Standard CFML attributes that match Adobe CF
		name:			{required:true,type:"string"},
		format:      	{required:false,type:"string",default:"html"},
		bind:  			{required:false,type:"string",default:"",hint:""},	
		query: 			{required:false,type:"any",default:"",hint:""},	
		width: 			{required:false,type:"string",default:"100%",hint:""},	
		href: 			{required:false,type:"string",default:"",hint:""},	
		hrefKey: 		{required:false,type:"string",default:"",hint:""},	
		pageSize: 		{required:false,type:"string",default:"10",hint:""},	
		autowidth: 		{required:false,type:"boolean",default:true,hint:""},	
		style: 			{required:false,type:"string",default:"",hint:""},	
		sort:			{required:false,type:"boolean",default:true,hint:""},	
		onload: 		{required:false,type:"string",default:"",hint:""},	
		maxrows: 		{required:false,type:"string",default:"999999",hint:"Applies to query only, not bind"},
		// Below here is custom for Lucee attributes
		search:				{required:false,type:"boolean",default:true,hint:"Include the search box."},
		jsAtBottom:      	{required:false,type:"boolean",default:true,hint:"Put the JavaScript includes inside the closing BODY tag."},
		cssAtBottom:      	{required:false,type:"boolean",default:true,hint:"Put the CSS includes inside the closing BODY tag."},
		includeDatatables:  {required:false,type:"boolean",default:true,hint:"Set to false to use your own datatables js."},
		includeDatatablesCSS:  {required:false,type:"boolean",default:true,hint:"Set to false to use your own styles."},
		includeJQuery:    	{required:false,type:"boolean",default:true,hint:"Set to false to use your own jQuery (1.12+)."},
		includeBootstrap:   {required:false,type:"boolean",default:false,hint:"Set to true to use Bootstrap for styling."},
		customJS:      	{required:false,type:"any",default:"",hint:"Pass a single path to a js file, or an array of paths."},
		customCSS:      	{required:false,type:"any",default:"",hint:"Pass a single path to a css file, or an array of paths."},
		lengthChange:		{required:false,type="boolean",default=true,hint:"Show the per-page pulldown"},
		compact:			{required:false,type="boolean",default=true,hint:"Set false for more padding/spacing."},
		defaultSortColumn:	{required:false,type="string",default="",hint:"Default column to sort by on load. If blank, it uses the first column."},
		defaultSortDir:			{required:false,type="string",default="ASC",hint:"Sort direction on load."}
	}/>
	<cfset variables.children = [] />
	<cfset _log = [] />

	<cffunction name="init" output="no" returntype="void" hint="invoked after tag is constructed">
		<cfargument name="hasEndTag" type="boolean" required="yes" />
		<cfargument name="parent" type="component" required="no" hint="the parent cfc custom tag, if there is one" />
		<cfset variables.hasEndTag = arguments.hasEndTag />
	</cffunction>
	<cffunction name="onStartTag" output="yes" returntype="boolean">

		<cfargument name="attributes" type="struct">
		<cfargument name="caller" type="struct">

		<cfif structKeyExists(attributes,"argumentCollection")>
			<cfset arguments.attributes = attributes.argumentCollection />
		</cfif>

		<!--- this sets the defaults for undefined attributes.  Not sure why this is needed. --->
		<cfset variables.attributes=setAttributes(arguments.attributes) />

		<cfif NOT isQuery(attributes.query) and attributes.query GT "">
			<cfset attributes.query = caller[attributes.query] />
		</cfif>

		<cfif not variables.hasEndTag>
			<cfset onEndTag(variables.attributes,caller,"") />
		</cfif>

		<cfreturn variables.hasEndTag>
	</cffunction>
	<cffunction name="onEndTag" output="yes" returntype="boolean">

		<cfargument name="attributes" type="struct">
		<cfargument name="caller" type="struct">
		<cfargument name="generatedContent" type="string">

		<cfset var children = getChildren() />
		<cfset attributes.children = children />

		<cfset attributes.columns = "" />
		<cfset attributes.firstVisibleColumn = "" />
		<cfloop array="#children#" index="col">
			<cfset attributes.columns = listAppend(attributes.columns,col.getAttribute('name')) />
			<cfif col.getAttribute('display') AND attributes.firstVisibleColumn IS "">
				<cfset attributes.firstVisibleColumn = col.getAttribute('name') />
			</cfif>
		</cfloop>
		<cfif attributes.defaultSortColumn IS "">
			<cfset attributes.defaultSortColumn = attributes.firstVisibleColumn />
		</cfif>

		<cfscript>
			if(len(trim(generatedContent))) {
				attributes.content = generatedContent;
			}
			if(attributes.format Neq "html") {
				writeOutput('This tag only supports the HTML grid format.');
				abort;
			}
			addJS(attributes);
			writeOutput(buildTable(attributes));
		</cfscript>

		<cfreturn false/>
	</cffunction>

	<cffunction name="setAttributes" output="false" access="public" returntype="struct">
		<cfargument name="attributes" required="true" type="struct" />
		<cfloop collection="#this.metadata.attributes#" index="a">
			<cfif NOT structKeyExists(arguments.attributes,a)>
				<cfif structKeyExists(this.metadata.attributes[a],'default')>
					<cfset arguments.attributes[a] = this.metadata.attributes[a]['default'] />
				</cfif>	
			</cfif> 
		</cfloop>
		<cfreturn arguments.attributes />
    </cffunction>

    <!---  children   --->
	<cffunction name="getChildren" access="public" output="false" returntype="array">
		<cfreturn variables.children/>
	</cffunction>
	
	<!---	addChild	--->
    <cffunction name="addChild" output="false" access="public" returntype="void">
    	<cfargument name="child" required="true" type="gridcolumn" />
		<cfset children = getchildren() />
		<cfset children.add(arguments.child) />
    </cffunction>

    <!--- build the table HTML --->
	<cffunction name="buildTable" output="false" hint="for calling from function, etc.">

		<cfargument name="attributes" required="true" />

		<cfsavecontent variable="grid">
		<cfoutput>
			<table name="#attributes.name#" id="#attributes.name#" class="display<cfif attributes.compact> compact</cfif>" cellspacing="0" width="#attributes.width#" <cfif attributes.style GT "">style="#attributes.style#"</cfif>>
				<thead><tr>
				<cfif arrayIsEmpty(attributes.children)>
					<cfif isQuery(attributes.query)>
						<cfset var columnAry = querycolumnarray(attributes.query) />
						<cfloop array="#columnAry#" index="c">
							<th>#c#</th>
						</cfloop>
					</cfif>	
				<cfelse>
					<cfloop array="#attributes.children#" index="c">
						<th>
							<cfif c.getAttribute('header') GT "">
								#c.getAttribute('header')#
							<cfelse>
								#c.getAttribute('name')#
							</cfif>
						</th>
					</cfloop>
				</cfif>
				
				</tr></thead>
				<tbody>
					<cfif attributes.bind IS "">
						<cfif arrayIsEmpty(attributes.children)>
							<cfif isQuery(attributes.query)>
								<cfloop query="attributes.query" endrow="#attributes.maxrows#">
									<tr>
										<cfloop array="#columnAry#" index="c">
											<td>#attributes.query[c]#</td>
										</cfloop>
									</tr>
								</cfloop>	
							</cfif>
						<cfelse>
							<cfloop query="attributes.query" endrow="#attributes.maxrows#">
								<tr>
									<cfloop array="#attributes.children#" index="c">
										<td>#attributes.query[c.getAttribute('name')]#</td>
									</cfloop>
								</tr>
							</cfloop>						
						</cfif>
					</cfif>
				</tbody>
			</table>
		</cfoutput>
	</cfsavecontent>

		<cfreturn grid />
	</cffunction>

	<!--- Add JavaScript functions --->
	<cffunction name="addJS">
		<cfargument name="attributes" type="struct" />
		
		<!--- Include the javascript, once time per page --->
		<cfparam name="request.cfgridincluded" default="0" />
		<cfif NOT request.cfgridincluded>
			<cfsavecontent variable="js">
				<cfif attributes.includeJQuery>
					<script src="//code.jquery.com/jquery-2.2.4.min.js" integrity="sha256-BbhdlvQf/xTY9gja0Dq3HiwQF8LaCRTXxZKRutelT44=" crossorigin="anonymous"></script>		
				</cfif>
				<cfif attributes.includeDatatables>
					<script src="//cdn.datatables.net/1.10.13/js/jquery.dataTables.min.js"></script>	
				</cfif>
				<cfif attributes.includeBootstrap>
			  		<script src="//cdn.datatables.net/1.10.13/js/dataTables.bootstrap.min.js"></script>
			  	</cfif>
			  	<cfif isArray(attributes.customJS)>
		  			<cfloop array="#attributes.customJS#" index="a">
		  				<cfoutput><script src="#a#"></script></cfoutput>
		  			</cfloop>
		  		<cfelseif attributes.customJS GT "">
		  			<script src="#attributes.customJS#"></script>
		  		</cfif>
		  		<!--- cross-compatilbity with a common Adobe CF function --->
		  		<script>
		  			var ColdFusion = {};
		  			ColdFusion.Grid = {};
		  			ColdFusion.Grid.refresh = function(gridid) {
		  				$('#'+gridid).DataTable().ajax.reload();
		  			};
		  		</script>
			</cfsavecontent>
			<!--- Now, add to the DOM --->
			<cfif attributes.jsAtBottom>
				<cfhtmlbody action="append" text="#js#" />
			<cfelse>
				<cfhtmlhead text="#js#" />
			</cfif>
		
			<cfsavecontent variable="css">
		  		<cfif attributes.includeBootstrap>
		  			<link type="text/css" href="//cdn.datatables.net/1.10.13/css/dataTables.bootstrap.min.css" rel="stylesheet" />
					<link type="text/css" href="//maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" rel="stylesheet" />
				</cfif>
				<cfif attributes.includeDatatablesCSS>
					<link type="text/css" href="//cdn.datatables.net/1.10.13/css/jquery.dataTables.min.css" rel="stylesheet" />
				</cfif>
				<cfif isArray(attributes.customCSS)>
		  			<cfloop array="#attributes.customCSS#" index="a">
		  				<cfoutput><link type="text/css" href="#a#" rel="stylesheet" /></cfoutput>
		  			</cfloop>
		  		<cfelseif attributes.customCSS GT "">
		  			<cfoutput><link type="text/css" href="#attributes.customCSS#" rel="stylesheet" /></cfoutput>
		  		</cfif>
				<!--- used for cfgridcolumn dataAlign attribute --->
				<style>
					.dt-cell-left {text-align:left}
					.dt-cell-center {text-align:center}
					.dt-cell-right {text-align:right}
				</style>
			</cfsavecontent>
			<!--- Now, add to the DOM --->
			<cfif attributes.cssAtBottom>
				<cfhtmlbody action="append" text="#css#" />
			<cfelse>
				<cfhtmlhead text="#css#" />
			</cfif>
			<cfset request.cfgridincluded = 1 />
		</cfif>

		<!--- This is included once for EACH instance of CFGRID loaded --->
		<cfsavecontent variable="dtcall">
			<cfoutput>
				<script>
					$(document).ready(function() {
						$('###attributes.name#').DataTable({
							<cfif attributes.bind GT ""><cfset binddata = getBindArgs(attributes.bind) />
							#buildBindConfig(binddata)#
							</cfif>
							"columnDefs": #buildColumnConfig(attributes.children)#,
							"pageLength" : #attributes.pagesize#,
							"autoWidth" : #attributes.autowidth#,
							"ordering" : #truefalsetext(attributes.sort)#,
							"lengthChange": #truefalsetext(attributes.lengthChange)#,
							<cfif listFindNoCase(attributes.columns,attributes.firstVisibleColumn)>"order" : [[#listFindNoCase(attributes.columns,attributes.defaultSortColumn)-1#, '#attributes.defaultSortDir#']],</cfif>
							"searching" : #truefalsetext(attributes.search)#,
							"drawCallback": function(settings) {
								<cfif attributes.href GT "">
									<cfset cellindex = listFindNoCase(attributes.columns,attributes.hrefKey,",")-1 />
									var api = this.api();
									this.find('tr').on('click', 'td', function(){
										var keyval = api.rows( {page:'current'} ).data()[$(this).parent().index()][#cellindex#]
										<cfif attributes.href CONTAINS "javascript:">
											#replace(attributes.href,'{key}','keyval')#
										<cfelse>
									 		location.href="#attributes.href#"<cfif attributes.hrefKey GT "">+keyval</cfif>;		
										</cfif>
									}).on('mouseover','td',function() {
										$(this).siblings().andSelf().css('backgroundColor','RGBA(128,128,128,0.2)').css('cursor','pointer');
									}).on('mouseout','td',function() {
										$(this).siblings().andSelf().css('backgroundColor','inherit').css('cursor','auto');
									});
								</cfif>
								<!--- Listeners, if they exist. Initial value is passed in buildBindConfig, but these are listeners for changes. --->
				                <cfif attributes.bind GT "">
				                <cfloop from="1" to="#arraylen(binddata.args)#" index="a">
									<cfif NOT listFindNoCase("{cfgridpage},{cfgridpagesize},{cfgridsortcolumn},{cfgridsortdirection}",binddata.args[a])>
										<cfif left(binddata.args[a],1) IS "{" AND right(binddata.args[a],1) IS "}">
											<!--- for items with a @ listener --->
											<cfset bindid = rereplace(getToken(binddata.args[a],1,"@"),"[\}\{]","","ALL") />
											<cfset bindevent = rereplace(getToken(binddata.args[a],2,"@"),"[\}\{]","","ALL") />
											<cfif bindevent IS "">
												<cfset bindevent="change" />
											</cfif>
											$('###jsstringformat(bindid)#').off('#bindevent#').on('#bindevent#',function() {
												$('###attributes.name#').DataTable().ajax.reload();
											});
										</cfif>
									</cfif> 
						        </cfloop>
						        </cfif>
								#attributes.onload#
							}
						});	

					});
				</script>
			</cfoutput>
		</cfsavecontent>

		<!--- Now, add to the DOM --->
		<cfif attributes.jsAtBottom>
			<cfhtmlbody action="append" text="#dtcall#" />
		<cfelse>
			<cfhtmlhead text="#dtcall#" />
		</cfif>
	</cffunction>

	<!--- set up the the column config --->
	<cffunction name="buildColumnConfig" output="false">
		<cfargument name="columns" type="array" />
		<cfset var rtn = "" />
		<cfloop from="1" to="#arrayLen(arguments.columns)#" index="c">
			<cfset thiscol = '{"targets":[ #c-1# ]' />
			<cfset thiscol = thiscol & ',"visible": #truefalsetext(arguments.columns[c].getAttribute('display'))#' />
			<cfif arguments.columns[c].getAttribute('width') GT "">
				<cfset thisCol = thisCol & ',"width":"#arguments.columns[c].getAttribute('width')#"' />
			</cfif>
			<cfif arguments.columns[c].getAttribute('type') GT "">
				<cfset thisCol = thisCol & ',"type":"#translateType(arguments.columns[c].getAttribute('type'))#"' />
			</cfif>
			<cfset idkey = "" />
			<cfif attributes.hrefKey GT "" AND arguments.columns[c].getAttribute('name') IS attributes.hrefKey>
				<cfset idkey = "row-key" />
			</cfif>
			<cfif arguments.columns[c].getAttribute('dataAlign') GT "">
				<cfset thisCol = thisCol & ',"className":"dt-cell-#arguments.columns[c].getAttribute('dataAlign')# #idkey#"' />
			<cfelse>
				<cfset thisCol = thisCol & ',"className":"#idkey#"' />
			</cfif>
			<cfset thisCol = thisCol & "}" />
			<cfset rtn = rtn & thiscol />
			<cfif c Neq arrayLen(arguments.columns)>
				<cfset rtn = rtn & "," />
			</cfif>
		</cfloop>
		<cfreturn "[" & rtn & "]" />
	</cffunction>

	<!--- Get the arguments that were passed in to the bind --->
	<cffunction name="getBindArgs" output="false">
		<cfargument name="bindString" type="string" />
		<cfset var binddata = structnew() />
		<cfset var ajaxpath = replacenocase(arguments.bindstring,"cfc:","") />
		<cfset var methodAndArgs = listLast(ajaxpath,".") />
		<cfset var cfcPath = replacenocase(ajaxpath,'.'&methodAndArgs,"") />
		<cfset var method = getToken(methodAndArgs,1,"(") />
		<cfset var args = getToken(methodAndArgs,2,"(") />
		<cfset var loadCFC = createObject('component',cfcPath) />
		<cfset var functionmeta = GetMetaData( loadCFC[method] ) />
		
		<cfif len(args) GT 1>
			<cfset args = left(args,len(args)-1) />
		<cfelse>
			<cfset args = "" />
		</cfif>
		<cfset binddata.args = listToArray(args,",") />
		
		<cfset ajaxpath = "/" & replacenocase(ajaxpath,".","/","ALL") />
		<cfset binddata.ajaxpath = replacenocase(ajaxpath,"/#methodAndArgs#",".cfc?method=#method#") />

		<cfset binddata.parameters = functionmeta.parameters />

		<cfreturn binddata />

	</cffunction>

	<!--- set up the the column config --->
	<cffunction name="buildBindConfig" output="false">
		<cfargument name="binddata" type="struct" />
		<Cfset var binddata = arguments.binddata />
		<cfsavecontent variable="rtn"><cfoutput>
		"processing": true,
        "serverSide": true,
        "ajax": {"url": "#binddata.ajaxpath#",
            "type": "POST",
            "data": function ( d ) {
                d.columns = '#attributes.columns#';
                // these are here for backward compatibility and default sorting (on binds).
                d.pageSize = #attributes.pageSize#;
                d.page = 1;
                d.gridsortcolumn = '#attributes.defaultSortColumn#';
                d.gridsortdir = '#attributes.defaultSortDir#';
                <!--- Here, we will pass anything that was in the bind arguments. The built-in 
                CFGRID {cfgrid...} values are ignored because they are not valid for Datatables. --->
                <cfloop from="1" to="#arraylen(binddata.args)#" index="a">
					<cfif NOT listFindNoCase("{cfgridpage},{cfgridpagesize},{cfgridsortcolumn},{cfgridsortdirection}",binddata.args[a])>
						<cfif left(binddata.args[a],1) IS "{" AND right(binddata.args[a],1) IS "}">
							<!--- for items with a @ listener, we will pass the initial value here, but set up the listener in the callback later --->
							d.#binddata.parameters[a].name#=$('###jsstringformat(rereplace(getToken(binddata.args[a],1,"@"),"[\}\{]","","ALL"))#').val();
						<cfelse>
							d.#binddata.parameters[a].name#='#jsstringformat(replace(binddata.args[a],"'","","ALL"))#';
						</cfif>
					</cfif> 
		        </cfloop>
            }
        },	
    	</cfoutput></cfsavecontent>
		<cfreturn rtn />
	</cffunction>

	<cffunction name="truefalsetext" output="false">
		<cfargument name="exp" />
		<cfif exp>
			<cfreturn "true" />
		<cfelse>
			<cfreturn "false" />
		</cfif>
	</cffunction>
	<cffunction name="translateType" output="false">
		<cfargument name="exp" />
		<cfswitch expression="#arguments.exp#">
			<cfcase value="numeric">
				<cfreturn "num-fmt" />
			</cfcase>	
			<cfcase value="date">
				<cfreturn "date" />
			</cfcase>
			<cfdefaultcase>
				<cfreturn "string" />
			</cfdefaultcase>		
		</cfswitch>
	</cffunction>

</cfcomponent>
