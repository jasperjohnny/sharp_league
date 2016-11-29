<cfset rc.pageTitle = "#rc.tourneyBasics.name#: Confirm Bet">
<cfoutput>

<br />
<h3>Confirm Bet</h3>

<div class="row">
	<div class="span6">
		<div class="alert">
			<p><strong>#dollarFormat( rc.betInfo.amount )#</strong> to win <strong>#dollarFormat( rc.toWin )#</strong></p>
			<ul style="margin-bottom: 0;">
			<cfloop array="#rc.betArray#" index="itm">
				<li id="#itm.segmentID#" multiplier="#itm.multiplier#">#itm.displayText#</li>
			</cfloop>
			</ul>
		</div>

		<cfform action="/tourney/place_form/#rc.t#" method="post">
			<input type="checkbox" name="hideThis" value="1"> Hide bet until kickoff time?</p>
			<input type="hidden" name="tempID" value="#rc.tempID#" />
			<input type="submit" value="place bet" name="place" class="btn" />
		</cfform>
		
		<p><small>This bet is valid until #timeFormat( rc.convertTime( rc.betInfo.expiry, session.user.timezone ), "short" )#.</small></p>
	</div>
</div>

</cfoutput>

<!--- <cfdump var="#rc#"> --->