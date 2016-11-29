<cfoutput>

<script>
	$(document).ready(function() {
		$.ajaxSetup({ cache: false });
		$("##nowPlaying").load("/services/ajax.cfc?method=renderDashboard");
 	 	var refreshId = setInterval(function() {
			$("##nowPlaying").load('/services/ajax.cfc?method=renderDashboard&randval='+ Math.random());
		}, 30000);
	});
</script>
 
<div class="span8">
	<!---Top content is AJAXed in--->
	<div id="nowPlaying"></div>
	<div style="margin-top: 20px;">
		<p><em>Thanks everyone for playing. Check back come World Cup time.</em></p>
	</div>

	<!---Start a New Tournament--->
<!--- 	<h3 style="margin-top: 15px;">Run Your Own League &ndash; NFL 2013</h3>
	<p>Invite your friends and start a league. Full access, plus commissioner tools. Free.</p> 
	<cfif structKeyExists( rc, "somethingWrong" )>
		<div class="alert alert-success" style="margin-top: 10px;">
			<button class="close" data-dismiss="alert">x</button>
			#rc.somethingWrong#
		</div>
	</cfif>
	<form action="make_tourney_form" method="post" style="margin-top: 20px;">
	<div class="controls input-append" style="padding: 0px;margin-bottom: 10px;">
		<label class="control-label" for="tourneyName">League Name</label>
		<input type="text" id="tourneyName" name="tourneyName">
		<input type="submit" name="submit" value="Create League" class="btn btn btn-primary">
	</div>
	<div style="margin-bottom: 25px;">
		<input type="checkbox" name="suicide" value="1" checked="checked"/> Include the Suicide Pool?
	</div>
	</form>

	<hr> 	 --->
	<!---Join a Free, Public Tournament--->
<!--- 	<h3 style="margin-top: 15px;">Join a Public League &ndash; NFL 2013</h3>
	<p class="subtext">Sharp League's public leagues are a great way to get a feel for how things work and practice betting. Everything is the same, except you play against random people. Free.</p> 
	<cfif structKeyExists( rc, "somethingWrong2" )>
		<div class="alert alert-success" style="margin-top: 10px;">
			<button class="close" data-dismiss="alert">x</button>
			#rc.somethingWrong2#
		</div>
	</cfif>
	<form action="join_public_form" method="post" style="margin-top: 20px;">
		<input type="submit" name="submit" value="Join Public" class="btn btn-primary">
	</form> --->

	<!---Bottom Buckets--->	
	<div class="row" style="margin-top: 30px;">
	<cfif rc.tourneyhistory.recordcount>
		<div class="span4">
			<div class="well">
				<h3>Tourney History</h3>
				<ul>
				<cfloop query="rc.tourneyHistory">
					<li><p><a href="/tourney/lobby/#rc.tourneyHistory.tourneyID#">#rc.tourneyHistory.name#</a> <small>(#rc.tourneyHistory.league# #rc.tourneyHistory.season#)</small></p></li>
				</cfloop>
				</ul>
			</div>
		</div>
	</cfif>
		<div class="span4">
			<div class="well">
				<h3>A Little Help</h3>				
				<ul>
					<li><p><a href="/front/faq">FAQs</a><p></li>
					<li><p><a href="/front/betting_guide">Betting Guide</a></p></li>
				</ul>
			</div>
		</div>	
	</div>
</div>

<!---<cfdump var="#rc#">
<cfdump var="#session#"> --->

</cfoutput>