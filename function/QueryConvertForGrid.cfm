<cffunction name="QueryConvertForGrid" returntype="any" output="false" returnformat="json">
	<cfargument name="query" type="query" required="true" />
	<cfargument name="page" type="string" required="false" />
	<cfargument name="pagesize" type="string" required="false" />
	<cfargument name="dtformscope" type="struct" required="false" default="#structNew()#" />
	<!--- This is really just a wrapper for queryconvertfordatatables. It can be used if you cannot convert all your queryconvertforgrid calls to the datatables function --->
	<cfif NOT structIsEmpty(arguments.dtformscope)>
		<!-- if the form scope is passed as an argument, use that one --->
		<cfset passform = arguments.dtformscope />
	<cfelse>
		<!--- Otherwise use the real form scope of the current request --->
		<cfset passform = form />
	</cfif>
	<cfreturn QueryConvertForDatatables(query,passform) />
</cffunction>
