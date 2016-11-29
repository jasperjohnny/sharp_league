<cfoutput>

<style type="text/css">
	.span4, .span8, .center { display: none; }
</style>

<cfobject component="common" name="commonObj" />
<cfobject component="services._admin" name="servObj" />

<cfoutput>
	
<!--- 
	Now: #now()#
	Now EST: #commonObj.convertTime()#

	#servObj.convertDayTimeToUTC( "Thu", "8:20" )#


<cfset timeBlah = "1:30">

<br />
#hour( timeBlah & "pm" )#
 --->

<cffunction name="roundTo2" hint="rounds to 2 decimal places">
	<cfargument name="theNumber">
	<cfreturn round( arguments.theNumber * 100) / 100>
</cffunction>

<cfset numb = 17.5337878>
#numb# gets rounded to #round(numb * 100) / 100# ALSO #roundTo2( numb )#

<br />#replace( cgi.server_name, "www.", "" )#

<Cfdump var="#cgi#">

</cfoutput>

</cfoutput>