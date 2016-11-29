<cfoutput>

<div class="row">
	<div class="span3">
		<div class="well" style="padding: 8px 0; background-color: white;">
			<ul class="nav nav-list">
 				<li class="nav-header">Commissioner Tools</li>
				<li><a href="/commish/players/#rc.t#">Players</a></li>
				<li><a href="/commish/invites/#rc.t#">Invitations</a></li>
				<li class="active"><a href="/commish/settings/#rc.t#">Settings</a></li>
			</ul>
		</div>
	</div>
	<div class="span9">
		<h4 style="margin-top: 12px;">Tourney Status</h4>
		<p>Is this tourney currently accepting new players?
			<cfif rc.tourneyBasics.status EQ "closed">
				<strong>No.</strong>This sucker is closed.
			<cfelseif rc.tourneyBasics.status EQ "ongoing">
				<strong>No.</strong><br /><a href="/commish/status/#rc.t#/1">Allow new people to join</a>
			<cfelseif rc.tourneyBasics.status EQ "open">
				<strong>Yes.</strong><br /><a href="/commish/status/#rc.t#/2">Close it, no more people</a>
			<cfelse>
				Um, not sure.
			</cfif>
		</p>

		<!--- SUICIDE POOL for NFL tourneys --->
		<cfif rc.tourneyBasics.league EQ "NFL">
			<br />
			<h4>Suicide Pool</h4>
			<cfsavecontent variable="variables.suicideForm">
				<form action="/commish/form_updateSuicide/t/#rc.t#" method="post" style="margin: 0;">
					<p>Starting Week: <input type="text" name="suicideStarts" value="<cfif rc.tourneyBasics.suicideType EQ "none">#( rc.tourneyBasics.currentround + 1 )#<cfelse>#rc.tourneyBasics.suicideStarts#</cfif>" class="span1"><br />
						Prize Money: <input type="text" name="suicidePrize" value="#rc.tourneyBasics.suicidePrize#" class="input-mini"><br />
						Elimination Type: &nbsp;&nbsp;
						<input type="radio" name="suicideType" value="single" <cfif rc.tourneyBasics.suicideType EQ "single" OR rc.tourneyBasics.suicideType EQ "none">checked</cfif>> single &nbsp;&nbsp;
						<input type="radio" name="suicideType" value="double" <cfif rc.tourneyBasics.suicideType EQ "double">checked</cfif>> double</p>
					<p style="margin: 0px;">
						<a href="/commish/form_updateSuicide/t/#rc.t#/suicideType/none" class="btn">cancel</a>
						<input type="submit" value="<cfif rc.tourneyBasics.suicideType EQ "none">create<cfelse>update</cfif>" name="submit" class="btn btn-primary">
					</p>
					<p style="margin-top: 5px;"><small>*The pool winner gets the prize added to his/her bankroll.</small></p>
					<cfif structKeyExists( rc, "returnMsg" )>
						<div class="alert alert-error left">
							<button class="close" data-dismiss="alert">x</button>
							#rc.returnMsg#
						</div>
					</cfif>
				</form>
			</cfsavecontent>
			<!---you can edit the suicide pool up until kickoff of the suicide start week. After that, no edits--->
			<cfif rc.tourneyBasics.suicideType EQ "none">
				<cfif structKeyExists( rc, "returnMsg" )><!---this is a return Msg is user tries to create suicide but something is wrong--->
					<div>
				<cfelse>
					<p id="SuicideIntro">This tourney has no suicide pool. <a href="##" id="showSuicideForm">Start One</a></p>
					<div id="SuicideForm" style="display:none;">
				</cfif>
					#variables.suicideForm#
				</div>
			<cfelseif rc.suicideKickoff EQ "" OR rc.suicideKickoff GT DateConvert( "local2Utc", now() )>
				#variables.suicideForm#
			<cfelse>
				<p>The suicide pool has begun. It is #rc.tourneyBasics.suicideType# elimination.<br />Winner gets #dollarFormat( rc.tourneyBasics.suicidePrize )#.</p>
			</cfif>
		</cfif>
	</div>
</div>

<script type="text/javascript">
	$('##showSuicideForm').on('click', function() {
		$('##SuicideForm').show();
		$('##SuicideIntro').hide();
		});
</script>


<!--- <cfdump var="#rc#"> --->

</cfoutput>