<cfcomponent extends="common">

<cffunction name="getTourneyBasics" hint="all from tourney on tourneyID; adds in current round based on games table">
	<cfargument name="t">
	<cfset var getInfo = "">
	<cfquery name="getInfo">		
		SELECT tourneys.*, if(v_CurrentRound.currentRound is null, 0, v_CurrentRound.currentRound) AS currentRound
		FROM tourneys
		LEFT JOIN v_CurrentRound
		ON tourneys.league = v_CurrentRound.league AND tourneys.season = v_CurrentRound.season
		WHERE tourneyID = <cfqueryparam value="#arguments.t#" cfsqltype="cf_sql_integer">
		GROUP BY league
	</cfquery>
	<cfreturn getInfo>
</cffunction>

<cffunction name="figureCurrentRound" hint="sometimes you need to figure the current round wo/ knowing a tourneyID, like when creating a tourney">
	<cfargument name="league">
	<cfargument name="season">
	<cfset var getRound = "">
	<cfquery name="getRound">
		SELECT currentRound
		FROM v_CurrentRound
		WHERE league = <cfqueryparam value="#arguments.league#">
		AND season = <cfqueryparam value="#arguments.season#" cfsqltype="cf_sql_integer">
	</cfquery>
	<cfreturn getRound.currentRound>
</cffunction>

<cffunction name="getUserBasics" hint="users in a tourney">
	<cfargument name="t">	
	<cfargument name="userID" required="false" default="0">
	<cfset var userInfo = "">
	<cfquery name="userInfo">
		SELECT *
		FROM enteredIn
		JOIN users
		ON enteredIn.userID = users.userID		
		WHERE enteredIn.tourneyID = <cfqueryparam value="#arguments.t#" cfsqltype="cf_sql_integer">
		<cfif arguments.userID>
			AND enteredIn.userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
		</cfif>
		ORDER BY lastname, firstname
	</cfquery>
	<cfreturn userInfo>
</cffunction>

<cffunction name="getStandings" hint="users in a tourney plus bankroll/atRisk">
	<cfargument name="t">
	<cfargument name="userID" required="false" default="0">
	<cfset var getStandings = "">
	<cfquery name="getStandings">
		SELECT *
		FROM enteredIn
		JOIN users 
		ON enteredIn.userID = users.userID 
		LEFT JOIN v_TourneyTotals
		ON enteredIn.userID = v_TourneyTotals.userID AND enteredIn.tourneyID = v_TourneyTotals.tourneyID
		WHERE enteredIn.tourneyID = <cfqueryparam value="#arguments.t#" cfsqltype="cf_sql_integer">
		<cfif arguments.userID>
			AND enteredIn.userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
		</cfif>
		ORDER BY bankroll DESC, atRisk DESC
	</cfquery>
	<cfreturn getStandings>
</cffunction>

<cffunction name="getFeatured" hint="returns the upcoming featured game">
	<cfargument name="league">
	<cfargument name="season">
	<cfset var getFeat = "">
	<cfquery name="getFeat">
		SELECT games.*, team1.mascot as homeTeam, team1.img as homeImg, team2.mascot as awayTeam, team2.img as awayImg
		FROM games
		JOIN teams as team1 ON games.home = team1.teamCode
	    JOIN teams as team2 ON games.away = team2.teamCode
		WHERE games.league = <cfqueryparam value="#arguments.league#">
		AND games.season = <cfqueryparam value="#arguments.season#" cfsqltype="cf_sql_integer">
		AND games.gametime > #dateConvert( "local2utc", now() )#
		AND featured = 1
		ORDER BY gametime
		LIMIT 1
	</cfquery>
	<cfreturn getFeat>
</cffunction>

