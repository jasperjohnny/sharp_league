<cfoutput>
<cfprocessingdirective suppresswhitespace="true">

<cfset variables.counter = 1>

<h3>Update Lines</h3>
<br />
<div class="row">
	<div class="span9">
		<form class="form-inline" action="/_admin/update_lines_form" method="post">
		<table class="sportsbook">
			<tr>
				<th class="span2"></th>
				<th>line</th>
				<th>over/under</th>
				<th>moneyline</th>
			</tr>
			<cfloop query="rc.games">
				<cfset localGametime = rc.convertTime( rc.games.gametime, session.user.timezone )>
	 			<tr class="doubleLine">
					<td>#rc.games.away# #rc.games.awayTeam#</td>
					<td></td>
					<td></td>
					<td class="center"><input name="#rc.games.gameID#|awayWin" type="text" value="<cfif rc.games.awayWin NEQ "">#numberformat( rc.convertOdds( rc.games.awayWin ), "+9" )#</cfif>" class="input-mini" tabindex="#( counter + 3 )#"></td>
	 				<td class="subtext">#dateformat( localGametime, "ddd, mmm d")#, #timeformat( localGametime, "short")#</small></p></td>
				</tr>
				<tr>
					<td>#rc.games.home# #rc.games.homeTeam#</td>
					<td class="center"><input name="#rc.games.gameID#|homeSpread" type="text" value="#rc.games.homeSpread#" class="input-mini" tabindex="#counter#"></td>
					<td class="center"><input name="#rc.games.gameID#|overUnder" type="text" value="#rc.games.overUnder#" class="input-mini" tabindex="#( counter + 1 )#"></td>
					<td class="center"><input name="#rc.games.gameID#|homeWin" type="text" value="<cfif rc.games.homeWin NEQ "">#numberformat( rc.convertOdds( rc.games.homeWin ), "+9" )#</cfif>" class="input-mini" tabindex="#( counter + 2 )#"></td>
	 				<td class="subtext">featured? <input type="checkbox" name="#rc.games.gameID#|featured" value="1" <cfif rc.games.featured>checked="checked"</cfif>></td>
				</tr>
				<cfset counter = counter + 4>
			</cfloop>
			<tr class="doubleLine">
				<td colspan="5" class="right">
					<input type="hidden" name="season" value="#rc.season#">
					<input type="hidden" name="league" value="#rc.league#">
					<input type="submit" name="submit" value="submit" class="btn" tabindex="#counter#">
				</td>
			</tr>
		</table>
		</form>
	</div>
</div>

<!--- <cfdump var="#rc#"> --->

</cfprocessingdirective>
</cfoutput>