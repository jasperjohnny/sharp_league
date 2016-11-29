<cfcomponent extends="common">
	
<cffunction name="init" hint="set variables for framework API and needed services">
	<cfargument name="fw">
	<cfset variables.fw = arguments.fw>
	<cfset variables.tourneyService = new services.tourney()>
	<cfset variables.commishService = new services.commish()>
</cffunction>

<cffunction name="before" hint="Users can only be here if they are commish; admins can see anything">
	<cfargument name="rc">
 	<cfset variables.fw.setLayout( "tourney" )>
  	<cfif ( isDefined( "rc.t" ) AND isDefined( "session.user.isComm" ) AND listFind( session.user.isComm, rc.t ) OR ( isDefined( "session.user.role" ) AND session.user.role EQ "admin" ) )>
		<cfset rc.tourneyBasics = variables.tourneyService.getTourneyBasics( rc.t )>
	<cfelse>
		<cfset variables.fw.redirect( "front" )>
	</cfif>
</cffunction>

<cffunction name="invites" hint="invite players">
	<cfargument name="rc">

</cffunction>

<cffunction name="settings" hint="change name, suicide, other">
	<cfargument name="rc">
	<cfset rc.suicideKickoff = variables.tourneyService.getSundaykickoff( rc.tourneyBasics.season, rc.tourneyBasics.league, rc.tourneyBasics.suicideStarts )>
</cffunction>

<cffunction name="players" hint="buy-ins, re-buys, delete player">
	<cfargument name="rc">
	<cfset rc.players = variables.tourneyService.getStandings( rc.t )>
</cffunction>

<cffunction name="markPaid" hint="add 2000 to 'special' and switch 'eneteredin'; make sure player is indeed in tourney before action">
	<cfargument name="rc">
	<cfset rc.playerData = variables.tourneyService.getUserBasics( rc.t, rc.player )>
	<cfif rc.playerData.recordcount>
		<cfset variables.commishService.markAsPaid( rc.t, rc.player )>
		<cfif variables.commishService.checkSpecial( rc.t, rc.player ) is false>
			<cfset variables.commishService.addBankroll( rc.t, rc.player )>
		</cfif>
	</cfif>
	<cfset variables.fw.redirect( "commish/players/#rc.t#" )>
</cffunction>

<cffunction name="rebuy" hint="add x to 'special' to get to $2000 and flip rebuy to 1; make sure player is indeed in tourney before action">
	<cfargument name="rc">
	<cfset rc.playerData = variables.tourneyService.getStandings( rc.t, rc.userID )>
 	<cfif rc.playerData.recordcount AND rc.playerData.bankroll LT 100 AND rc.playerData.rebuy is false AND rc.playerData.haspaid is true>
		<cfset variables.commishService.markRebuy( rc.t, rc.userID )>
		<cfif variables.commishService.checkSpecial( rc.t, rc.userID, "re-buy" ) is false>
 			<cfset variables.commishService.addRebuy( rc.t, rc.userID, rc.playerData.bankroll, rc.tourneyBasics.currentRound )>
		</cfif>
	</cfif>
 	<cfset variables.fw.redirect( "commish/players/#rc.t#" )>
</cffunction>

<cffunction name="status" hint="allow more people or not">
	<cfargument name="rc">
	<cfif rc.tourneyBasics.status EQ "ongoing" AND rc.option EQ 1><!---switch to open--->
		<cfset rc.john = variables.commishService.updateStatus( rc.t, "open" )>
	<cfelseif rc.tourneyBasics.status EQ "open" AND rc.option EQ 2><!---switch to closed--->
		<cfset rc.dulce = variables.commishService.updateStatus( rc.t, "ongoing" )>
	</cfif>
	<cfset variables.fw.redirect( "commish/settings/#rc.t#" )>
</cffunction>

<cffunction name="form_updateSuicide">
	<cfargument name="rc">
	<cfparam name="rc.suicideStarts" default="0">
	<cfparam name="rc.suicideType" default="single">
	<cfparam name="rc.suicidePrize" default="2000">
	<cfset rc.returnMsg = "">
	<cfset rc.suicideKickoff = variables.tourneyService.getSundaykickoff( rc.tourneyBasics.season, rc.tourneyBasics.league, rc.suicideStarts )>
	<cfif rc.suicideStarts LT rc.tourneyBasics.currentRound AND rc.suicideType NEQ "none"><!---fall through if sucideType is none; this cancels suicide---> 
		<cfset rc.returnMsg = "Cannot start in the past. Try again.">	
	<cfelseif rc.suicideStarts EQ rc.tourneyBasics.currentRound AND rc.suicideKickoff LTE DateConvert( "local2Utc", now() ) AND rc.suicideType NEQ "none">
		<cfset rc.returnMsg = "This week has already started. Try again.">	
	<cfelse>
		<cfset variables.commishService.updateSuicide( rc.t, rc.suicideStarts, rc.suicideType, round( rc.suicidePrize ) )>
		<cfset rc.returnMsg = "Updated!">
	</cfif>
	<cfif rc.suicideType EQ "none">
		<cfset variables.fw.redirect( "commish/settings/#rc.t#" )>
	<cfelse>
		<cfset variables.fw.redirect( "commish/settings/#rc.t#", "returnMsg" )>	
	</cfif>
</cffunction>

</cfcomponent>