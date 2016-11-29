<output>

<h3>Admin Area</h3>

<div class="row">
	<div class="span6">
		<br />
		<h4>Sportsbook</h4>
		<p><a href="update_lines?season=2013&league=NFL">Set the Lines</a></p>
		<br />
		<h4>Run these Scripts</h4>
		<p class="subtext"><em>Careful, no confirm, no going back.</em></p>
		<p><a href="suicide_random?season=2013&league=NFL">Assign random suicide picks to the forgetful</a></p>
		<p><a href="update_suicide?season=2013">Calculate suicide winners and losers</a></p>
		<p><a href="update_bets?season=2013&league=NFLp">Calculate bet winners and losers</a></p>
		<p><a href="update_props?season=2013&league=NFLp">Calculate prop winners and losers</a></p>
	</div>
	<div class="span6">
		<br />
		<h4>Tourneys</h4>
		<cfoutput query="rc.tourneys" group="leagueseason">
			#rc.tourneys.leagueseason# <br />
			<ul>
			<cfoutput>
				<li><a href="/tourney/lobby/#rc.tourneys.tourneyID#">#rc.tourneys.name#</a> <span class="subtext">(#rc.tourneys.players#)</span></li>
			</cfoutput>
			</ul>
		</cfoutput>
	</div>
</div>

</output>