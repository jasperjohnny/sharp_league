<cfcomponent extends="common">

<cffunction name="getSuicideInfo" hint="returns all picks so far" returnType="struct">
	<cfargument name="userID">
	<cfargument name="t">
	<cfargument name="suicideType" hint="either 'single' or 'double' elimination">
	<cfargument name="currentRound">
	<cfargument name="suicideStarts">
	<cfset var struct = {}>
	<cfset var getPicks = "">
	<cfset var getLosses = "">
	<cfset var checkRound = "">
	<cfquery name="getPicks">
		SELECT suicide.*, users.firstName, users.lastName
		FROM suicide
		JOIN users
		ON suicide.userID = users.userID
		WHERE tourneyID = <cfqueryparam value="#arguments.t#" cfsqltype="cf_sql_integer">
		AND round >= <cfqueryparam value="#suicideStarts#" cfsqltype="cf_sql_integer">
		ORDER BY users.lastName, users.firstName, users.userID, suicide.round
	</cfquery>
	<cfset local.struct.picks = getPicks>

	<!---get the teams picked by this user--->
	<cfquery name="getUserPicks" dbtype="query">
		SELECT team
		FROM getPicks
		WHERE userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
	</cfquery>
	<cfset local.struct.teamsPicked = valueList( getUserPicks.team )>		

	<!---now count the loses to see if the player is dead--->
	<cfquery name="countLoses" dbtype="query">
		SELECT count( result ) AS results
		FROM getPicks
		WHERE result = 'loss'
		AND userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
		GROUP BY userID
	</cfquery>
	<cfif arguments.suicideType EQ "double" AND countLoses.results LT 2>
		<cfset local.struct.isDead = false>
	<cfelseif arguments.suicideType EQ "single" AND countLoses.results LT 1>
		<cfset local.struct.isDead = false>	
	<cfelse>
		<cfset local.struct.isDead = true>
	</cfif>

	<!---has chosen for this week?--->
	<cfquery name="checkRound" dbtype="query">
		SELECT team
		FROM getPicks
		WHERE round = <cfqueryparam value="#arguments.currentRound#" cfsqltype="cf_sql_integer">
		AND userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
	</cfquery>
	<cfset local.struct.currentPick = checkRound.team>
	<cfset local.struct.currentTeam = getTeamFromCode( checkRound.team )>
	<cfreturn local.struct>
</cffunction>

<cffunction name="getWinners">
	<cfargument name="winnerList">
	<cfset getNames = "">
	<cfquery name="getNames">
		SELECT firstName, lastName
		FROM users
		WHERE userID IN (<cfqueryparam value="#arguments.winnerList#" cfsqltype="cf_sql_char" list="true">)
	</cfquery>
	<cfreturn getNames>
</cffunction>

<cffunction name="addSuicidePick" hint="nothing special here">
	<cfargument name="t">
	<cfargument name="currentRound">
	<cfargument name="thePick">
	<cfset var insertPick = "">
	<cftry>
		<cfquery name="insertPick">
			INSERT INTO suicide ( tourneyID, userID, round, team, whenPlaced, autoPicked ) 
			VALUES ( <cfqueryparam value="#arguments.t#" cfsqltype="integer">,
					 <cfqueryparam value="#session.user.userID#" cfsqltype="integer">,
					 <cfqueryparam value="#arguments.currentRound#" cfsqltype="integer">,
					 <cfqueryparam value="#arguments.thePick#">,
					 #DateConvert( 'local2Utc', now() )#,
					 0 )
		</cfquery>
		<cfcatch>
			<cfset logDbError( cfcatch, "tourney.addSuicidePick" )>									
			<cfreturn false>
		</cfcatch>
	</cftry>		
	<cfreturn true>
</cffunction>

<cffunction name="getTeamFromCode" hint="just pass it the code">
	<cfargument name="teamCode">
	<cfset var getTeam = "">
	<cfquery name="getTeam">
		SELECT area, mascot
		FROM teams
		WHERE teamCode = <cfqueryparam value="#arguments.teamCode#">
	</cfquery>
	<cfset local.teamName = getTeam.area & " " & getTeam.mascot>
	<cfreturn local.teamName>
</cffunction>