<cffunction name="getLedger" hint="all bets and results for a user in a tourney">
	<cfargument name="t">	
	<cfargument name="userID">
	<cfset var betList = "">
	<cfquery name="betList">
		SELECT bets.userID, bets.tourneyID, bets.risked, bets.toWin, bets.whenPlaced, bets.betStarts AS entireStart, betDetail.betStarts AS segmentStart, bets.round, bets.result, bets.finalAmount, displayText, bets.hide, betDetail.result AS segResult
		FROM bets
		JOIN betDetail 
		ON bets.betID = betDetail.betID
		WHERE bets.userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
		AND bets.tourneyID = <cfqueryparam value="#arguments.t#" cfsqltype="cf_sql_integer">
		
		UNION ALL 
		SELECT special.userID, special.tourneyID, null, null, special.whenPlaced, null, null, special.round, 'special' as result, special.amount, displayText, '', ''
		FROM special
		WHERE special.userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer"> 
		AND special.tourneyID = <cfqueryparam value="#arguments.t#" cfsqltype="cf_sql_integer">
		
		ORDER BY round, whenPlaced, segmentStart
	</cfquery>
	<cfreturn betList>
</cffunction>

<cffunction name="getRoundTotals" hint="a helper QoQ; works only after rc.ledger has been formed">
	<cfargument name="round">
	<cfset var getTotals = "">
	<cfquery name="getBets" dbtype="query">
		SELECT whenPlaced, finalAmount
		FROM rc.ledger
		WHERE round = <cfqueryparam value="#arguments.round#" cfsqltype="cf_sql_integer">
		GROUP BY whenPlaced, finalAmount
	</cfquery>
	<cfquery name="getTotals" dbtype="query">
		SELECT sum(finalAmount) AS roundTotal
		FROM getBets
	</cfquery>
	<cfreturn getTotals.roundTotal>
</cffunction>

<cffunction name="getBetList" hint="available bets for listing on sportsbook">
	<cfargument name="league">
	<cfargument name="season">
	<cfargument name="currentRound">	
	<cfset var getGames = "">
	<cfquery name="getGames">
		SELECT games.*, team1.area as homeArea, team1.mascot as homeTeam, team1.stadium, team2.area as awayArea, team2.mascot as awayTeam
		FROM games
		JOIN teams as team1 ON games.home = team1.teamCode
	    JOIN teams as team2 ON games.away = team2.teamCode
		WHERE games.league = <cfqueryparam value="#arguments.league#">
		AND games.season = <cfqueryparam value="#arguments.season#" cfsqltype="cf_sql_integer">
		AND games.gametime > #dateConvert( "local2utc", now() )#
		AND round = <cfqueryparam value="#arguments.currentRound#">
		ORDER BY gametime
	</cfquery>
	<cfreturn getGames>
</cffunction>

<cffunction name="getPropList" hint="available props for listing on sportsbook">
	<cfargument name="league">
	<cfargument name="season">
	<cfargument name="currentRound">	
	<cfset var getProps = "">
	<cfquery name="getProps">
		SELECT *
		FROM props
		JOIN propOpts ON props.propID = propOpts.propID
		WHERE league = <cfqueryparam value="#arguments.league#">
		AND season = <cfqueryparam value="#arguments.season#" cfsqltype="cf_sql_integer">
		AND cutoff > #dateConvert( "local2utc", now() )#
		ORDER BY props.propID, propOpts.line
	</cfquery>
	<cfreturn getProps>
</cffunction>

<cffunction name="convertOdds" hint="dec2US or US2dec">
	<cfargument name="line">
	<cfargument name="conversion" required="false" default="dec2US">
	<cfif arguments.line EQ "" OR arguments.line EQ 0>
		<cfreturn 0>
	<cfelseif arguments.conversion EQ "dec2US">
		<cfif arguments.line GTE 1>
			<cfreturn arguments.line * 100>
		<cfelse>
			<cfreturn -100 / arguments.line>
		</cfif>
	<cfelseif arguments.conversion EQ "US2dec">
		<cfif arguments.line GTE 100>
			<cfreturn line / 100>
		<cfelse>
			<cfreturn -100 / arguments.line>
		</cfif>
	</cfif>
</cffunction>

