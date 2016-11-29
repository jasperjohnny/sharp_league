<cfcomponent extends="common">

<cffunction name="init" hint="allows us to call a service and set results to rc">
	<cfargument name="fw">
	<cfset variables.fw = arguments.fw />
	<cfset variables.tourneyService = new services.tourney() />
	<cfset variables.suicideService = new services.suicide() />
</cffunction>

<cffunction name="before" hint="Users can only see tourneys they are entered in; admins can see anything">
	<cfargument name="rc">
 	<cfif isDefined( "rc.t" ) AND ( ( isDefined( "session.user.enteredIn" ) AND listFind( session.user.enteredIn, rc.t ) ) OR ( isDefined( "session.user.role" ) AND session.user.role EQ "admin" ) )>
		<cfset rc.tourneyBasics = variables.tourneyService.getTourneyBasics( rc.t )>
	<cfelse>
		<cfset variables.fw.redirect( "front" )>
	</cfif>
</cffunction>

<cffunction name="lobby" hint="tourney homepage">
	<cfargument name="rc">
	<cfinvoke component="services.ajax" method="renderMessages" t="#rc.t#" returnVariable="rc.msgStruct" />
	<cfset rc.tourneyStandings = variables.tourneyService.getStandings( rc.t ) />
	<cfset rc.featured = variables.tourneyService.getFeatured( rc.tourneyBasics.league, rc.tourneyBasics.season ) />
	<cfset rc.suicide = variables.suicideService.getSuicideInfo( session.user.userID, rc.t, rc.tourneyBasics.suicideType, rc.tourneyBasics.currentRound, rc.tourneyBasics.suicideStarts ) />
	<cfset rc.notables = variables.tourneyService.getNotables( rc.t, rc.tourneyBasics.currentRound )>
	<cfif NOT rc.notables.recordcount AND rc.tourneyBasics.currentRound NEQ 1><!---don't want to end up fetching preseason--->
		<cfset rc.notables = variables.tourneyService.getNotables( rc.t, val( rc.tourneyBasics.currentRound ) - 1 ) />
	</cfif>	
	<cfset rc.convertTime = variables.tourneyService.convertTime />	
</cffunction>

<cffunction name="ledger" hint="shows bet history; only fetch bets after confirming that user is in tourney">
	<cfargument name="rc">
	<cfparam name="rc.show" default="#session.user.userID#">
	<cfset rc.userInfo = variables.tourneyService.getUserBasics( rc.t, rc.show )>
	<cfif rc.userInfo.recordcount>
		<cfset rc.ledger = variables.tourneyService.getLedger( rc.t, rc.show )>
		<cfset rc.tourneyTotals = variables.tourneyService.getStandings( rc.t, rc.show )>
		<cfset rc.getRoundTotals = variables.tourneyService.getRoundTotals>
	</cfif>
</cffunction>

<cffunction name="book" hint="place your bets">
	<cfargument name="rc">
	<cfset rc.convertTime = variables.convertTime />
	<cfset rc.betList = variables.tourneyService.getBetList( rc.tourneyBasics.league, rc.tourneyBasics.season, rc.tourneyBasics.currentRound ) />
	<cfset rc.propList = variables.tourneyService.getPropList( rc.tourneyBasics.league, rc.tourneyBasics.season, rc.tourneyBasics.currentRound ) />
	<cfset rc.convertOdds = variables.tourneyService.convertOdds />
</cffunction>

