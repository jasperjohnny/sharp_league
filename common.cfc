<cfcomponent>

<cffunction name="convertTime" hint="can convert a UTC datetime object to a named timezone or the reverse">
	<cfargument name="datetime" default="#DateConvert( 'local2Utc', now() )#">
	<cfargument name="timezone" default="America/New_York" hint="java timezones">
	<cfargument name="conversionType" default="UTCtoNamedTZ" hint="other option would be NamedTZtoUTC">
	<cfset var local = {} />

	<!---first need to convert the passed datetime to Java epoch time (milliseconds since January 1, 1970)--->
	<cfset local.inEpochTime = arguments.datetime.getTime() />

	<!---the TimeZone java class has the UTC offsets for timezones on differnet dates and figures in daylight savings too---> 
	<cfset local.timezoneClass = createObject( "java", "java.util.TimeZone" ) />
	<cfset local.tz = local.timezoneClass.getTimeZone( arguments.timezone ) />
	<cfset local.offSet = local.tz.getOffset( local.inEpochTime ) />

	<!---add the offset and return the time--->
	<cfif arguments.conversionType EQ "UTCtoNamedTZ">
		<cfset local.theNewTime = dateAdd( "l", local.offSet, arguments.datetime ) />	
	<cfelse>
		<cfset local.theNewTime = dateAdd( "l", local.offSet * -1, arguments.datetime ) />	
	</cfif>
	<cfreturn local.theNewTime />
</cffunction>

<cffunction name="logThis" hint="all purpose logging method">
	<cfargument name="contents" required="true">
	<cfargument name="fileName" required="false" default="general">	
	<cfset var logFile = expandPath( "/" ) & "logs/" & dateFormat( now(),"mmddyyyy" ) & "_" & arguments.fileName & ".txt">
	<cftry>
		<cfif FileExists( logFile )>
			<cffile action="append" addNewLine="true" file="#logFile#" output="#arguments.contents#">
		<cfelse>
			<cffile action="write" file="#logFile#" output="#arguments.contents#">
		</cfif>
		<cfreturn true>
		<cfcatch>
			<cfreturn false>
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="logDbError" hint="for cfcatch in services">
	<cfargument name="catch">
	<cfargument name="method">
	<cfset var errorMessage = "">
	<cfsavecontent variable="errorMessage"><cfoutput>
#dateFormat( now(), "long")#, #timeFormat( now(), "short")# => "#arguments.method#"
#arguments.catch.message#
<cfif structKeyExists( arguments.catch, "SQL" )>#arguments.catch.SQL#</cfif>	
-------------------------------------------
	</cfoutput></cfsavecontent>
	<cfset logThis( errorMessage, "SQL" )>
</cffunction>

<cffunction name="didIwin" hint="given score and bet info, returns win, loss, or push status">
	<cfargument name="homeScore">
	<cfargument name="awayScore">
	<cfargument name="optionID">
	<cfargument name="mark">
	
	<cfswitch expression="#arguments.optionID#">
		<cfcase value="1"><!---away team with spread--->
			<cfif arguments.awayScore + arguments.mark GT arguments.homeScore>
				<cfset local.outcome = "win">
			<cfelseif arguments.awayScore + arguments.mark EQ arguments.homeScore>
				<cfset local.outcome = "push">
			<cfelse>
				<cfset local.outcome = "loss">
			</cfif>        
		</cfcase>
		<cfcase value="2"><!---away team moneyline--->
			<cfif arguments.awayScore GT arguments.homeScore>
				<cfset local.outcome = "win">
			<cfelseif arguments.awayScore EQ arguments.homeScore>
				<cfset local.outcome = "push">
			<cfelse>
				<cfset local.outcome = "loss">
			</cfif>
		</cfcase>
		<cfcase value="3"><!---home team with spread--->
			<cfif arguments.homeScore + arguments.mark GT arguments.awayScore>
				<cfset local.outcome = "win">
			<cfelseif arguments.homeScore + arguments.mark EQ arguments.awayScore>
				<cfset local.outcome = "push">
			<cfelse>
				<cfset local.outcome = "loss">
			</cfif>
		</cfcase>			
		<cfcase value="4"><!---home team moneyline--->
			<cfif arguments.homeScore GT arguments.awayScore>
				<cfset local.outcome = "win">
			<cfelseif arguments.homeScore EQ arguments.awayScore>
				<cfset local.outcome = "push">
			<cfelse>
				<cfset local.outcome = "loss">
			</cfif>
		</cfcase>
		<cfcase value="5"><!---over--->
			<cfif arguments.homeScore + arguments.awayScore GT arguments.mark>
				<cfset local.outcome = "win">
			<cfelseif arguments.homeScore + arguments.awayScore EQ arguments.mark>
				<cfset local.outcome = "push">
			<cfelse>
				<cfset local.outcome = "loss">
			</cfif>			      	
		</cfcase>
		<cfcase value="6"><!---under--->
			<cfif arguments.homeScore + arguments.awayScore LT arguments.mark>
				<cfset local.outcome = "win">
			<cfelseif arguments.homeScore + arguments.awayScore EQ arguments.mark>
				<cfset local.outcome = "push">
			<cfelse>
				<cfset local.outcome = "loss">
			</cfif>			      	
		</cfcase>			
	</cfswitch>	

	<cfreturn local.outcome />
</cffunction>

<cffunction name="isPasswordOK" hint="must be >8 and have a number">
	<cfargument name="password">
	<cfif len( trim( arguments.password ) ) GTE 8 AND reFind( "[0-9]", arguments.password )  >
		<cfreturn true>
	<cfelse>
		<cfreturn false>
	</cfif>
</cffunction>

<cffunction name="roundTo2" hint="rounds to 2 decimal places">
	<cfargument name="theNumber">
	<cfreturn round( arguments.theNumber * 100) / 100>
</cffunction>

<cffunction name="getCurrentRound">
	<cfargument name="league">
	<cfargument name="season">
	<cfset local.getRound = "">
	<cfquery name="getRound">
		SELECT currentRound 
		FROM v_CurrentRound
		WHERE league = <cfqueryparam value="#arguments.league#">
		AND season = <cfqueryparam value="#arguments.season#" cfsqltype="cf_sql_integer">
	</cfquery>
	<cfreturn getRound.currentRound />
</cffunction>

<cffunction name="getSundaykickoff" hint="gets the timestamp for the sunday start for a current week">
	<cfargument name="season">
	<cfargument name="league">
	<cfargument name="currentRound">
	<cfquery name="getKickoff">
		SELECT gametime
		FROM games
		WHERE round = <cfqueryparam value="#arguments.currentRound#" cfsqltype="integer">
		AND league = <cfqueryparam value="#arguments.league#">
		AND season = <cfqueryparam value="#arguments.season#">
		AND weekday(gametime) = 6
		ORDER BY gametime
		LIMIT 1		
	</cfquery>
	<cfreturn getKickoff.gametime>
</cffunction>

</cfcomponent>