<cffunction name="isSuicidePickOK" hint="checks to see if the game has started">
	<cfargument name="team">
	<cfargument name="currentRound">
	<cfargument name="league">
	<cfargument name="season">
	<cfset var getGame = "">
	<cfquery name="getGame">
		SELECT *
		FROM games
		WHERE ( home = <cfqueryparam value="#arguments.team#"> OR away = <cfqueryparam value="#arguments.team#"> )
		AND round = <cfqueryparam value="#arguments.currentRound#" cfsqltype="integer">
		AND league = <cfqueryparam value="#arguments.league#">
		AND season = <cfqueryparam value="#arguments.season#">
		AND gametime > #DateConvert( 'local2Utc', now() )#
	</cfquery>
	<cfif getGame.recordcount>
		<cfreturn true>
	<cfelse>
		<cfreturn false>
	</cfif>
</cffunction>

<cffunction name="figureSuicideResults">
	<cfargument name="season">
	<cftry>
		<cfquery name="getData">
			SELECT suicide.*, tourneys.name, if ( sub1.away = suicide.team, 2, 4 ) as pseudoBetOption, sub1.homefinal, sub1.awayfinal, sub1.status
			FROM suicide
			JOIN tourneys
			ON suicide.tourneyID = tourneys.tourneyID

			LEFT JOIN (
				SELECT * FROM games
				WHERE league = 'NFL' 
				AND season = <cfqueryparam value="#arguments.season#" cfsqltype="cf_sql_integer"> 
				AND round = (
					SELECT currentRound
					FROM v_CurrentRound
					WHERE season = <cfqueryparam value="#arguments.season#" cfsqltype="cf_sql_integer"> 
					AND league = 'NFL'
					)
				) as sub1 
			ON suicide.team = sub1.home OR suicide.team = sub1.away

			WHERE tourneys.season = <cfqueryparam value="#arguments.season#" cfsqltype="cf_sql_integer"> 
			AND tourneys.league = 'NFL'
			AND suicide.result = 'undecided'
			AND ( sub1.status = "Final" OR sub1.status = "final overtime" )
			ORDER BY team
		</cfquery>

		<cfif getData.recordCount>
			<cfquery name="updateSuicideResults">
				<cfloop query="getData">
					<cfset local.result = this.didIwin ( getData.homeFinal, getData.awayFinal, getData.pseudoBetOption ) />
					<cfoutput>
						UPDATE suicide
						SET result = '#local.result#'
						WHERE suicideID = #getData.suicideID#;
					</cfoutput>
				</cfloop>
			</cfquery>
		</cfif>
		<cfset logThis( "#now()# - #getData.recordcount# suicide picks updated", "betUpdate" )>
		
		<cfreturn true>		
		<cfcatch>
			<cfdump var="#cfcatch#">
 			<cfset logThis( cfcatch.message, "betUpdate" )>
			<cfreturn false>		
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="newPlayerCheck" access="remote">
	<cfargument name="tourneyInfo" hint="this is passed in by using the service.">
	<cfset tempStruct = {
		league = "NFL",
		season = 2013,
		tourneyID = 49,
		sucideStarts = 1,
		suicideType = "single",
		userID = session.user.userid
	} />

	<cfdump var="#tempStruct#" />
	<!--- <cfset session.suicideCheck = arguments.tourneyInfo /> --->

</cffunction>


<!---SUICIDE AUTO-PICKER--->

<cffunction name="autoPickSuicide" access="remote">
	<cfargument name="season">
	<cfset local.currentRound = this.getCurrentRound( 'NFL', arguments.season ) />
	<cfset local.getActiveTourneys = this.getTourneysWithActiveSuicide( arguments.season, local.currentRound ) />
	<cfif local.getActiveTourneys.recordcount>
		<cfloop query="local.getActiveTourneys">
			<cfset local.lossesAllowed = ( local.getActiveTourneys.suicideType EQ "double" ? 1 : 0 )>
			<cfset local.usersMissingPick = this.getPlayersAliveWoPicks( local.getActiveTourneys.tourneyID, local.currentRound, local.lossesAllowed )>
			<cfif local.usersMissingPick NEQ "">
				<cfset this.addRandomPick( local.getActiveTourneys.tourneyID, local.usersMissingPick, local.currentRound, arguments.season )>
			</cfif>
		</cfloop>
	</cfif>
</cffunction>