<cffunction name="review" hint="after selections from book">
	<cfargument name="rc">
	<cfparam name="rc.betType" default="">
	<cfif structKeyExists( rc, "betString" ) AND rc.betType EQ "game">
		<cfset local.checkBet = variables.tourneyService.isBetOK( rc.betString ) />
		<cfif local.checkBet EQ "Passed">
			<cfset rc.betArray = variables.tourneyService.betStringToBetArray( rc.betString ) />
		</cfif>
	<cfelseif structKeyExists( rc, "propString" ) AND rc.betType EQ "prop">
		<cfset local.checkBet = variables.tourneyService.isPropOK( rc.propString ) />
		<cfif local.checkBet EQ "Passed">
			<cfset rc.betArray = variables.tourneyService.propStringtoBetArray( rc.propString ) />
		</cfif>
	<cfelse>
		<cfset variables.fw.redirect( "tourney/book/#rc.t#" )>
	</cfif>	
	<cfif local.checkBet NEQ "Passed">
		<cfset rc.returnMsg = local.checkBet />
		<cfset variables.fw.redirect( "tourney/book/#rc.t#", "returnMsg" ) />
	</cfif>
	<cfset rc.multiplier = variables.tourneyService.figureMultiplier( rc.betArray ) />
	<cfset rc.totals = variables.tourneyService.getStandings( rc.t, session.user.userID ) />	
</cffunction>

<cffunction name="confirm_form" hint="after clearing all checks, this will generate a tempID in betTemp table">
	<cfargument name="rc">
	<cfparam name="rc.amount" default="0">
	<cfset rc.amount = replace( rc.amount, ",", "", "all" ) />
	<cfset rc.amount = replace( rc.amount, "$", "", "all" ) />
	<cfset local.totals = variables.tourneyService.getStandings( rc.t, session.user.userID )>
	<!---games--->
	<cfif structKeyExists( rc, "betString" ) AND rc.betType EQ "game">
		<cfset local.checkBet = variables.tourneyService.isBetOK( rc.betString ) />
		<cfset rc.betType = "game" />
		<cfif local.checkBet NEQ "Passed">
			<cfset rc.returnMsg = local.checkBet />
			<cfset variables.fw.redirect( "tourney/book/#rc.t#", "returnMsg" )>
	 	<cfelseif NOT structKeyExists( rc, "amount" ) OR rc.amount LT 5>
			<cfset rc.returnMsg = "The minimum bet size is $5.">
			<cfset variables.fw.redirect( "tourney/review/#rc.t#", "betString,returnMsg,betType" )>
		<cfelseif rc.amount GT ( roundTo2( val( local.totals.bankroll ) ) - roundTo2( val( local.totals.atRisk ) ) )>		
			<cfset rc.returnMsg = "You do not have the money to cover this bet.">
			<cfset variables.fw.redirect( "tourney/review/#rc.t#", "betString,returnMsg,betType" )>
		<cfelse>
			<!---Only after passing all checks, put in betTemp with expiry.--->
			<cfset rc.tempID = variables.tourneyService.addBetToTemp( rc.betString, rc.amount, rc.t )>
		</cfif>
	<!---props--->
	<cfelseif structKeyExists( rc, "propString" ) AND rc.betType EQ "prop">
		<cfset local.checkBet = variables.tourneyService.isPropOK( rc.propString ) />
		<cfset rc.betType = "prop" />
		<cfif local.checkBet NEQ "Passed">
			<cfset rc.returnMsg = local.checkBet />
			<cfset variables.fw.redirect( "tourney/book/#rc.t#", "returnMsg" )>
	 	<cfelseif NOT structKeyExists( rc, "amount" ) OR rc.amount LT 5>
			<cfset rc.returnMsg = "The minimum bet size is $5.">
			<cfset variables.fw.redirect( "tourney/review/#rc.t#", "propString,returnMsg,betType" )>
		<cfelseif rc.amount GT ( roundTo2( val( local.totals.bankroll ) ) - roundTo2( val( local.totals.atRisk ) ) )>		
			<cfset rc.returnMsg = "You do not have the money to cover this bet.">
			<cfset variables.fw.redirect( "tourney/review/#rc.t#", "propString,returnMsg,betType" )>
		<cfelse>
			<!---Only after passing all checks, put in betTemp with expiry.--->
			<cfset rc.tempID = variables.tourneyService.addBetToTemp( rc.propString, rc.amount, rc.t, "prop" )>
		</cfif>
	<cfelse>
		<cfset variables.fw.redirect( "tourney/book/#rc.t#" )>
	</cfif>	
	<cfif rc.tempID>
		<cfset variables.fw.redirect( "tourney/confirm/#rc.t#", "tempID" )>
	<cfelse>
		<cfset rc.returnMsg = "We cannot process the bet at this time. Please try again later.">
		<cfset variables.fw.redirect( "tourney/review/#rc.t#", "betString,returnMsg" )>		
	</cfif>