<cffunction name="isBetOK" hint="runs some checks on bet construction">
	<cfargument name="betString">
	<cfif listLen( arguments.betString ) GT 8>
		<cfreturn "House rules limit parlays to eight items.">
	<cfelseif this.isParlayOK( arguments.betString ) is false>
		<cfreturn "Bets cannot be combined in this way.">
 	<cfelseif this.isBetTooLate( arguments.betString ) is true>
		<cfreturn "Too late, game has already started.">
	<cfelse>
		<cfreturn "Passed">
	</cfif>
</cffunction>

<cffunction name="isPropOK" hint="don't check for parlays because we allow whatever right now">
	<cfargument name="propString">
	<cfif listLen( arguments.propString ) GT 8>
		<cfreturn "House rules limit parlays to eight items.">
	<cfelseif this.isPropTooLate( arguments.propString ) is true>
		<cfreturn "Too late, game has already started.">
	<cfelseif this.isPropDuplicated( arguments.propString ) is true>
		<cfreturn "You cannot take multiple sides of a prop bet. (You won't ever win.)">				
	<cfelse>
		<cfreturn "Passed">
	</cfif>
</cffunction>

<cffunction name="isParlayOK" hint="checks for disallowed combinations of bets">
	<cfargument name="segments">
	<cfset var i = "">
	<cfloop list="#arguments.segments#" index="i">
		<cfset theGame = listGetAt( i, 1, "|" )>
		<cfset option = listGetAt( i, 2, "|" )>
		<cfif ( option EQ 1 AND REfind( "(^|,)#theGame#\|[2,3,4]", arguments.segments ) ) 
				OR ( option EQ 2 AND REfind( "(^|,)#theGame#\|[3,4]", arguments.segments ) )
				OR ( option EQ 3 AND REfind( "(^|,)#theGame#\|[4]", arguments.segments ) )
				OR ( option EQ 5 AND REfind( "(^|,)#theGame#\|[6]", arguments.segments ) )>
			<cfreturn false>
		</cfif>
	</cfloop>
	<cfreturn true>
</cffunction>

<cffunction name="isBetTooLate" hint="checks to see that none of the games have started">
	<cfargument name="betString">
	<cfset local.getGames = this.getGamesFromBetString( arguments.betString ) />
	<cfif local.getGames.gametime[1] LT DateConvert( "local2Utc", now() )>
		<cfreturn true>
	<cfelse>
		<cfreturn false>
	</cfif>
</cffunction>

<cffunction name="isPropTooLate" hint="also checks to see that none of the games have started">
	<cfargument name="propString">
	<cfset local.getProps = this.getPropsFromPropString( arguments.propString ) />
	<cfif local.getProps.cutoff[1] LT DateConvert( "local2Utc", now() )>
		<cfreturn true>
	<cfelse>
		<cfreturn false>
	</cfif>	
</cffunction>

<cffunction name="isPropDuplicated" hint="check to see if someone took two values from the same prop">
	<cfargument name="propString">
	<cfset var checkForDup = "">
	<cfquery name="checkForDup">
		SELECT if( count( props.propID ) > 1, true, false ) AS hasDuplicate
		FROM props
		JOIN propOpts
		ON props.propID = propOpts.propID
		WHERE propOptID IN ( <cfqueryparam value="#arguments.propString#" list=true> )
		GROUP BY props.propID
		ORDER BY count( props.propID ) DESC
		LIMIT 1		
	</cfquery>
	<cfreturn checkForDup.hasDuplicate>
</cffunction>

<cffunction name="getGamesFromBetString">
	<cfargument name="betString">
	<cfset var i = "">
	<cfset var getGames = "">

	<!---1. loop through the list to get all the gameIDs--->
	<cfset local.gameIDs = "">
	<cfloop list="#arguments.betString#" index="i">
		<cfset local.theGame = listGetAt( i, 1, "|" )>
		<cfset local.gameIDs = listAppend( gameIDs, theGame )>
	</cfloop>
	
	<!---2. query to get a recordset of all the games; the first item will be the earliest game--->
	<cfquery name="getGames">
		SELECT games.*, team1.area as homeArea, team1.mascot as homeTeam, team1.stadium, team2.area as awayArea, team2.mascot as awayTeam
		FROM games
		JOIN teams as team1 ON games.home = team1.teamCode
	    JOIN teams as team2 ON games.away = team2.teamCode
		WHERE gameID IN ( <cfqueryparam value="#local.gameIDs#" list=true> )
		ORDER BY gametime
	</cfquery>
	<cfreturn getGames>
