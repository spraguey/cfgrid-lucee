<cfcomponent name="grid">
	<cfset this.metadata.attributetype="mixed">
	<cfset this.metadata.attributes={
		// Standard CFML attributes that match Adobe CF
		name:			{required:true,type:"string"},
		format:      	{required:false,type:"string",default:"html"},
		bind:  			{required:false,type:"string",default:"",hint:""},	
		query: 			{required:false,type:"query",default:"",hint:""},	
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
		includeJQuery:    	{required:false,type:"boolean",default:true,hint:"Set to false to use your own jQuery (1.12+)."},
		includeBootstrap:   {required:false,type:"boolean",default:true,hint:"Set to false to use your own css for styling."},
		customJS:      	{required:false,type:"any",default:"",hint:"Pass a single path to a js file, or an array of paths."},
		customCSS:      	{required:false,type:"any",default:"",hint:"Pass a single path to a css file, or an array of paths."}
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
			<table name="#attributes.name#" id="#attributes.name#" class="table table-striped table-bordered" cellspacing="0" width="#attributes.width#" <cfif attributes.style GT "">style="#attributes.style#"</cfif>>
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
							<cfif attributes.bind GT "">#buildBindConfig(attributes.bind)#</cfif>
							"columnDefs": #buildColumnConfig(attributes.children)#,
							"pageLength" : #attributes.pagesize#,
							"autoWidth" : #attributes.autowidth#,
							"ordering" : #truefalsetext(attributes.sort)#,
							"order" : [[#listFindNoCase(attributes.columns,attributes.firstVisibleColumn)-1#, 'asc']],
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

	<!--- set up the the column config --->
	<cffunction name="buildBindConfig" output="false">
		<cfargument name="bindstring" type="string" />
		<cfset var rtn = "" />
		<cfset var ajaxpath = replace(arguments.bindstring,"cfc:","") />
		<cfset var methodAndArgs = listLast(ajaxpath,".") />
		<cfset var method = getToken(methodAndArgs,1,"(") />
		<cfset ajaxpath = "/" & replace(ajaxpath,".","/","ALL") />
		<cfset ajaxpath = replace(ajaxpath,"/#methodAndArgs#",".cfc?method=#method#") />
		<cfsavecontent variable="rtn"><cfoutput>
		"processing": true,
        "serverSide": true,
        "ajax": {"url": "#ajaxpath#",
            "type": "POST",
            "data": function ( d ) {
                d.columns = '#attributes.columns#';
                // these are here for backward compatibility and default sorting (on binds).
                d.pageSize = #attributes.pageSize#;
                d.page = 1;
                d.gridsortcolumn = '#attributes.firstVisibleColumn#';
                d.gridsortdir = 'ASC';
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