</cffunction>

<cffunction name="confirm" hint="the only thing this page will process is a betTempID">
	<cfargument name="rc">
 	<cfif NOT structKeyExists( rc, "tempID" )>
		<cfset variables.fw.redirect( "tourney/book/#rc.t#" )>
	<cfelse>
		<cfset rc.betInfo = variables.tourneyService.getBetFromTemp( rc.t, rc.tempID )>
		<cfif rc.betInfo.recordcount>
			<cfwddx action="wddx2cfml" input="#rc.betInfo.betWddx#" output="rc.betArray">
			<cfset rc.toWin = rc.betInfo.amount * variables.tourneyService.figureMultiplier( rc.betArray )>
			<cfset rc.totals = variables.tourneyService.getStandings( rc.t, session.user.userID )>
			<cfset rc.convertTime = variables.convertTime>
		<cfelse>
			<cfset rc.returnMsg = "That bet has expired or is otherwise invalid.">
			<cfset variables.fw.redirect( "tourney/book/#rc.t#", "returnMsg" )>
		</cfif>
	</cfif>
</cffunction>

<cffunction name="place_form" hint="move from betTemp to Bets and betDetail">
	<cfargument name="rc">
	<cfparam name="rc.hideThis" default="0">
 	<cfif NOT structKeyExists( rc, "tempID" )>
		<cfset variables.fw.redirect( "tourney/book/#rc.t#" )>
	<cfelse>
		<cfset local.tempBet = variables.tourneyService.getBetFromTemp( rc.t, rc.tempID )>
		<cfif local.tempBet.recordcount>
			<cfset rc.placeResult = variables.tourneyService.placeBet( local.tempBet, rc.hideThis, rc.t, rc.tourneyBasics.currentRound )>
			<cfif rc.placeResult>
				<cfset variables.tourneyService.deleteBetTemp( rc.tempID )>
				<cfset rc.returnMsg = "Bet placed successfully. Good luck.">
				<cfset variables.fw.redirect( "tourney/ledger/#rc.t#", "returnMsg" )>
			<cfelse>
				<cfset rc.returnMsg = "There was an unexpected error when placing this bet. Please try again later.">
				<cfset variables.fw.redirect( "tourney/book/#rc.t#", "returnMsg" )>
			</cfif>
		<cfelse>
			<cfset rc.returnMsg = "That bet has expired or is otherwise invalid.">
			<cfset variables.fw.redirect( "tourney/book/#rc.t#", "returnMsg" )>
		</cfif>
	</cfif>
</cffunction>

<cffunction name="comment_form" hint="just inserts now, then a bounce back">
	<cfargument name="rc">
	<cfparam name="rc.comment" default="">
	<cfif trim( rc.comment ) NEQ "">
		<cfset variables.tourneyService.addComment( rc.comment, rc.t )>
	</cfif>
	<cfset variables.fw.redirect( "tourney/lobby/#rc.t#" )>
</cffunction>

