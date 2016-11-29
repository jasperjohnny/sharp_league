
<cfset rc.pageTitle = "#rc.tourneyBasics.name#: Lobby">
<cfoutput>

<cfif structKeyExists( rc, "newCommish" )>
	<div class="alert">
		<button class="close" data-dismiss="alert">x</button>
		Tourney created successfully! Be sure to click on "Tools" above to explore your commissioner powers.<br />
		Before players can bet, you need to credit their account. Best of luck.
	</div>
</cfif>	

<div class="row">
	<div class="span8">
		<table class="table table-striped table-condensed">
			<thead>
			<tr>
				<th />
				<th><strong>Bankroll</strong></th>
				<th><strong>At Risk</strong></th>
			</tr>
			</thead>
			<cfloop query="rc.tourneyStandings">
			<tr>
				<td><a href="/tourney/ledger/#rc.t#/#rc.tourneyStandings.userID#">#rc.tourneyStandings.firstName# #rc.tourneyStandings.lastName#</a></td>
				<td><cfif rc.tourneyStandings.bankroll LT 0><cfset rc.tourneyStandings.bankroll = 0></cfif>#dollarFormat( rc.tourneyStandings.bankroll )#</td>
				<td>#dollarFormat( rc.tourneyStandings.atRisk )#</td>
			</tr>
			</cfloop>
		</table>
	</div>
	<div class="span4">
		<cfif rc.tourneyBasics.status EQ "closed">
			<div class="hidden-phone" style="width:200px;height:150px;margin-left: 20px;background:url('/images/trophy-small.gif') no-repeat;">
				<p style="margin-top: 20px;text-align:center;font-weight:bold;padding-top:15px;">
					<cfif rc.t EQ 1>
						Noam Pines<br />Carl Barrick						
					<cfelse>
						The Champ:<br />#rc.tourneyStandings.firstName[1]#
						<cfif len(rc.tourneyStandings.firstName[1] & rc.tourneyStandings.lastName[1]) GT 12>
							<br />
						</cfif>
						#rc.tourneyStandings.lastName[1]#
					</cfif>

				</p>
			</div>
		</cfif>
		<cfif rc.featured.recordcount>
			<cfset variables.localGametime = rc.convertTime( rc.featured.gametime, session.user.timezone )>
			<div class="hidden-phone" style="margin-left: 20px;">
				<p style="margin-top: 2px;"><strong>Featured Game</strong></p>
				<p><img src="#application.imgPath#/clubs/#rc.featured.awayImg#" width="75" height="75"> <em>-at-</em>
				   <img src="#application.imgPath#/clubs/#rc.featured.homeImg#" width="75" height="75"></p>			
				<p>#dateformat( variables.localGametime, "long")# - #timeFormat( variables.localGametime, "short")#</p>
				<p><a href="/tourney/book/#rc.t#">Place Me Some Bets</a></p>
			</div>
		</cfif>
 		<cfif rc.tourneyBasics.suicideWinner EQ "" AND listFind( session.user.enteredIn, rc.t ) AND rc.suicide.isDead is FALSE AND trim( rc.suicide.currentPick ) EQ "" AND rc.tourneyBasics.status NEQ "closed" AND rc.tourneyBasics.suicideType NEQ "none" AND rc.tourneyBasics.currentRound GTE rc.tourneyBasics.suicideStarts>
			<div style="margin: 20px 0 0 20px;">
				<p><i class="icon-hand-right"></i> Don't forget your <a href="/tourney/suicide/#rc.t#">suicide pick</a>.</p>
			</div>
		</cfif>
 		<cfif rc.tourneyBasics.league EQ "NFLp" AND rc.tourneyBasics.currentRound EQ 4 AND rc.tourneyBasics.status NEQ "closed">
			<div style="padding: 5px; margin: 20px 0;">
				<span class="alert alert-info"><i class="icon-star"></i> 
				<a href="/tourney/super/#rc.t#">Play Super Prop Game</a></span>
			</div>
		</cfif>
		<cfif rc.notables.recordcount>
			<div class="hidden-phone" style="margin: 20px 0 0 20px;">
				<p style="margin-top: 2px;"><strong>Week #rc.notables.round# Notables</strong></p>
				<ul>
				<cfloop query="rc.notables" startRow="1" endRow="3">
					<cfif rc.notables.weekTotal GT 0>
						<li>#rc.notables.firstName# #rc.notables.lastName#: #dollarFormat( rc.notables.weekTotal )#</li>
					</cfif>
				</cfloop>
				<cfif rc.notables.weekTotal[ rc.notables.recordcount ] LT 0>
					<li><em>#rc.notables.firstName[ rc.notables.recordcount ]# #rc.notables.lastName[ rc.notables.recordcount ]#: #dollarFormat( rc.notables.weekTotal[ rc.notables.recordcount ] )#</em></li>
				</cfif>
				</ul>
			</div>
		</cfif>
	</div>
</div>
<hr>
<div class="row">
	<div class="span8">
		<ul id="messageStream" class="unstyled">
			#rc.msgStruct.listItems#
		</ul>
		<cfif rc.msgStruct.showMore IS TRUE>
			<div id="moreArea"><button id="moreBtn" class="btn span3 offset2"><i class="icon-chevron-down"></i> show more</button></div>
		</cfif>
	</div>
	<div class="span4">
		<br />
		<form action="/tourney/comment_form/t/#rc.t#" method="post">
			<textarea rows="5" name="comment" placeholder="Post new message..."></textarea>
			<!---<input type="file" value="Include image" name="image"> --->
			<input type="submit" value="post" name="post" class="btn">
		</form>
	</div>
</div>

<script type="text/javascript">
	$(".message").live("click", function(event) {
		var messageID = $(this).attr("id")
		$("." + messageID + "more").toggle();
		$("." + messageID + "extra").toggle();
	});

	$("##moreBtn").on("click", function(event) {
		var lastid = $("##messageStream li.message").last().attr('id');
	 	$.getJSON("/services/ajax.cfc", {
				method: "renderMessages",
				t: "#rc.t#",
				howMany: 10,
				lastMessageID: lastid }, 
			function(data) {
		    	$("##messageStream").append(data.listItems);
 				if (data.SHOWMORE == false)
					{
					$("##moreBtn").hide();	
					};
		  	});
		});
</script>

</cfoutput>