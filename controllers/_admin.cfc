<cfcomponent extends="common">

<cffunction name="init" hint="set variables for framework API and needed services">
	<cfargument name="fw">
	<cfset variables.fw = arguments.fw>
	<cfset variables.adminService = new services._admin()>
	<cfset variables.tourneyService = new services.tourney()>
</cffunction>

<cffunction name="before">
 	<cfset variables.fw.setLayout( "front" )>
	<cfif session.user.role NEQ "admin">
		<cfset variables.fw.redirect( "/" )>
	</cfif>
</cffunction>

<cffunction name="default" hint="the default view for this section">
	<cfset variables.fw.redirect( "_admin/options" )>
</cffunction>

<cffunction name="options" hint="admin landing page">
	<cfargument name="rc">
	<cfset rc.tourneys = variables.adminService.getTourneysWithPlayerCount() />
</cffunction>

<cffunction name="suicide_random" hint="auto-pick for the forgetful">
	<cfargument name="rc">
	<cfset variables.adminService.autoPickSuicide( rc.season ) />
	<cfset variables.fw.redirect( "_admin" ) />
</cffunction>

<cffunction name="update_bets" hint="figure winners and losers">
	<cfargument name="rc">
	<cfset variables.adminService.figureWinnersLosers( rc.league, rc.season ) />
  	<cfset variables.fw.redirect( "_admin" ) />
</cffunction>

<cffunction name="update_props" hint="figure winenrs and losers for props">
	<cfargument name="rc">
	<cfset variables.adminService.figurePropWinners( rc.league, rc.season ) />
  	<cfset variables.fw.redirect( "_admin" ) />
</cffunction>

<cffunction name="update_suicide" hint="figure winenrs and losers for suicide">
	<cfargument name="rc">
	<cfset variables.adminService.figureSuicideResults( rc.season ) />
  	<cfset variables.fw.redirect( "_admin" )>
</cffunction>

<cffunction name="update_lines">
	<cfargument name="rc">
	<cfset rc.convertTime = variables.convertTime>
	<cfset rc.convertOdds = variables.tourneyService.convertOdds>
	<cfset rc.currentRound = variables.tourneyService.figureCurrentRound( rc.league, rc.season )>
	<cfset rc.games = variables.tourneyService.getBetList( rc.league, rc.season, rc.currentRound )>
</cffunction>

<cffunction name="update_lines_form">
	<cfargument name="rc">
	<cfset rc.convertOdds = variables.tourneyService.convertOdds>
	<cfset variables.adminService.updateTheLines( rc )>
	<cfset variables.fw.redirect( "_admin/update_lines", "season,league" )>	
</cffunction>

</cfcomponent>