<!--- <cffunction name="suicide">
	<cfargument name="rc">
	<cfif rc.tourneyBasics.suicideType EQ "none">
		<cfset variables.fw.redirect( "tourney/lobby/#rc.t#" )>

	<cfelseif rc.tourneyBasics.status EQ "closed">
		<cfset rc.topMessage = "This tournament has concluded, so no more betting. Thanks.">
		<cfset rc.suicide = variables.suicideService.getSuicideInfo( session.user.userID, rc.t, rc.tourneyBasics.suicideType, rc.tourneyBasics.currentRound, rc.tourneyBasics.suicideStarts )>
		
	<cfelseif rc.tourneyBasics.suicideStarts GT rc.tourneyBasics.currentRound>
		<cfset rc.topMessage = "The suicide pool will begin Week #rc.tourneyBasics.suicideStarts#.">

	<cfelse>		
		<cfset rc.suicide = variables.suicideService.getSuicideInfo( session.user.userID, rc.t, rc.tourneyBasics.suicideType, rc.tourneyBasics.currentRound, rc.tourneyBasics.suicideStarts )>
		<cfset rc.sundayStart = this.getSundaykickoff( rc.tourneyBasics.season, rc.tourneyBasics.league, rc.tourneyBasics.currentRound )>

		<cfif rc.suicide.isdead is true>
			<cfset rc.topMessage = "Sorry, you are out of contention for the suicide pool.">			
		<cfelseif trim( rc.suicide.currentTeam ) NEQ "">
			<cfset rc.topMessage = "Your choice for Week #rc.tourneyBasics.currentRound#: <strong>#rc.suicide.currentTeam#</strong>.">
		<cfelseif trim( rc.suicide.currentTeam ) EQ "" AND rc.sundayStart NEQ "" AND DateConvert( 'local2Utc', now() ) GT rc.sundayStart >
			<cfset rc.topMessage = "You did not choose a team this week. The computer will pick randomly for you.">
		<cfelse>
			<cfset rc.betList = variables.tourneyService.getBetList( rc.tourneyBasics.league, rc.tourneyBasics.season, rc.tourneyBasics.currentRound )>
			<cfset rc.convertTime = variables.convertTime>
		</cfif>
	</cfif>
</cffunction> --->

<cffunction name="suicide">
	<cfargument name="rc">
	<cfif rc.tourneyBasics.suicideType EQ "none">
		<cfset variables.fw.redirect( "tourney/lobby/#rc.t#" )>
	<cfelse>
		<cfset rc.suicide = variables.suicideService.getSuicideInfo( session.user.userID, rc.t, rc.tourneyBasics.suicideType, rc.tourneyBasics.currentRound, rc.tourneyBasics.suicideStarts )>
		<cfset rc.sundayStart = this.getSundaykickoff( rc.tourneyBasics.season, rc.tourneyBasics.league, rc.tourneyBasics.currentRound )>

		<cfif rc.tourneyBasics.suicideWinner NEQ "">
			<cfset rc.winners = variables.suicideService.getWinners( rc.tourneyBasics.suicideWinner )>
		<cfelseif rc.suicide.isdead is false AND trim( rc.suicide.currentTeam ) EQ "" AND DateConvert( 'local2Utc', now() ) LT rc.sundayStart>
			<cfset rc.betList = variables.tourneyService.getBetList( rc.tourneyBasics.league, rc.tourneyBasics.season, rc.tourneyBasics.currentRound )>
			<cfset rc.convertTime = variables.convertTime>
		</cfif>
	</cfif>
</cffunction>


<cffunction name="suicide_form">
	<cfargument name="rc">
	<cfparam name="rc.selection" default="">
	<cfif rc.selection NEQ "" AND rc.tourneyBasics.suicideType NEQ "none">
		<cfset local.isPickOK = variables.suicideService.isSuicidePickOK( rc.selection, rc.tourneyBasics.currentRound, rc.tourneyBasics.league, rc.tourneyBasics.season )>
		<cfset local.suicide = variables.suicideService.getSuicideInfo( session.user.userID, rc.t, rc.tourneyBasics.suicideType, rc.tourneyBasics.currentRound, rc.tourneyBasics.suicideStarts )>
		<cfif local.suicide.isdead is FALSE AND local.suicide.currentpick EQ "" AND local.isPickOK is TRUE AND listFindNoCase( local.suicide.teamspicked, rc.selection ) is FALSE >
			<cfset variables.suicideService.addSuicidePick( rc.t, rc.tourneyBasics.currentRound, rc.selection )>
		</cfif>
	</cfif>
	<cfset variables.fw.redirect( "tourney/suicide/#rc.t#" )>
