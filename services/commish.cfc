<cfcomponent extends="common">

<cffunction name="checkSpecial" hint="before Inserting, check that this isn't a duplicate">
	<cfargument name="t">
	<cfargument name="player">
	<cfargument name="checkThis" hint="either buy-in or re-buy" default="buy-in">
	<cfset var checker = "">
	<cfquery name="checker">
		SELECT specialID
		FROM special
		WHERE tourneyID = <cfqueryparam value="#arguments.t#" cfsqltype="cf_sql_integer">
		AND userID = <cfqueryparam value="#arguments.player#" cfsqltype="cf_sql_integer">
		<cfif arguments.checkThis EQ "re-buy">
			AND displayText = "Re-buy"
		<cfelse>
			AND round = 0
		</cfif>
	</cfquery>
	<cfif checker.recordcount>
		<cfreturn true>
	<cfelse>
		<cfreturn false>
	</cfif>
</cffunction>

<cffunction name="markAsPaid" hint="updates enteredIn - hasPaid">
	<cfargument name="t">
	<cfargument name="player">
	<cfset var hasPaid = "">
	<cftry>
		<cfquery name="hasPaid">
			UPDATE enteredIn
			SET hasPaid = 1
			WHERE tourneyID = <cfqueryparam value="#arguments.t#" cfsqltype="cf_sql_integer">
			AND userID = <cfqueryparam value="#arguments.player#" cfsqltype="cf_sql_integer">
		</cfquery>
		<cfreturn true>
		<cfcatch>
			<cfset logDbError( cfcatch, "commish.markAsPaid" )>			
			<cfreturn false>
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="addBankroll" hint="you get the $2000 starting amount">
	<cfargument name="t">
	<cfargument name="player">
	<cfset var adder = "">
	<cftry>
		<cfquery name="adder">
			INSERT INTO special ( userID, tourneyID, amount, displayText, whenPlaced, round )
			VALUES ( <cfqueryparam value="#arguments.player#" cfsqltype="cf_sql_integer">,
					 <cfqueryparam value="#arguments.t#" cfsqltype="cf_sql_integer">,
					 2000, 
					 'League Buy-In',
					 #DateConvert( 'local2Utc', now() )#,
					 0 );
		</cfquery>
		<cfreturn true>
		<cfcatch>
			<cfset logDbError( cfcatch, "commish.addBankroll" )>			
			<cfreturn false>
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="markRebuy" hint="updates enteredIn - Rebuy">
	<cfargument name="t">
	<cfargument name="player">
	<cfset var markRebuy = "">
	<cftry>
		<cfquery name="markRebuy">
			UPDATE enteredIn
			SET rebuy = 1
			WHERE tourneyID = <cfqueryparam value="#arguments.t#" cfsqltype="cf_sql_integer">
			AND userID = <cfqueryparam value="#arguments.player#" cfsqltype="cf_sql_integer">
		</cfquery>
		<cfreturn true>
		<cfcatch>
			<cfset logDbError( cfcatch, "commish.markRebuy" )>			
			<cfreturn false>
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="addRebuy" hint="you get the $2000 starting amount">
	<cfargument name="t">
	<cfargument name="player">
	<cfargument name="bankroll">
	<cfargument name="currentRound">
	<cfset var addit = "">
	<cfset local.addAmount = 2000 - arguments.bankroll>
	<cftry>
		<cfquery name="addit">
			INSERT INTO special ( userID, tourneyID, amount, displayText, whenPlaced, round )
			VALUES ( <cfqueryparam value="#arguments.player#" cfsqltype="cf_sql_integer">,
					 <cfqueryparam value="#arguments.t#" cfsqltype="cf_sql_integer">,
					 <cfqueryparam value="#local.addAmount#" cfsqltype="cf_sql_double">,
					 'Re-buy',
					 #DateConvert( 'local2Utc', now() )#,
					 <cfqueryparam value="#arguments.currentRound#" cfsqltype="cf_sql_integer"> );
		</cfquery>
		<cfreturn true>
		<cfcatch>
			<cfset logDbError( cfcatch, "commish.addRebuy" )>			
			<cfreturn false>
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="updateStatus" hint="open or closed; allow new players?">
	<cfargument name="t">
	<cfargument name="status">
	<cfset var updateS = "">
	<cfif arguments.status EQ "open" OR arguments.status EQ "ongoing">
		<cftry>
			<cfquery name="updateS">	
				UPDATE tourneys
				SET status = <cfqueryparam value="#arguments.status#">
				WHERE tourneyID = <cfqueryparam value="#arguments.t#" cfsqltype="cf_sql_integer">
			</cfquery>
			<cfcatch>
				<cfset logDbError( cfcatch, "commish.updateStatus" )>						
				<cfreturn false>
			</cfcatch>
		</cftry>
	</cfif>
	<cfreturn true>
</cffunction>

<cffunction name="updateSuicide" hint="change options for suicide pool">
	<cfargument name="t">
	<cfargument name="suicideStarts">
	<cfargument name="suicideType">
	<cfargument name="suicidePrize">
	<cfset var updateFun = "">
	<cftry>
		<cfquery name="updateFun">
			UPDATE tourneys
			SET suicideStarts = <cfqueryparam value="#arguments.suicideStarts#" cfsqltype="cf_sql_integer">,
				suicideType = <cfqueryparam value="#arguments.suicideType#">,
				suicidePrize = <cfqueryparam value="#arguments.suicidePrize#" cfsqltype="cf_sql_integer">	
			WHERE tourneyID = <cfqueryparam value="#arguments.t#" cfsqltype="cf_sql_integer">
		</cfquery>
		<cfcatch>
			<cfset logDbError( cfcatch, "commish.updateSuicide" )>						
			<cfreturn false>		
		</cfcatch>
	</cftry>
	<cfreturn true>
</cffunction>

</cfcomponent>