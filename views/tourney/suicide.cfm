<cfprocessingdirective suppressWhiteSpace="true">
<cfset rc.pageTitle = "#rc.tourneyBasics.name#: Suicide">
<cfoutput>
	
<h3>Suicide Pool</h3>

<div class="row">
	<div class="span10">
		<cfif rc.tourneyBasics.status NEQ "closed">
			<p><blockquote>Select one team each week to win its game outright. If they win, you advance.
				<cfif rc.tourneyBasics.suicideType EQ "double">Double elimination, last
				<cfelse>Last </cfif>person remaining wins. Please submit picks by kickoff on Sunday.</blockquote></p>
		</cfif>
		<cfif rc.t EQ 7>
			<!---This tourney had two suicide pools.--->
			<p><strong>Suicide Pool 1 Winners:</strong> Geoff Berlin, sean denvir, elliot glass, Kevin Hood, Brad Miller, Jason Peetz, clark perkins</p>
			<p><strong>Suicide Pool 2 Winners:</strong> sean denvir, Raj Pandit, Geoff Berlin, Jared Haynes, Joseph Mason, clark perkins, Matthew Riley</p>
		<cfelseif structKeyExists(rc, "winners") AND rc.winners.recordcount>
			<h4>WINNER<cfif rc.winners.recordcount GT 1>S</cfif>:
				<cfloop query="rc.winners">
					#rc.winners.firstName# #rc.winners.lastName#<cfif rc.winners.currentRow LT rc.winners.recordcount>, </cfif>
				</cfloop></h4>
		<cfelseif rc.suicide.isdead is true>
			<p>Sorry, you are out of contention for the suicide pool.</p>
		<cfelseif trim( rc.suicide.currentTeam ) NEQ "">
			<p>Your choice for Week #rc.tourneyBasics.currentRound#: <strong>#rc.suicide.currentTeam#</strong>.</p>
		<cfelseif trim( rc.suicide.currentTeam ) EQ "" AND DateConvert( 'local2Utc', now() ) GT rc.sundayStart >
			<p>You did not choose a team this week. The computer will pick randomly for you.</p>
		<!---else show the form to pick--->
		<cfelse>
			<form action="/tourney/suicide_form/t/#rc.t#" method="post">				
				<table class="table table-striped table-condensed">
					<tr>
						<th>Home</th>
						<th>Away</th>
						<th class="hidden-phone">Kickoff</th>
						<th>Line</th>
					</tr>
				<cfloop query="rc.betList">
					<cfset localGametime = rc.convertTime( rc.betList.gametime, session.user.timezone )>
					<tr>
						<td><input type="radio" name="selection" value="#rc.betList.home#" <cfif listFindNoCase( rc.suicide.teamspicked, rc.betList.home )>disabled="disabled"</cfif>> <span class="hidden-phone">#rc.betList.homeArea# </span> #rc.betList.homeTeam#</td>
						<td><input type="radio" name="selection" value="#rc.betList.away#" <cfif listFindNoCase( rc.suicide.teamspicked, rc.betList.away )>disabled="disabled"</cfif>> <span class="hidden-phone">#rc.betList.awayArea# </span> #rc.betList.awayTeam#</td>
						<td class="hidden-phone">#dateformat( localGametime, "ddd")# #timeFormat( localGametime, "h:mm")#</td>
						<td>
							<cfif rc.betList.homeSpread LTE 0>
								#rc.betList.home# #numberformat( rc.betList.homeSpread, "+.9" )#
							<cfelse>
								#rc.betList.away# #numberformat( ( rc.betList.homeSpread * -1 ), "+.9" )# 					
							</cfif>
						</td>
					</tr>
				</cfloop>
				</table>
				<p class="right"><input type="submit" class="btn" name="submit" value="submit pick"></p>
			</form>
		</cfif>
		</div>
	<cfif rc.tourneyBasics.status NEQ "closed">
		<div class="span2">
			<p><strong>Grand Prize</strong> <i class="icon-star-empty"></i><br />#dollarFormat( rc.tourneyBasics.suicidePrize )# added to your bankroll.</p>
		</div>
	</cfif>
</div>

<cfif structKeyExists( rc, "suicide" ) AND rc.suicide.picks.recordcount AND rc.t NEQ 7>
	<h3 style="margin: 20px 0 10px;">Picks</h3>
	<table>
		<cfoutput query="rc.suicide.picks" group="userID">
		<tr>
			<td>#rc.suicide.picks.firstName# #rc.suicide.picks.lastName#&nbsp;&nbsp;</td>
			<td><cfoutput><cfif rc.suicide.picks.round LT rc.tourneyBasics.currentRound OR rc.sundaystart LT DateConvert( "local2Utc",now() )><span class="label <cfif rc.suicide.picks.result EQ 'loss'>label-important</cfif>">#rc.suicide.picks.team#</span></cfif>&nbsp;</cfoutput></td>
		</tr>
		</cfoutput>
	</table>
</cfif>
<cfif structKeyExists( rc, "suicide" )>
	<p style="margin: 20px 0;"><small>Everyone's picks are revealed after the first kickoff on Sunday. If you don't chose, the computer will pick a random team for you.</small></p>
</cfif>
<!--- <cfdump var="#rc#"> --->
</cfoutput>
</cfprocessingdirective>