<cffunction name="getTourneysWithActiveSuicide">
	<cfargument name="season">
	<cfargument name="currentRound">
	<cfset var getTs = "">
	<cfquery name="getTs">
		SELECT tourneyID, suicideType
		FROM tourneys
		WHERE league = 'NFL'
		AND season = <cfqueryparam value="#arguments.season#" cfsqltype="cf_sql_integer">		
		AND suicideType <> 'none'
		AND suicideWinner is null
		AND status <> 'closed'
		AND suicideStarts <= <cfqueryparam value="#arguments.currentRound#" cfsqltype="cf_sql_integer">
	</cfquery>
	<cfreturn getTs>
</cffunction>

<cffunction name="getPlayersAliveWoPicks">
	<cfargument name="t">
	<cfargument name="currentRound">
	<cfargument name="lossesAllowed">
	<cfset var getIDs = "">
	<cfquery name="getIDs">
		SELECT sub2.userID, sub2.tourneyID, sub3.team 
		FROM (
			SELECT enteredIn.*, if( sub1.losses is null, 0 , sub1.losses ) AS losses
			FROM enteredIn	
			LEFT JOIN ( 
				SELECT userID, sum( if( result='loss', 1, 0 ) ) AS losses
				FROM suicide
				WHERE tourneyID = <cfqueryparam value="#arguments.t#" cfsqltype="cf_sql_integer">
				GROUP BY userID
				) AS sub1
			ON enteredIn.userID = sub1.userID
			WHERE tourneyID = <cfqueryparam value="#arguments.t#" cfsqltype="cf_sql_integer">
			AND ( losses <= <cfqueryparam value="#arguments.lossesAllowed#" cfsqltype="cf_sql_integer"> OR losses is null )
			) AS sub2
		LEFT JOIN (
			SELECT userID, team
			FROM suicide
			WHERE tourneyID = <cfqueryparam value="#arguments.t#" cfsqltype="cf_sql_integer">
			AND round = <cfqueryparam value="#arguments.currentRound#" cfsqltype="cf_sql_integer">
			) AS sub3
		ON sub2.userID = sub3.userID 
		WHERE sub3.team is null	
	</cfquery>
	<cfreturn valueList( getIDs.userID )>
</cffunction>

<cffunction name="addRandomPick">
	<cfargument name="t">
	<cfargument name="userIDs" hint="a string of IDs of people without picks">
	<cfargument name="currentRound">
	<cfargument name="season">
	<cfset var insertPicks = "">
	<cfset var i = "">
	<cfquery name="insertPicks">
		INSERT INTO suicide ( tourneyID, userID, round, team, whenPlaced, autoPicked )
		VALUES
		<cfloop list="#arguments.userIDs#" index="i">
			<cfset local.randomTeam = getRandomPick( arguments.t, i, arguments.currentRound, arguments.season )>
			  ( <cfqueryparam value="#arguments.t#" cfsqltype="cf_sql_integer">, 
				<cfqueryparam value="#i#" cfsqltype="cf_sql_integer">, 
				<cfqueryparam value="#arguments.currentRound#" cfsqltype="cf_sql_integer">, 
				<cfqueryparam value="#local.randomteam#">,
				#DateConvert( 'local2Utc', now() )#,
				1 ) <cfif i NEQ listLast( arguments.userIDs )>,</cfif>
		</cfloop>
	</cfquery>
</cffunction>

<cffunction name="getRandomPick">
	<cfargument name="t">
	<cfargument name="userID">
	<cfargument name="currentRound">
	<cfargument name="season">
	<cfset var getTeam = "">
	<cfquery name="getTeam">
		SELECT teamCode
		FROM teams
		INNER JOIN (
			SELECT *
			FROM games
			WHERE league = 'NFL'
			AND season = <cfqueryparam value="#arguments.season#" cfsqltype="cf_sql_integer">
			AND round = <cfqueryparam value="#arguments.currentRound#" cfsqltype="cf_sql_integer">
			) as sub1
		ON teams.teamCode = sub1.home OR teams.teamCode = sub1.away
		LEFT JOIN (
			SELECT *
			FROM suicide
			WHERE tourneyID = <cfqueryparam value="#arguments.t#" cfsqltype="cf_sql_integer">
			AND userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
			) AS sub2
		ON teams.teamCode = sub2.team
		WHERE teams.league = 'NFL'
		AND suicideID is NULL	
	</cfquery>
	<cfset randomNum = RandRange( 1, getTeam.recordCount ) />
	<cfset randomTeam = getTeam.teamCode[ randomNum ] />
	<cfreturn randomTeam>
</cffunction>

</cfcomponent>