</cffunction>

<cffunction name="getPropsFromPropString">
	<cfargument name="propString">
	<cfset var getProps = "">
	<cfquery name="getProps">
		SELECT *
		FROM props
		JOIN propOpts
		ON props.propID = propOpts.propID
		WHERE propOptID IN ( <cfqueryparam value="#arguments.propString#" list=true> )
		ORDER BY cutoff		
	</cfquery>
	<cfreturn getProps>
</cffunction>

<cffunction name="betStringToBetArray" hint="takes betString (formatted as gameID|option) and returns an array of structs">
	<cfargument name="betString">
	<cfset var i = "">
	<cfset local.getGames = this.getGamesFromBetString( arguments.betString ) />
	
	<!---Loop through the list, running a QoQ to form a struct for each segment--->
	<cfset local.allSegments = [] />
	<cfloop list="#arguments.betString#" index="i">
		<cfset local.theGame = listGetAt( i, 1, "|" ) />
		<cfset local.option = listGetAt( i, 2, "|" ) />
		<cfquery name="getBet" dbtype="query">
			SELECT *
			FROM getGames
			WHERE gameID = #local.theGame#
		</cfquery>
		<cfswitch expression="#local.option#">
			<cfcase value="1">
				<cfset local.segment = {
					displayText = getBet.awayTeam & " " & numberformat( ( getBet.homeSpread * -1 ), "+.9" ) & " over " & getBet.homeTeam,
					multiplier = .9091,
					mark = getBet.homeSpread * -1,
					segmentID = "#local.theGame#|#local.option#",
					gametime = getBet.gametime
					} />
			</cfcase>
			<cfcase value="2">
				<cfset local.segment = { 
					displayText = getBet.awayTeam & " " & numberformat( convertOdds( getBet.awayWin ), "+9" ) & " over " & getBet.homeTeam,
					multiplier = #getBet.awayWin#,
					mark = '',
					segmentID = "#local.theGame#|#local.option#",
					gametime = getBet.gametime
					} />
			</cfcase>
			<cfcase value="3">
				<cfset local.segment = {
					displayText = getBet.homeTeam & " " & numberformat( getBet.homeSpread, "+.9" ) & " over " & getBet.awayTeam,
					multiplier = .9091,
					mark = getBet.homeSpread,
					segmentID = "#local.theGame#|#local.option#",
					gametime = getBet.gametime
					} />
			</cfcase>
			<cfcase value="4">
				<cfset local.segment = {
					displayText = getBet.homeTeam & " " & numberformat( convertOdds( getBet.homeWin ), "+9" ) & " over " & getBet.awayTeam,
					multiplier = #getBet.homeWin#,
					mark = '',
					segmentID = "#local.theGame#|#local.option#",
					gametime = getBet.gametime
					} />
			</cfcase>
			<cfcase value="5">
				<cfset local.segment = { 
					displayText = getBet.awayTeam & " at " & getBet.homeTeam & ": over " & getBet.overUnder & " points",
					multiplier = .9091,
					mark = getBet.overUnder,
					segmentID = "#local.theGame#|#local.option#",
					gametime = getBet.gametime
					} />
			</cfcase>
			<cfcase value="6">
				<cfset local.segment = { 
					displayText = getBet.awayTeam & " at " & getBet.homeTeam & ": under " & getBet.overUnder & " points",
					multiplier = .9091,
					mark = getBet.overUnder,
					segmentID = "#local.theGame#|#local.option#",
					gametime = getBet.gametime
					} />
			</cfcase>
		</cfswitch>
		<cfset ArrayAppend( local.allSegments, local.segment )>
	</cfloop>
	
	<cfreturn local.allSegments>