</cffunction>

<cffunction name="super" hint="super bowl prop game">
	<cfargument name="rc">
	<cfparam name="rc.show" default="#session.user.userID#" />
	<cfset rc.userInfo = variables.tourneyService.getUserBasics( rc.t, rc.show )>
	<cfset rc.superStart = variables.tourneyService.getSuperStart( rc.tourneyBasics.season ) />
	<cfset rc.canEdit = ( rc.superStart GT DateConvert( "local2Utc", now() ) ) ? true : false />
	<cfif NOT rc.userInfo.recordcount OR rc.canEdit><!---makes sure the requested show User is in the tourney and the cutoff has passed--->
		<cfset rc.show = session.user.userID />
	</cfif>
	<cfset rc.superPicks = variables.tourneyService.getSuperPicks( rc.show, rc.t ) />
	<cfset rc.superTieBreak = variables.tourneyService.getSuperTieBreak( rc.show, rc.t ) />
	<cfset rc.propCount = variables.tourneyService.getPropCount( rc.tourneyBasics.season ) />
	<cfif rc.canEdit is false>
		<cfset rc.leaderboard = variables.tourneyService.getSuperLeaders( rc.t ) />
	</cfif>
	<cfif NOT rc.superPicks.recordcount AND rc.canEdit>
		<cfset variables.fw.redirect( "tourney/super_entry/#rc.t#" ) />
	</cfif>
	<cfset rc.convertTime = variables.convertTime>
</cffunction>

<cffunction name="super_entry" hint="entry form for picks">
	<cfargument name="rc">
	<cfset rc.convertTime = variables.convertTime>
	<cfset rc.cutoff = variables.tourneyService.getSuperStart( rc.tourneyBasics.season ) />
	<cfif rc.cutoff LT DateConvert( "local2Utc", now() )>
		<cfset rc.returnMsg = "Too late to change/place picks." />
		<cfset variables.fw.redirect( "tourney/super/#rc.t#", "returnMsg" ) />		
	<cfelse>
		<cfset rc.propList = variables.tourneyService.getSuperProps( rc.tourneyBasics.season, rc.t, session.user.userID ) />
		<cfset rc.superTieBreak = variables.tourneyService.getSuperTieBreak( session.user.userID, rc.t ) />
	</cfif>
</cffunction>

<cffunction name="super_form" hint="places the super picks">
	<cfargument name="rc">
	<cfset local.cutoff = variables.tourneyService.getSuperStart( rc.tourneyBasics.season ) />
	<cfif local.cutoff LT DateConvert( "local2Utc", now() )>
		<cfset rc.returnMsg = "Too late to change/place picks." />
		<cfset variables.fw.redirect( "tourney/super/#rc.t#", "returnMsg" ) />		
	<cfelse>
		<cfset local.placePicks = variables.tourneyService.placePicks( rc, session.user.userID ) />
		<cfif local.placePicks is false>
			<cfset rc.returnMsg = "There was an error placeing your picks. Please try again or something." />
			<cfset variables.fw.redirect( "tourney/super/#rc.t#", "returnMsg" ) />	
		<cfelseif rc.tiebreaker NEQ "">
			<cfset local.placeTieBreaker = variables.tourneyService.placeSuperTieBreak( session.user.userID, rc.t, rc.tiebreaker ) />
			<cfif local.placeTieBreaker is false>
				<cfset rc.returnMsg = "There was an error placeing your picks. Please try again or something." />
				<cfset variables.fw.redirect( "tourney/super/#rc.t#", "returnMsg" ) />	
			</cfif>
		</cfif>
	</cfif>
	<cfset variables.fw.redirect( "tourney/super/#rc.t#", "returnMsg" ) />		
</cffunction>

</cfcomponent>