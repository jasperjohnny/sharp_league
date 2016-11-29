<cfset rc.pageTitle = "#rc.tourneyBasics.name#: My Bets">
<cfoutput>

<cfif rc.userInfo.recordcount EQ 0>
	<p>We cannot find records of this user participating in "#rc.tourneyBasics.name#".</p>
	
<cfelse>
	<cfif structKeyExists( rc, "returnMsg" )>
		<div class="alert alert-error left">
			<button class="close" data-dismiss="alert">x</button>
			#rc.returnMsg#
		</div>
	</cfif>

	<div class="row">
		<div class="span12">
			<div class="well">
				<div class="row">
					<div class="span2">
						<img style="float: left; margin-right: 20px;" src="#application.imgPath#/profiles/#rc.userInfo.imgFilename#" height="104px" />
					</div>
					<div class="span4">
						<h3 style="margin-bottom: 2px;">#rc.userInfo.firstName# #rc.userInfo.lastName#</h3>
						<cfif rc.show EQ session.user.userID>
							<p style="margin-bottom: 15px;"><a href="/my/profile">Edit Profile</a></p>
						<cfelse>
							<p style="margin-bottom: 15px;" class="hidden-phone">#rc.userInfo.email#</p>
							<p style="margin-bottom: 15px;" class="hidden-tablet"><a href="mailto:#rc.userInfo.email#">Email</a></p>
						</cfif>
						<p style="margin-bottom: 2px;">Bankroll: #dollarFormat( rc.tourneyTotals.bankroll )#</p>
						<p style="margin-bottom: 0;">At risk: #dollarFormat( rc.tourneyTotals.atRisk )#
					</div>
				</div>
			</div>
		</div>
	</div>
	
	<cfif rc.ledger.recordcount EQ 0>
		<p>#rc.userInfo.firstName# has not placed any bets yet in <em>#rc.tourneyBasics.name#</em>.</p>
	<cfelse>
		<div class="accordion" id="accordion2">
			<cfoutput query="rc.ledger" group="round">
			<div class="accordion-group">
				<div class="accordion-heading">
					<cfset variables.roundTotal = rc.getRoundTotals( rc.ledger.round )>
					<a class="accordion-toggle collapsed" data-toggle="collapse" data-parent="##accordion2" href="##collapse#rc.ledger.round#">
					<strong><cfif rc.ledger.round EQ 0>Preseason<cfelse>Round #rc.ledger.round#</cfif>: #dollarFormat( variables.roundTotal )#</strong>
					<cfif variables.roundTotal GT 0>
						<i class="icon-circle-arrow-up"></i>
					</cfif>
					</a>
				</div>
				<div id="collapse#rc.ledger.round#" class="accordion-body <cfif rc.ledger.round EQ rc.tourneyBasics.currentRound AND rc.tourneyBasics.status NEQ "closed">in</cfif> collapse">
					<div class="accordion-inner">
						<ul>
						<cfoutput group="whenPlaced"><!---not exact, but close enough--->
							<li>
							<cfif rc.ledger.result EQ "special">
								<p>#rc.ledger.displayText#: #dollarFormat( rc.ledger.finalAmount )#</p>
							<cfelseif rc.ledger.hide IS TRUE AND session.user.userid NEQ rc.show AND rc.ledger.entireStart NEQ "" AND dateAdd( "n", 5, rc.ledger.entirestart) GT DateConvert( "local2UTC", now() ) AND rc.ledger.result NEQ "loss">
								<!---we delay the reveal for 5 minutes to make sure all the bets are in--->
								<p>Bet hidden until kickoff</p>
							<cfelse>
								<p>#dollarFormat( rc.ledger.risked )# to win #dollarFormat( rc.ledger.toWin )#
								<cfif rc.ledger.result EQ "win"><span class="label label-success">Win!</span>
								<cfelseif rc.ledger.result EQ "winadj"><span class="label label-success">Win!*</span>
								<cfelseif rc.ledger.result EQ "push"><span class="label label-info">Push</span>
								<cfelseif rc.ledger.result EQ "loss"><span class="label">Loss</span>
								</cfif>
								<br />
								<span class="subtext">
								<cfoutput>
									<cfif rc.ledger.hide IS TRUE AND session.user.userid NEQ rc.show AND rc.ledger.segmentStart NEQ "" AND dateAdd( "n", 5, rc.ledger.segmentStart) GT DateConvert( "local2UTC", now() ) AND rc.ledger.result NEQ "loss">
										&ndash;segment hidden<br />										
									<cfelse>
										#Replace( rc.ledger.displayText, "|", "<br />", "all" )#<!---backwards compatability--->
										<cfif rc.ledger.segResult EQ "loss"><strong>x</strong></cfif><br />
									</cfif>
								</cfoutput>
								<cfif rc.ledger.result EQ "winadj"><em>*bet adjusted due to a push</em></cfif>
								<cfif rc.ledger.hide IS TRUE AND session.user.userid EQ rc.show AND rc.ledger.result EQ "undecided"><em><i class="icon-hand-right"></i> bet hidden from others until kickoff</em></cfif>
								</span>
								</p>
							</cfif>
							</li>
						</cfoutput>
						</ul>
					</div>
				</div>
			</div>
			</cfoutput>
		</div>
	</cfif>
</cfif>

</cfoutput>

<!--- 
<cfdump var="#rc#">
 --->
