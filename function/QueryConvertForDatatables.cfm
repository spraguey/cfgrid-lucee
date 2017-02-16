<cffunction name="QueryConvertForDatatables" returntype="any" output="false" returnformat="json">
	<cfargument name="query" type="query" required="true" />
	<cfargument name="dtformscope" type="struct" required="false" default="#structNew()#" />
	
	<cfif structIsEmpty(arguments.dtformscope)>
		<!-- if the passed form scope is empty (not passed), use the real form scope --->
		<cfset arguments.dtformscope  = form />
	</cfif>

	<cfif not structKeyExists(arguments.dtformscope,"columns")>
		<cfthrow type="Application" message="DataTables form scope must be present and passed in to use the QueryConvertForDatatables function." />
	</cfif>

	<!--- first, manipulate the query based on the data passed through the dataTables post --->
	<cfquery name="arguments.query" dbtype="query">
		SELECT * FROM arguments.query
		WHERE <cfloop list="#arguments.dtformscope.columns#" index="c">
			#c# LIKE '%#arguments.dtformscope["search[value]"]#%' <cfif c NEQ listlast(arguments.dtformscope.columns)> OR </cfif>
		</cfloop>
		<cfif structKeyExists(arguments.dtformscope,"order[0][column]")>
			ORDER BY #getToken(arguments.dtformscope.columns,arguments.dtformscope["order[0][column]"]+1,",")# #arguments.dtformscope["order[0][dir]"]#
		<cfelse>
			ORDER BY #getToken(arguments.dtformscope.columns,1,",")#
		</cfif>
		
	</cfquery>

	<cfset json = structNew() />
	<cfset json['draw'] = arguments.dtformscope.draw />
	<cfset json['recordsTotal'] = arguments.query.recordcount />
	<cfset json['recordsFiltered'] = arguments.query.recordcount />
	<cfset json['columns'] = arrayNew(1) />
	<cfloop list="#arguments.dtformscope.columns#" index="c">
		<cfset thiscol = arrayNew(1) />
		<cfset thiscol[1] = c />
		<cfset arrayAppend(json['columns'],thiscol) />
 	</cfloop>
	<cfset json['data'] = arrayNew(1) />
	<cfoutput query="#arguments.query#" startrow="#arguments.dtformscope.start+1#" maxrows="#arguments.dtformscope.length#">
		<cfset thisrecord = arrayNew(1) />
		<cfloop list="#arguments.dtformscope.columns#" index="c">
			<cfset arrayAppend(thisrecord,arguments.query[c]) />
		</cfloop>
		<cfset arrayAppend(json.data,thisrecord) />
	</cfoutput>
	<cfreturn json />
</cffunction>
