<cfoutput>

<div>
	<cfif structKeyExists( rc, "returnMsg" )>
		<div class="alert alert-error left">
			<button class="close" data-dismiss="alert">x</button>
			#rc.returnMsg#
		</div>
	</cfif>
	<form action="/tourney/super_form/t/#rc.t#" method="post" style="margin: 0;"> 
	<cfset variables.localGametime = rc.convertTime( rc.cutoff, session.user.timezone )>
	<h3>Super Bowl Prop Game</h3>
	<p>One point per correct answer. Most points wins.
	You can make edits until kickoff &ndash; #dateformat( variables.localGametime, "dddd, mmmm dd")#, #timeFormat( variables.localGametime, "short")#.</p>

	<table class="sportsbook">
		<tr>
			<td class="right"><input type="submit" name="submit" value="submit->" class="btn"></td>
		</tr>
		<cfoutput query="rc.propList" group="propID">
		<tr class="info doubleLine">
			<td><strong>#rc.propList.theProp#</strong></td>
		</tr>
			<cfset counter = 1 />
			<cfoutput>
				<tr <cfif counter EQ 1>class="doubleLine"</cfif>>
					<td>
						<input style="margin: 3px 5px;" <cfif rc.propList.hasPicked>checked="checked"</cfif> type="radio" name="#rc.propList.propID#" value="#rc.propList.propOptID#">
						#rc.propList.theOption#
					</td>
				</tr>
				<cfset counter = counter + 1 />
			</cfoutput>
		</cfoutput>
		<tr class="info doubleLine">
			<td><strong>*Tie-breaker: How many points will the winning team have?</strong></td>
		</tr>
		<tr class="doubleLine">
			<td style="vertical-align: middle;"><input class="span1" type="text" name="tiebreaker" value="#rc.superTieBreak#"> Please enter a number. (The closest wins.)</td>
		</tr>
		<tr class="doubleLine">
			<td align="right">
				<input action="submit" type="submit" name="submit" value="submit->" class="btn">
			</td>
		</tr>
	</table>
	</form>
</div>

<!--- <cfdump var="#rc#"> --->

</cfoutput>