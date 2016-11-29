<cfcomponent extends="common">

<cffunction name="getTourneysWithPlayerCount">
	<cfset var getTournyes = "">
	<cfquery name="getTourneys">
		SELECT tourneys.tourneyID, tourneys.name, concat(tourneys.league, " ", tourneys.season) AS leagueseason, count( userID ) AS players
		FROM tourneys
		JOIN enteredIn
		ON tourneys.tourneyID = enteredIn.tourneyID 
		
		GROUP BY tourneys.tourneyID
		ORDER BY season DESC, league DESC, name
	</cfquery>
	<cfreturn getTourneys>
</cffunction>

<cffunction name="updateBetResults" hint="called from figureWinnersLosers() after segments are updates">
	<cfargument name="betIDs">
	<cfset var getBetInfo = "">
	<cfset var updateBets = "">
	<cfset var i = "">
	<cfset var finalResults = {} />
	<cfquery name="getBetInfo">
		SELECT bets.*, betDetail.segmentID, betDetail.line, betDetail.result AS segResult, displayText
		FROM bets
		JOIN betDetail
		ON bets.betID = betDetail.betID		
		WHERE bets.result = 'undecided'
		AND bets.betID IN ( #arguments.betIDs# )
		ORDER BY betID 
	</cfquery>

	<cfloop list="#arguments.betIDs#" index="i">
		<cfquery name="getSegments" dbType="query">
			SELECT * 
			FROM getBetInfo
			WHERE getBetInfo.betID = #i#		
		</cfquery>

		<cfif getSegments.result EQ "undecided"><!---if the whole result is undecided--->
			<cfset local.resultList = valueList( getSegments.segResult )>
			<cfif listFind( local.resultList, "loss" )>
				<!---this guy lost--->
				<cfset local.finalResults[ i ] = {
					betResult = "loss",
					finalAmount = getSegments.risked * -1
					} />
			<cfelseif listFind( local.resultList, "undecided" )>
				<!---don't do anything because some results are still needed--->
			<cfelseif local.resultList EQ "push">
				<!---bet has only one segment that is a push---> 
				<cfset local.finalResults[ i ] = {
					betResult = "push",
					finalAmount = 0
					} />
			<cfelseif NOT listFind( local.resultList, "push" )>
				<!---this guy is a winner--->
				<cfset local.finalResults[ i ] = {
					betResult = "win",
					finalAmount = getSegments.toWin
					} />
			<cfelse>
				<!---there has been all wins with a push, so recalculate payout--->
				<cfset local.multiplier = 1>
				<cfloop query="getSegments">
					<cfif getSegments.segResult NEQ "push">
						<cfset local.multiplier = local.multiplier * ( 1 + getSegments.line )>
					</cfif>
				</cfloop>
				<cfset local.multiplier = local.multiplier - 1>
				<cfset local.finalResults[ i ] = {
					betResult = "winadj",
					finalAmount = getSegments.risked * local.multiplier
					} />
			</cfif>
		</cfif>
	</cfloop>

	<cfset local.betCount = structCount( local.finalResults ) />
	<cfif local.betCount>
		<cfoutput>
		<cfquery name="updateBets">
			UPDATE bets
			SET result = CASE betID
			<cfloop collection="#local.finalResults#" item="itm">
				WHEN #itm# THEN '#local.finalResults[ itm ].betResult#'
			</cfloop>
	 		END,
				finalAmount = CASE betID
			<cfloop collection="#local.finalResults#" item="itm">
				WHEN #itm# THEN '#local.finalResults[ itm ].finalAmount#'
			</cfloop>
	 		END
			WHERE betID IN ( #StructKeyList( local.finalResults )# )
		</cfquery>
		</cfoutput>
	</cfif>
	
	<cfreturn local.betCount>
</cffunction>

<cffunction name="figureWinnersLosers" hint="can be called directly from admin or from the scheduled update task">
	<cfargument name="league">
	<cfargument name="season">
	<cfset var results = {} />
	<cfset var betsAffected = "" />
	<cfset var getUndecided = "" />
	<cfset var betsUpdated = 0 />

	<cftry>
		<cfquery name="getUndecided">
			SELECT betDetail.*, games.home, games.away, games.homeFinal, games.awayFinal
			FROM betDetail
	
			JOIN bets
			ON betDetail.betID = bets.betID
			JOIN tourneys
			ON bets.tourneyID = tourneys.tourneyID
			JOIN games
			ON betDetail.gameID = games.gameID
			
			WHERE tourneys.league = '#arguments.league#'
			AND tourneys.season = #arguments.season#
			AND betDetail.result = 'undecided'
			AND ( games.status = "Final" OR games.status = "final overtime" )
		</cfquery>
	
		<cfif getUndecided.recordcount><!---if there are "undecided" segments that now have final scores--->
			<cfloop query="getUndecided">
				<cfset local.results[ getUndecided.segmentID ] = didIwin( getUndecided.homeFinal, getUndecided.awayFinal, getUndecided.optionID, getUndecided.mark ) />
	 			<cfif NOT listFind( local.betsAffected, getUndecided.betID )>
					<cfset local.betsAffected = listAppend( local.betsAffected, getUndecided.betID )>
				</cfif>
			</cfloop>
			
			<cfoutput>
		 	<cfquery name="big_update">
				UPDATE betDetail
				SET result = CASE segmentID
				<cfloop collection="#local.results#" item="itm">
					WHEN #itm# THEN '#structFind( local.results, itm )#'
				</cfloop>
		 		END
				WHERE segmentID IN ( #structKeyList( local.results )# )
			</cfquery>
			</cfoutput>
			<cfset local.betsUpdated = updateBetResults( local.betsAffected ) /><!---after the segment update, run the update on 'bets' table--->
		</cfif>
		
		<cfset logThis( "#now()# - #getUndecided.recordcount# bet segments updated. #local.betsUpdated# whole bets updated", "betUpdate" )>
		<cfreturn true>		
		<cfcatch>
			<cfdump var="#cfcatch#">
 			<cfset logThis( cfcatch.message, "betUpdate" )>
			<cfreturn false>		
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="figurePropWinners" hint="updates all the betDetails for props" output="true">
	<cfargument name="league">
	<cfargument name="season">
	<cfset var getPropResults = "">
	<cfset var updateBetSegments = "">
	
	<cftry>
		<cfquery name="getPropResults">
			SELECT betDetail.propOptID, propOpts.propResult, group_concat( bets.betID ) AS betsAffected
			FROM betDetail
			JOIN propOpts
			ON betDetail.propOptID = propOpts.propOptID
			JOIN bets
			ON betDetail.betID = bets.betID
			WHERE betDetail.result = "undecided"
			AND propOpts.propResult <> "undecided"
			AND betDetail.propOptID is not null
			GROUP BY propOptID
		</cfquery>
	
		<cfif getPropResults.recordcount>
			<cfquery name="updateBetSegments">
				UPDATE betDetail
				SET result = CASE propOptID
				<cfloop query="getPropResults">
					WHEN #getPropResults.propOptID# THEN '#getPropResults.propResult#'
				</cfloop>
				END
				WHERE propOptID IN ( #valueList( getPropResults.propOptID )# )
			</cfquery>
			<cfset local.betsUpdated = updateBetResults( valueList( getPropResults.betsAffected ) ) /><!---after the segment update, run the update on 'bets' table--->
			<cfset logThis( "#now()# - #getPropResults.recordcount# props updated. #local.betsUpdated# whole bets updated", "betUpdate" )>
		</cfif>
		
		<cfreturn true>		
		<cfcatch>
			<cfdump var="#cfcatch#">
 			<cfset logThis( cfcatch.message, "betUpdate" )>
			<cfreturn false>		
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="updateTheLines" hint="setting the spread, moneyline, and over/under">
	<cfargument name="rc">
	<cfset var updater = "">
	<cfquery name="updater">
		UPDATE games
        SET homeSpread = CASE gameID        
        <cfloop list="#rc.fieldnames#" index="itm">
			<cfif listLen( itm, "|" ) EQ 2 AND listGetAt( itm, 2, "|" ) EQ "homeSpread" AND rc[ itm ] NEQ "">
	    		WHEN #listGetAt( itm, 1, "|" )# THEN #rc[ itm ]#
			</cfif>
        </cfloop>
		WHEN "" THEN "" END,

        homeWin = CASE gameID       
        <cfloop list="#rc.fieldnames#" index="itm">
			<cfif listLen( itm, "|" ) EQ 2 AND listGetAt( itm, 2, "|" ) EQ "homeWin" AND rc[ itm ] NEQ "">
	    		WHEN #listGetAt( itm, 1, "|" )# THEN #rc.convertOdds( rc[ itm ], "US2dec" )#
			</cfif>
        </cfloop>
		WHEN "" THEN "" END,

        awayWin = CASE gameID
        <cfloop list="#rc.fieldnames#" index="itm">
			<cfif listLen( itm, "|" ) EQ 2 AND listGetAt( itm, 2, "|" ) EQ "awayWin" AND rc[ itm ] NEQ "">
	    		WHEN #listGetAt( itm, 1, "|" )# THEN #rc.convertOdds( rc[ itm ], "US2dec" )#
			</cfif>
        </cfloop>
		WHEN "" THEN "" END,

		overUnder = CASE gameID
        <cfloop list="#rc.fieldnames#" index="itm">
			<cfif listLen( itm, "|" ) EQ 2 AND listGetAt( itm, 2, "|" ) EQ "overUnder" AND rc[ itm ] NEQ "">
	    		WHEN #listGetAt( itm, 1, "|" )# THEN #rc[ itm ]#
			</cfif>
        </cfloop>
		WHEN "" THEN "" END,

		featured = CASE gameID
        <cfloop list="#rc.fieldnames#" index="itm">
			<cfif listLen( itm, "|" ) EQ 2 AND listGetAt( itm, 2, "|" ) EQ "featured" AND rc[ itm ] NEQ "">
	    		WHEN #listGetAt( itm, 1, "|" )# THEN 1
			</cfif>
        </cfloop>
		WHEN "" THEN ""
		ELSE 0 END

		<!---make where clause--->
		<cfset rc.gameList = "">
        <cfloop list="#rc.fieldnames#" index="itm">
			<cfif listLen( itm, "|" ) EQ 2>
				<cfset rc.gameList = listAppend( rc.gameList, listGetAt( itm, 1, "|" ) )>
			</cfif>
		</cfloop>
		WHERE gameID IN ( #rc.gameList# )
	</cfquery>
	<cfreturn true>
</cffunction>

<cffunction name="fetchNFLjson" hint="JSON is improper; need to replace blank fields with ''">
<!--- 	<cfhttp url="http://www.nfl.com/liveupdate/scorestrip/scorestrip.json" /> --->
	<cfhttp url="http://3.hidemyass.com/ip-9/encoded/Oi8vd3d3Lm5mbC5jb20vbGl2ZXVwZGF0ZS9zY29yZXN0cmlwL3Njb3Jlc3RyaXAuanNvbg%3D%3D&f=norefer" />
 	<cfset local.dataJSON = REreplace( cfhttp.FileContent, ',,', ',"",', "all" ) />
	<cfset local.dataJSON = REreplace( local.dataJSON, ',,', ',"",', "all" ) />
	<cfreturn deserializeJSON( local.dataJSON ).ss />
</cffunction>

<cffunction name="fetchNFLplayoffJSON" hint="The NFL feed for the playoffs is dofferent than the regular season">
<!--- 	<cfhttp url="http://www.nfl.com/liveupdate/scorestrip/postseason/scorestrip.json" /> --->
<!--- 	<cfhttp url="http://6.hidemyass.com/ip-1/encoded/Oi8vd3d3Lm5mbC5jb20vbGl2ZXVwZGF0ZS9zY29yZXN0cmlwL3Bvc3RzZWFzb24vc2NvcmVzdHJpcC5qc29u&f=norefer" /> --->
	<cfhttp url="http://174.136.50.254/~ipxnowin/r.php?nin_u=Oi8vd3d3Lm5mbC5jb20vbGl2ZXVwZGF0ZS9zY29yZXN0cmlwL3Bvc3RzZWFzb24vc2NvcmVzdHJpcC5qc29u&nin_b=1&nin_f=norefer" />
	<cfset local.dataJSON = REreplace( cfhttp.FileContent, ',,', ',"",', "all" ) />
	<cfset local.dataJSON = REreplace( local.dataJSON, ',,', ',"",', "all" ) />
	<cfreturn deserializeJSON( local.dataJSON ).ss />
</cffunction>

<cffunction name="convertDayTimeToUTC" hint="takes a day time like THU 9:30 EST and turns into UTC.">
	<cfargument name="gameday" hint="as a three character string">
	<cfargument name="gametime" hint="in short format. Assumes PM.">

	<!---server time is UTC, but nflfeed time is EST. We'll do our conversions in EST, then convert back to UTC at the end.--->	
	<cfset local.nowEST = convertTime() />
	<cfset local.todayAsNum = dayOfWeek( nowEST ) />

	<!---new feeds are published on tuesday. need to figure amount of time between now and gameday--->
	<cfif local.todayAsNum LTE 2>
		<cfset local.todayAsNum = local.todayAsNum + 7>
	</cfif>
	<cfswitch expression = "#arguments.gameday#">
		<cfcase value="THU"><cfset local.daysfromNow = 5 - local.todayAsNum></cfcase>
		<cfcase value="FRI"><cfset local.daysfromNow = 6 - local.todayAsNum></cfcase>
		<cfcase value="SAT"><cfset local.daysfromNow = 7 - local.todayAsNum></cfcase>
		<cfcase value="SUN"><cfset local.daysfromNow = 8 - local.todayAsNum></cfcase>
		<cfcase value="MON"><cfset local.daysfromNow = 9 - local.todayAsNum></cfcase>
	</cfswitch>
	
	<!---figure all the variables we need to create a date/time obj--->
	<cfset local.dayOfGame = day( dateAdd( "d", local.daysfromNow, local.nowEST ) ) />
	<cfset local.monthOfGame = month( dateAdd( "d", local.daysfromNow, local.nowEST ) ) />
	<cfset local.yearOfGame = year( dateAdd( "d", local.daysfromNow, local.nowEST ) ) />
	<cfset local.hourOfGame = hour( arguments.gametime & "pm" ) /><!---will return hour in military time--->
	<cfset local.minuteOfGame = minute( arguments.gametime ) />

	<cfset local.dateObj = createDateTime( local.yearOfGame, local.monthOfGame, local.dayOfGame, local.hourOfGame, local.minuteOfGame, 0 ) />
 	<cfset local.UTCdatetime = convertTime( local.dateObj, "America/New_York", "NamedTZtoUTC" ) />
	<cfreturn local.UTCdatetime />
</cffunction>

<cffunction name="getNFLgames" access="remote" return="plain" hint="gets games from nfl.com json feed.">
	<cfset var getIDs = "">
	<cfset var insertGames = "">
	<cfset var i = "">
	<cfset var idx = "">
	<cfset var newRecs = 0>
	<cfset var counter = 0>
	<cftry>
		<cfset local.dataArray = fetchNFLjson() />
		<cfset local.findResults = REfind( "[0-9]+", local.dataArray[1][13], 1, "true" )>
		<cfset local.currentweek = mid( local.dataArray[1][13], local.findResults.pos[1], local.findResults.len[1] )>			
	
		<!---get a list of nflIDs we already have. This will prevent dup rows--->
		<cfquery name="getIDs">
			SELECT nflID
			FROM games
			WHERE nflID is not null
			AND season = <cfqueryparam value="#local.dataArray[1][14]#" cfsqltype="cf_sql_integer">
			AND round = <cfqueryparam value="#local.currentweek#" cfsqltype="cf_sql_integer">
		</cfquery>
		<cfset local.nflIDlist = valuelist( getIDs.nflID )>
	
		<!---loop through to see if we have any new records--->
		<cfloop from=1 to="#arrayLen( local.dataArray )#" index="idx"> 
			<cfif listFind( local.nflIDlist, local.dataArray[idx][11] ) is FALSE>
				<cfset local.newRecs = 1>
				<cfbreak>
			</cfif>
		</cfloop>
	
		<!---run the insert if we have new records--->
		<cfif newRecs>
	 		<cfquery name="insertGames">
				INSERT INTO games ( league, season, round, gametime, home, away, nflID ) 
				VALUES 
				<cfloop from=1 to="#arrayLen( local.dataArray )#" index="i"> 
					<cfif listFind( local.nflIDlist, local.dataArray[i][11] ) is FALSE>
						<cfset local.gametime = convertDayTimeToUTC( local.dataArray[i][1], local.dataArray[i][2] )>
						<cfoutput>
							( 'NFL', 
							 <cfqueryparam value="#local.dataArray[i][14]#" cfsqltype="cf_sql_integer">,
							 <cfqueryparam value="#local.currentweek#" cfsqltype="cf_sql_integer">, 
							 <cfqueryparam value="#local.gametime#" cfsqltype="cf_sql_timestamp">,
							 <cfqueryparam value="#local.dataArray[i][7]#">,		
							 <cfqueryparam value="#local.dataArray[i][5]#">, 
							 <cfqueryparam value="#local.dataArray[i][11]#"> )
							 <cfif i NEQ arrayLen( local.dataArray )>,</cfif>
						</cfoutput>
						<cfset local.counter = local.counter + 1>
					</cfif>
				</cfloop>
			</cfquery>
		</cfif>	

		<!---log it and out--->
		<cfdump var="#dataArray#">		
		<cfset logThis( "#local.counter# games added at #now()# by getNFLgames().", "jobs" )>
		<cfreturn true>
		<cfcatch>
 			<cfset logThis( cfcatch.message, "jobs" )>
			<cfreturn false>
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="getNFLupdates" access="remote" return="plain">
	<cfset var i="">
	<cfset var getGames="">
	<cfset var counter = 0>
	<cfset var hasNewResult = 0>
	<cftry>
		<cfset local.dataArray = fetchNFLjson() />
		<cfset local.findResults = REfind( "[0-9]+", local.dataArray[1][13], 1, "true" )>
		<cfset local.currentweek = mid( local.dataArray[1][13], local.findResults.pos[1], local.findResults.len[1] )>	
	
		<!---get a list of games that we need to update; once "final", we stop updating it--->
		<cfquery name="getGames">
			SELECT nflID
			FROM games
			WHERE nflID is not null
			AND season = <cfqueryparam value="#local.dataArray[1][14]#" cfsqltype="cf_sql_integer">
			AND round = <cfqueryparam value="#local.currentweek#" cfsqltype="cf_sql_integer">
 			AND status <> "Final" AND status <> "final overtime"
		</cfquery>
		<cfset local.nflIDlist = valuelist( getGames.nflID )>
		
		<!---loop through the list and update games that are in list and not pregame--->
		<cfloop from=1 to="#arrayLen( local.dataArray )#" index="i">
			<cfif listFind( local.nflIDlist, local.dataArray[i][11] ) AND local.dataArray[i][3] NEQ "Pregame"> 
				<cfoutput>
					<cfquery name="update-#i#">
						UPDATE games
						SET homeFinal = <cfqueryparam value="#local.dataArray[i][8]#" cfsqltype="cf_sql_integer">,
							awayFinal = <cfqueryparam value="#local.dataArray[i][6]#" cfsqltype="cf_sql_integer">,
							status = <cfqueryparam value="#local.dataArray[i][3]#">,
							timeRemaining = <cfqueryparam value="#local.dataArray[i][4]#">
						WHERE nflID = <cfqueryparam value="#local.dataArray[i][11]#" cfsqltype="cf_sql_integer">
					</cfquery>
				</cfoutput>
				<cfif local.dataArray[i][3] EQ "Final" OR local.dataArray[i][3] EQ "final overtime">
					<cfset local.hasNewResult = 1>
				</cfif>
				<cfset local.counter = local.counter + 1>	
			</cfif>
		</cfloop>
		
		<!---if there is a new "final" score in, then we'll run the betUpdater scripts--->
		<cfif hasNewResult>
			New result, gonna run figureWinnersLosers() & figureSuicideResults()
  			<cfset figureWinnersLosers( "NFL", local.dataArray[1][14] ) />
  			<cfset figureSuicideResults( local.dataArray[1][14] ) />
		</cfif>

		<!---log it and out--->
		<cfdump var="#dataArray#">		
		<cfset logThis( "#local.counter# games updated at #now()# by getNFLupdates().", "jobs" )>
		<cfreturn true>
		<cfcatch>
 			<cfset logThis( cfcatch.message, "jobs" )>
			<cfdump var="#cfcatch#">
			<cfreturn false>		
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="getNFLplayoffUpdates" access="remote" return="plain">
	<cfset var i="">
	<cfset var getGames="">
	<cfset var counter = 0>
	<cfset var hasNewResult = 0>

	<cftry>
		<cfset local.dataArray = fetchNFLplayoffjson() />
		<cfset local.findResults = REfind( "[0-9]+", local.dataArray[1][13], 1, "true" )>
		<cfset local.currentweek = mid( local.dataArray[1][13], local.findResults.pos[1], local.findResults.len[1] )>	

		<!---get a list of games that we need to update; once "final", we stop updating it--->
		<cfquery name="getGames">
			SELECT nflID
			FROM games
			WHERE nflID is not null
			AND league = "NFLp"
			AND season = <cfqueryparam value="#local.dataArray[1][17]#" cfsqltype="cf_sql_integer">
 			AND status <> "Final" AND status <> "final overtime"
		</cfquery>
		<cfset local.nflIDlist = valuelist( getGames.nflID )>
		
		<!---loop through the list and update games that are in list and not pregame--->
		<cfloop from=1 to="#arrayLen( local.dataArray )#" index="i">
			<cfif listFind( local.nflIDlist, local.dataArray[i][13] ) AND local.dataArray[i][3] NEQ "Pregame"> 
				<cfoutput>
					<cfquery name="update-#i#">
						UPDATE games
						SET homeFinal = <cfqueryparam value="#local.dataArray[i][10]#" cfsqltype="cf_sql_integer">,
							awayFinal = <cfqueryparam value="#local.dataArray[i][7]#" cfsqltype="cf_sql_integer">,
							status = <cfqueryparam value="#local.dataArray[i][3]#">,
							timeRemaining = <cfqueryparam value="#local.dataArray[i][4]#">
						WHERE nflID = <cfqueryparam value="#local.dataArray[i][13]#" cfsqltype="cf_sql_integer">
					</cfquery>
				</cfoutput>
				<cfif local.dataArray[i][3] EQ "Final" OR local.dataArray[i][3] EQ "final overtime">
					<cfset local.hasNewResult = 1>
				</cfif>
				<cfset local.counter = local.counter + 1>	
			</cfif>
		</cfloop>
		
		<!---if there is a new "final" score in, then we'll run the betUpdater scripts--->
		<cfif hasNewResult>
			New result, gonna run figureWinnersLosers()
  			<cfset figureWinnersLosers( "NFLp", local.dataArray[1][17] ) />
		</cfif>

		<!---log it and out--->
		<cfdump var="#dataArray#">		
		<cfset logThis( "#local.counter# games updated at #now()# by getNFLupdates().", "jobs" )>
		<cfreturn true>

		<cfcatch>
 			<cfset logThis( cfcatch.message, "jobs" )>
			<cfdump var="#cfcatch#">
			<cfreturn false>		
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="updateNFLidsAndTime" access="remote" return="plain" hint="the nflID is needed for automatic updates to work">
	<cfargument name="season">
	<cfset var i = "" />
	<cfset local.dataArray = fetchNFLjson() />
	<cfquery name="updateIDsAndTime" result="myResult">
		<cfloop from="1" to="#arrayLen( local.dataArray )#" index="i">
			<cfoutput>
				UPDATE games 
				SET nflID = #local.dataArray[i][11]#, gametime = #convertDayTimeToUTC( local.dataArray[i][1], local.dataArray[i][2] )#
				WHERE league = 'NFL' AND season = #arguments.season#
				AND home = '#local.dataArray[i][7]#'
				AND away = '#local.dataArray[i][5]#';
			</cfoutput>
		</cfloop>
 	</cfquery>
	<cfoutput>Ran: #myResult.sql#</cfoutput>
	<cfset logThis( "Ran weekly update for IDs and gametime at #now()#. #myResult.recordCount# records updated.", "jobs" )>
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

</cfcomponent>