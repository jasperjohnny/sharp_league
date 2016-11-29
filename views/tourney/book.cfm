<cfset rc.pageTitle = "#rc.tourneyBasics.name#: Book">
<cfoutput>
<cfprocessingdirective suppresswhitespace="true">

<cfif rc.tourneyBasics.status EQ "closed">
	<p>This tournament has concluded, so no more betting. Thanks.</p>

<cfelseif rc.betList.recordcount EQ 0>
	<p>There are no bets available at this time. Come back in a bit. Thanks.</p>

<cfelse>
	<cfif structKeyExists( rc, "returnMsg" )>
		<div class="alert alert-error left">
			<button class="close" data-dismiss="alert">x</button>
			#rc.returnMsg#
		</div>
	</cfif>

	<h3 style="margin: 0px;"><cfif rc.tourneyBasics.league EQ "NFLp">NFL Playoffs<cfelse>#rc.tourneyBasics.league#</cfif> Week #rc.tourneyBasics.currentRound#</h3>

	<cfif rc.propList.recordcount>
		<ul class="nav nav-pills" id="myTab" style="margin: 10px 0 0;">
			<li class="active"><a href="##games" data-toggle="tab">Games</a></li>
			<li><a href="##props" data-toggle="tab">Props</a></li>
		</ul>
	</cfif>
	
	<div class="tab-content">
		<!---GAMES tab--->
		<div class="tab-pane active" id="games">
			<form action="/tourney/review/#rc.t#" method="post" style="margin: 0;"> 
			<table class="sportsbook">
				<tr>
					<td />
					<th class="right"><span class="hidden-phone">point spread</span></th>
					<th class="right"><span class="hidden-phone">moneyline</span></th>
					<td class="right"><input type="submit" name="submit" value="next >" class="btn"></td>
				</tr>
				<cfoutput query="rc.betList" group="gametime">
			 		<tr class="info doubleLine">
						<td colspan="4"><strong>
						<cfset localGametime = rc.convertTime( rc.betList.gametime, session.user.timezone )>
						#dateformat( localGametime, "long")# &ndash; #timeFormat( localGametime, "short")#
						</strong></td>
					</tr>
					<cfoutput>
						<tr class="doubleLine">
							<td><span class="hidden-phone">#rc.betList.awayArea# </span>#rc.betList.awayTeam#</td>
							<td class="right">
								<cfif rc.betList.homeSpread EQ "">&mdash;<cfelse>
									#numberformat( ( rc.betList.homeSpread * -1 ), "+.9" )# <input type="checkbox" name="betString" value="#rc.betList.gameID#|1" multiplier=".9091">
								</cfif>
							</td>
							<td class="right">
								<cfif rc.betList.awayWin EQ "">&mdash;<cfelse>
									#numberformat( rc.convertOdds( rc.betList.awayWin ), "+9" )# <input type="checkbox" name="betString" value="#rc.betList.gameID#|2" multiplier="#rc.betList.awayWin#">
								</cfif>
							</td>
							<td class="right lightGrey">
								<cfif rc.betList.overUnder EQ "">&mdash;<cfelse>
									o<span class="hidden-phone">ver</span> #numberformat( rc.betList.overUnder, ".9" )# <input type="checkbox" name="betString" value="#rc.betList.gameID#|5" multiplier=".9091">
								</cfif>
							</td>
						</tr>
						<tr>
							<td><span class="hidden-phone">#rc.betList.homeArea# </span>#rc.betList.homeTeam#</td>				
							<td class="right">
								<cfif rc.betList.homeSpread EQ "">&mdash;<cfelse>
									#numberformat( rc.betList.homeSpread, "+.9" )# <input type="checkbox" name="betString" value="#rc.betList.gameID#|3" multiplier=".9091">
								</cfif>
							</td>
							<td class="right">
								<cfif rc.betList.homeWin EQ "">&mdash;<cfelse>
									#numberformat( rc.convertOdds( rc.betList.homeWin ), "+9" )# <input type="checkbox" name="betString" value="#rc.betList.gameID#|4" multiplier="#rc.betList.homeWin#">
								</cfif>
							</td>
							<td class="right lightGrey noTop">
								<cfif rc.betList.overUnder EQ "">&mdash;<cfelse>
									u<span class="hidden-phone">nder</span> #numberformat( rc.betList.overUnder, ".9" )# <input type="checkbox" name="betString" value="#rc.betList.gameID#|6" multiplier=".9091">
								</cfif>
							</td>
						</tr>
					</cfoutput>
				</cfoutput>
				<tr class="doubleLine">
					<td colspan="4" align="right">
						<input type="hidden" name="betType" value="game">
						<input type="submit" name="submit" value="next->" class="btn">
					</td>
				</tr>
			</table>
			</form>
		</div>
		<!---Props tab--->
		<cfif rc.propList.recordcount>
			<div class="tab-pane" id="props">
				<form action="/tourney/review/#rc.t#" method="post" style="margin: 0;"> 
				<table class="sportsbook">
					<tr>
						<td />
						<td class="right"><input type="submit" name="submit" value="next >" class="btn"></td>
					</tr>
					<cfoutput query="rc.propList" group="propID">
					<tr class="info doubleLine">
						<td><strong>#rc.propList.theProp#</strong></td>
						<td style="text-align: right;" class="subtext">
							<cfset localGametime = rc.convertTime( rc.propList.cutoff, session.user.timezone )>
							<span class="hidden-phone">closes #dateformat( localGametime, "m/dd")#, #timeFormat( localGametime, "short")#						
						</td>
					</tr>
						<cfset counter = 1 />
						<cfoutput>
							<tr <cfif counter EQ 1>class="doubleLine"</cfif>>
								<td>#rc.propList.theOption#</td>
								<td><input type="checkbox" name="propString" value="#rc.propList.propOptID#">#numberformat( rc.convertOdds( rc.propList.line ), "+9" )#</td>
							</tr>
							<cfset counter = counter + 1 />
						</cfoutput>
					</cfoutput>
					<tr class="doubleLine">
						<td colspan="4" align="right">
							<input type="hidden" name="betType" value="prop">
							<input action="prop" type="submit" name="submit" value="next->" class="btn">
						</td>
					</tr>
				</table>
				</form>
			</div>
		</cfif>
	</div>

	<p><em>All times are for "#session.user.timezone#". <a href="/my/profile">Change</a></em></p>
</cfif>

</cfprocessingdirective>
</cfoutput>
<!--- <cfdump var="#rc#"> --->