</cffunction>

<cffunction name="propStringtoBetArray" hint="takes propString and returns an array of structs">
	<cfargument name="propString">
	<cfset var i = "">
	<cfset local.allSegments = [] />
	<cfset local.getProps = this.getPropsFromPropString( arguments.propString ) />
	<cfloop list="#arguments.propString#" index="i">
		<cfquery name="getProp" dbtype="query">
			SELECT *
			FROM getProps
			WHERE propOptID = #i#
		</cfquery>
		<cfset local.segment = {
			displayText = getProp.theProp & ": " & getProp.theOption,
			multiplier = getProp.line,
			segmentID = getProp.propOptID,
			gametime = getProp.cutoff,
			isProp = true
			} />
		<cfset ArrayAppend( local.allSegments, local.segment ) />
	</cfloop>
	<cfreturn local.allsegments />
</cffunction>

<cffunction name="figureMultiplier" hint="expects the BetArray from getGamesFromString">
	<cfargument name="betArray">
	<cfset var itm = "">
	<cfset var Xer = 1>
	<cfloop array="#betArray#" index="itm">
		<cfset Xer = Xer * ( 1 + itm.multiplier )>
	</cfloop>
	<cfset Xer = Xer - 1>
	<cfreturn Xer>
</cffunction>

<cffunction name="addBetToTemp" hint="stores bet in Temp before confirmation to prevent line/odds from moving">
	<cfargument name="betstring">
	<cfargument name="amount">
	<cfargument name="t">
	<cfargument name="betType" default="game">
	<cfset var insertBet = "">
	<cfset var getnewID = "">
	<cfif arguments.betType EQ "prop">
		<cfset local.betArray = propStringToBetArray( arguments.betString )>
	<cfelse>
		<cfset local.betArray = betStringToBetArray( arguments.betString )>
	</cfif>
	<cfwddx action="cfml2wddx" input="#local.betArray#" output="local.betArrayWddx">
	<cftry>
		<cfquery name="insertBet">
			INSERT INTO betTemp ( userID, tourneyID, betWddx, amount, expiry )
			VALUES ( <cfqueryparam value="#session.user.userID#" cfsqltype="integer">,
					 <cfqueryparam value="#arguments.t#" cfsqltype="integer">,
					 <cfqueryparam value="#local.betArrayWddx#">,
					 <cfqueryparam value="#arguments.amount#" cfsqltype="cf_sql_decimal">,
					 #DateAdd( "n", 5, DateConvert( 'local2Utc', now() ) )# )	
		</cfquery>
		<cfquery name="getnewID">
			SELECT last_insert_id() as theID
		</cfquery>
		<cfreturn getnewID.theID>
		<cfcatch>
			<cfset logDbError( cfcatch, "tourney.addBetToTemp" )>						
			<cfreturn 0>
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="getBetFromTemp" hint="we add checks for expiry, as well as tourney & userID check so you can't hijack">
	<cfargument name="t">
	<cfargument name="tempID">
	<cfset var getBet = "">
	<cfquery name="getBet">
		SELECT *
		FROM betTemp
		WHERE tourneyID = <cfqueryparam value="#arguments.t#" cfsqltype="integer">
		AND ID = <cfqueryparam value="#arguments.tempID#" cfsqltype="integer">
		AND userID = <cfqueryparam value="#session.user.userID#" cfsqltype="integer">
		AND expiry > #DateConvert( 'local2Utc', now() )#
		LIMIT 1
	</cfquery>
	<cfreturn getBet>
</cffunction>

<cffunction name="placeBet" hint="finally">
	<cfargument name="tempBet" hint="1 row recordest from the betTemp table">
	<cfargument name="hideThis">
	<cfargument name="t">
	<cfargument name="currentRound">
	<cfset var insertBet = "">
	<cfset var getnewID = "">
	<cfset var insertDetails = "">
	<cfset var i = "">
	
	<cfwddx action="wddx2cfml" input="#arguments.tempBet.betWddx#" output="local.betArray">
	<cfset local.toWin = arguments.tempBet.amount * figureMultiplier( local.betArray )>

	<cftry>
		<!---1. Add to bets--->
	  	<cfquery name="insertBet">
			INSERT INTO bets ( userID, tourneyID, risked, toWin, whenPlaced, betStarts, round, hide )
			VALUES ( <cfqueryparam value="#session.user.userID#" cfsqltype="cf_sql_integer">,
					 <cfqueryparam value="#arguments.t#" cfsqltype="cf_sql_integer">,
					 <cfqueryparam value="#arguments.tempBet.amount#" cfsqltype="cf_sql_decimal">,
					 <cfqueryparam value="#local.toWin#" cfsqltype="cf_sql_decimal">,
					 #DateConvert( 'local2Utc', now() )#,
					 <cfqueryparam value="#local.betArray[1].gametime#" cfsqltype="cf_sql_timestamp">,					 	
					 <cfqueryparam value="#arguments.currentRound#" cfsqltype="cf_sql_integer">,					 	
					 <cfqueryparam value="#arguments.hideThis#" cfsqltype="cf_sql_integer"> )
		</cfquery>
		<cfquery name="getnewID">
			SELECT last_insert_id() as theID
		</cfquery>
		
		<!---2. Add to bet_detail (getnewID.theID)--->
 		<cfquery name="insertDetails">
			<cfif structKeyExists( local.betArray[1], "isProp" )>
				INSERT INTO betDetail ( betID, propOptID, line, displayText, betStarts)
				VALUES
					<cfloop from="1" to="#arrayLen( local.betArray )#" index="i">    
					( <cfqueryparam value="#getnewID.theID#" cfsqltype="cf_sql_integer">,
					  <cfqueryparam value="#local.betArray[i].segmentID#" cfsqltype="cf_sql_integer">,				
					  <cfqueryparam value="#local.betArray[i].multiplier#" cfsqltype="cf_sql_decimal">,
					  <cfqueryparam value="#local.betArray[i].displayText#">,
					  <cfqueryparam value="#local.betArray[i].gametime#" cfsqltype="cf_sql_timestamp"> )
							<cfif arrayLen( local.betArray ) NEQ i>,</cfif>
					</cfloop>
			<cfelse>
				INSERT INTO betDetail ( betID, gameID, optionID, line, mark, displayText, betStarts)
				VALUES
					<cfloop from="1" to="#arrayLen( local.betArray )#" index="i">    
					( <cfqueryparam value="#getnewID.theID#" cfsqltype="cf_sql_integer">,
					  <cfqueryparam value="#listGetAt( local.betArray[i].segmentID, 1, "|" )#" cfsqltype="cf_sql_integer">,
					  <cfqueryparam value="#listGetAt( local.betArray[i].segmentID, 2, "|" )#" cfsqltype="cf_sql_integer">,				
					  <cfqueryparam value="#local.betArray[i].multiplier#" cfsqltype="cf_sql_decimal">,
					  <cfqueryparam value="#local.betArray[i].mark#" cfsqltype="cf_sql_decimal">,
					  <cfqueryparam value="#local.betArray[i].displayText#">,
					  <cfqueryparam value="#local.betArray[i].gametime#" cfsqltype="cf_sql_timestamp"> )
							<cfif arrayLen( local.betArray ) NEQ i>,</cfif>
					</cfloop>
			</cfif>
		</cfquery>
		<cfreturn true>
		<cfcatch>
			<cfset logDbError( cfcatch, "tourney.placeBet" )>						
			<cfreturn false>
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="deleteBetTemp" hint="only if place is successful">
	<cfargument name="tempID">
	<cftry>
		<cfquery name="deleteTemp">
			DELETE FROM betTemp
			WHERE ID = <cfqueryparam value="#arguments.tempID#" cfsqltype="cf_sql_integer">
		</cfquery>
		<cfreturn true>
		<cfcatch>
			<cfset logDbError( cfcatch, "tourney.deleteBetTemp" )>						
			<cfreturn false>		
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="addComment" hint="from the lobby, usually">
	<cfargument name="comment">
	<cfargument name="t">
	<cfset var addIt = "">
	<cftry>
		<cfquery name="addIt">
			INSERT INTO messages ( tourneyID, userID, content, timestamp )
			VALUES ( <cfqueryparam value="#arguments.t#" cfsqltype="integer">,
					 <cfqueryparam value="#session.user.userID#" cfsqltype="integer">,
					 <cfqueryparam value="#arguments.comment#">,
					 #DateConvert( 'local2Utc', now() )# )
		</cfquery>
		<cfreturn true>
		<cfcatch>
			<cfset logDbError( cfcatch, "tourney.addcomment" )>									
			<cfreturn false>
		</cfcatch>
	</cftry>
</cffunction>

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

<cffunction name="getNotables" hint="for the lobby; we don't inlcude rebuys in this list">
	<cfargument name="t">
	<cfargument name="round">
	<cfset var getTotals = "">
	<cfquery name="getTotals">
		SELECT (v_RoundTotals.weekTotal - ifNUll(sub1.amount, 0)) AS WeekTotal, v_RoundTotals.round, users.userID, users.firstName, users.lastName
		FROM v_RoundTotals
		JOIN users
		ON v_RoundTotals.userID = users.userID
		<!---don't include rebuys in the notables totals--->
		LEFT JOIN ( 
			SELECT *
			FROM special
			WHERE tourneyID = <cfqueryparam value="#arguments.t#" cfsqltype="integer">
			AND round = <cfqueryparam value="#arguments.round#" cfsqltype="integer">
			AND ( displayText = "Re-buy" OR displayText = "League Buy-In" )
			) AS sub1
		ON v_RoundTotals.userID = sub1.userID
		WHERE v_RoundTotals.tourneyID = <cfqueryparam value="#arguments.t#" cfsqltype="integer">
		AND v_RoundTotals.round = <cfqueryparam value="#arguments.round#" cfsqltype="integer">
		AND v_RoundTotals.weekTotal - ifNUll(sub1.amount, 0) <> 0
		ORDER BY WeekTotal DESC		
	</cfquery>
	<cfreturn getTotals>
</cffunction>

<cffunction name="getPropCount">
	<cfset var getCount = "">
	<cfargument name="season">
	<cfquery name="getCount">
		SELECT count(1) AS counter
		FROM props
		WHERE league = 'NFLsb'
		AND season = <cfqueryparam value="#arguments.season#" cfsqltype="integer"> 
	</cfquery>
	<cfreturn getCount.counter>
</cffunction>

<cffunction name="getSuperProps" hint="for the super bowl prop game">
	<cfargument name="season">
	<cfargument name="t">
	<cfargument name="userID">
	<cfset var getProps = "" />
	<cfquery name="getProps">
		SELECT *, if( id is not null, true, false ) AS hasPicked
		FROM props
		JOIN propOpts
		ON props.propID = propOpts.propID
		LEFT JOIN superProps
		ON propOpts.propOptID = superProps.propOptID 
			AND superProps.tourneyID = <cfqueryparam value="#arguments.t#" cfsqltype="cf_sql_integer">
			AND superProps.userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
		WHERE league = 'NFLsb'
		AND season = <cfqueryparam value="#arguments.season#" cfsqltype="integer"> 
	</cfquery>
	<cfreturn name="#getProps#">
</cffunction>

<cffunction name="getSuperStart" hint="gets the game startTime">
	<cfargument name="season">
	<cfset var getStart = "">
	<cfquery name="getStart">
		SELECT min(cutoff) as gametime
		FROM props
		WHERE league = 'NFLsb'
		AND season = <cfqueryparam value="#arguments.season#" cfsqltype="integer"> 
	</cfquery>
	<cfreturn getStart.gametime>
</cffunction>

<cffunction name="placePicks" hint="place super props game picks">
	<cfargument name="rc">
	<cfargument name="userID">
	<cfset var deleteFirst = "">
	<cfset var insertPicks = "">
	<cftry>
		<cfquery name="deleteFirst">
			DELETE
			FROM superProps
			WHERE tourneyID = <cfqueryparam value="#arguments.rc.t#" cfsqltype="cf_sql_integer">
			AND userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
		</cfquery>
		<cfquery name="insertPicks">
			INSERT INTO superProps ( userID, tourneyID, propID, propOptID )
			VALUES
				<cfloop list="#arguments.rc.fieldnames#" index="i">
					<cfif isNumeric( i )>
						( <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">,
						  <cfqueryparam value="#arguments.rc.t#" cfsqltype="cf_sql_integer">,
						  <cfqueryparam value="#i#" cfsqltype="cf_sql_integer">,
						  <cfqueryparam value="#arguments.rc[ i ]#" cfsqltype="cf_sql_integer"> )
						<cfif i NEQ listGetAt( arguments.rc.fieldnames, listLen( arguments.rc.fieldnames ) )>,</cfif>
					</cfif>
				</cfloop>
		</cfquery>
		<cfreturn true>
		<cfcatch>
			<cfset logDbError( cfcatch, "tourney.placePicks" )>						
			<cfreturn false>
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="getSuperPicks" hint="as it sounds">
	<cfargument name="userID">
	<cfargument name="t">
	<cfset var getPicks = "">
	<cfquery name="getPicks">
		SELECT theProp, theOption, result
		FROM superProps
		JOIN props
		ON superProps.propID = props.PropID
		JOIN propOpts
		ON superProps.propOptID = propOpts.propOptID
		WHERE tourneyID = <cfqueryparam value="#arguments.t#" cfsqltype="cf_sql_integer">
		AND userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
		ORDER BY superProps.propID
	</cfquery>
	<cfreturn getPicks>
</cffunction>

<cffunction name="placeSuperTieBreak" hint="final score of winning team">
	<cfargument name="userID">
	<cfargument name="t">
	<cfargument name="pick">
	<cfset var insertPick = "">
	<cftry>
		<cfquery name="insertPick">
			UPDATE enteredIn
			SET propTieBreak = <cfqueryparam value="#arguments.pick#" cfsqltype="cf_sql_integer">
			WHERE userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer"> 
			AND tourneyID = <cfqueryparam value="#arguments.t#" cfsqltype="cf_sql_integer">
		</cfquery>
		<cfreturn true>
		<cfcatch>
			<cfset logDbError( cfcatch, "tourney.placeSuperTieBreak" )>						
			<cfreturn false>
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="getSuperTieBreak" hint="get the pick">
	<cfargument name="userID">
	<cfargument name="t">
	<cfset var getPick = "">
	<cfquery name="getPick">
		SELECT propTieBreak
		FROM enteredIn
		WHERE userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer"> 
		AND tourneyID = <cfqueryparam value="#arguments.t#" cfsqltype="cf_sql_integer">
	</cfquery>
	<cfreturn getPick.propTieBreak>
</cffunction>

<cffunction name="getSuperLeaders" hint="counts up the wins">
	<cfargument name="t">
	<cfset var getScores = "" />
	<cfquery name="getScores">
		SELECT firstName, lastName, enteredIn.userID, sum( if(result='win',1,0 ) ) AS score
		FROM enteredIn
		INNER JOIN users
		ON users.userID = enteredIn.userID
		INNER JOIN superProps
		ON superProps.userID = users.userID AND superProps.tourneyID = <cfqueryparam value="#arguments.t#" cfsqltype="cf_sql_integer">
		WHERE enteredIn.tourneyID = <cfqueryparam value="#arguments.t#" cfsqltype="cf_sql_integer">
		GROUP BY superProps.userID
		ORDER BY score DESC
	</cfquery>
	<cfreturn getScores />
</cffunction>

</cfcomponent>
