<cfcomponent name="gridcolumn">
	<cfset this.metadata.attributetype="mixed">
	<cfset this.metadata.attributes={
		name:{required:true,type:"string"},
		header:{required:false,default:"",type:"string"},
		display:{required:false,default:1,type:"boolean"},
		width:{required:false,default:'',type:"string"},
		type:{required:false,default:'',type:"string"},
		dataAlign:{required:false,default:'',type:"string"}
	}/>
	<cfset _log = [] />
	<cffunction name="onStartTag" output="yes" returntype="boolean">

		<cfargument name="attributes" type="struct">
		<cfargument name="caller" type="struct">

		<cfset var parent = getParent() />

		<cfif structKeyExists(attributes,"argumentCollection")>
			<cfset arguments.attributes = attributes.argumentCollection />
		</cfif>
		
		<!--- this sets the defaults for undefined attributes.  Not sure why this is needed. --->
		<cfset variables.attributes=setAttributes(arguments.attributes) />

		<cfif not variables.hasEndTag>
			<cfset onEndTag(attributes,caller,"") />
		</cfif>

		<cfreturn variables.hasEndTag>
	</cffunction>
	<cffunction name="onEndTag" output="yes" returntype="boolean">

		<cfargument name="attributes" type="struct">
		<cfargument name="caller" type="struct">
		<cfargument name="generatedContent" type="string">
		
		<cfset var parent = getParent() />
		<cfset variables['generatedContent'] = 	arguments.generatedContent />
		<cfset parent.addChild(this) />
		
		<cfscript>
			if(len(trim(generatedContent))) {
				attributes.content = generatedContent;
			}

			writeOutput(runAction(attributes));
		</cfscript>

		<cfreturn false/>
	</cffunction>
	<cffunction name="runAction" output="false" hint="for calling from function, etc.">

		<cfargument name="attributes" required="true" />

		<cfsavecontent variable="grid">
			<table border="1">
				<tr>
					<td>This is where a grid would be, if the grid was nice to me.</td>
				</tr>
			</table>
		</cfsavecontent>

		<cfreturn grid />
	</cffunction>
    <!---   parent   --->
	<cffunction name="getparent" access="public" output="false" returntype="grid">
		<cfreturn variables.parent/>
	</cffunction>
	<!---getGeneratedContent--->
    <cffunction name="getGeneratedContent" output="false" access="public" returntype="string">
    	<cfreturn variables.generatedContent />
    </cffunction>
	
	<!---   attributes   --->
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
	<cffunction name="getAttributes" access="public" output="false" returntype="struct">
		<cfreturn variables.atttributes/>
	</cffunction>

    <cffunction name="getAttribute" output="false" access="public" returntype="any">
		<cfargument name="key" required="true" type="String" />
    	<cfreturn variables.attributes[key] />
    </cffunction>

    <!--- init --->
	<cffunction name="init" output="no" returntype="void" hint="invoked after tag is constructed">
		<cfargument name="hasEndTag" type="boolean" required="yes" />
		<cfargument name="parent" type="component" required="no" hint="the parent cfc custom tag, if there is one" />
		<cfset variables.hasEndTag = arguments.hasEndTag />
      	<cfset variables.parent = arguments.parent />
	</cffunction>
</cfcomponent>
