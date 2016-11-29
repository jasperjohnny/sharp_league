<cfoutput>

<div>
	<cfif structKeyExists( rc, "returnMsg" )>
		<div class="alert alert-error left">
			<button class="close" data-dismiss="alert">x</button>
			#rc.returnMsg#
		</div>
	</cfif>

	<cfset variables.localGametime = rc.convertTime( rc.superStart, session.user.timezone )>
	<h3>Super Bowl Prop Game</h3>
	<p>One point per correct answer. Most points wins.
	You can make edits until kickoff &ndash; #dateformat( variables.localGametime, "dddd, mmmm dd")#, #timeFormat( variables.localGametime, "short")#.</p>

	<div class="row">
		<div <cfif rc.canEdit is false>class="span9"<cfelse>class="span12"</cfif>>
			<p style="margin-top: 10px;"><strong>
			<cfif session.user.userID NEQ rc.show>
				#rc.userInfo.firstname# #rc.userInfo.lastname#'s Picks
			<cfelse>
				My Picks
			</cfif>
			</strong>
			</p>
			<cfif rc.superPicks.recordcount>
				<div>
				<cfloop query="rc.superPicks">
					<cfif rc.superPicks.result EQ "win">
						<p class="hanging-indent"><i class="icon-ok"></i>
					<cfelseif rc.superPicks.result EQ "loss">
						<p class="hanging-indent"><i class="icon-remove"></i>
					<cfelse>
						<p style="margin: 0 0 10px 18px;">
					</cfif>
					#rc.superPicks.theProp# <strong>#rc.superPicks.theOption#</strong></p>
				</cfloop>
				<cfif rc.superTieBreak NEQ "">
					<p style="margin: 0 0 10px 18px;">*Tie-breaker: How many points will the winning team have? <strong>#rc.superTieBreak#</strong></p>
				</cfif>
				</div>
			<cfelse>
				<p>No picks yet.</p>
			</cfif>
			<cfif rc.canEdit is true>
				<p style="margin: 20px 0;"><a class="btn" href="/tourney/super_entry/#rc.t#">Edit Picks</a></p>
				<cfif rc.superPicks.recordcount NEQ rc.propCount>
					<div class="alert">
						<button class="close" data-dismiss="alert">x</button>
						<i class="icon-warning-sign"></i> Warning: 
						You have only picked #rc.superPicks.recordcount# of #rc.propCount# available props.
					</div>
				</cfif>
			</cfif>
		</div>
		<cfif rc.canEdit is false>
			<div class="span3">
				<div class="well">
					<p>Leaderboard</p>
					<p>
					<cfloop query="rc.leaderboard">
						<a href="/tourney/super/#rc.t#/#rc.leaderboard.userID#">#rc.leaderboard.firstName# #rc.leaderboard.lastName#</a> <span style="float: right">#rc.leaderboard.score#</span><br />
					</cfloop>
					</p>
				</div>
			</div>
		</cfif>
	</div>
</div>		
<!--- <cfdump var="#rc#"> --->

</cfoutput>