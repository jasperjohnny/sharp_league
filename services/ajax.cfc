<cfcomponent extends="common">

<cffunction name="hello" access="remote" return="plain" hint="for testing">
	<cfreturn "hello world" />
	
</cffunction>

<cffunction name="getMessages" hint="get messages for tourney lobby">
	<cfargument name="t">
	<cfargument name="howMany" required="false">
	<cfargument name="lastMessageID" required="false" default="0">
	<cfset var getAll = "">
	<cfquery name="getAll">
		SELECT messages.*, users.firstname, users.lastname, users.imgFilename 
		FROM messages
		JOIN users
		ON messages.userID = users.userID
		<!---messageIDs are chronological. A higher number happened later than a lower one--->
		WHERE
			( tourneyID = <cfqueryparam value="#arguments.t#" cfsqltype="integer">
			OR ( league = 
					( SELECT league
					FROM tourneys
					WHERE tourneyID = <cfqueryparam value="#arguments.t#" cfsqltype="integer"> )
				AND season = 
					( SELECT season
					FROM tourneys
					WHERE tourneyID = <cfqueryparam value="#arguments.t#" cfsqltype="integer"> ) ) )
		<cfif arguments.lastMessageID NEQ 0>
			AND messageID < <cfqueryparam value="#arguments.lastMessageID#" cfsqltype="integer">
		</cfif>
		ORDER BY timestamp DESC		
		LIMIT <cfqueryparam value="#arguments.howMany#" cfsqltype="integer">
	</cfquery>
	<cfreturn getAll>
</cffunction>

<cffunction name="renderMessages" access="remote" returnformat="JSON" returntype="struct">
	<cfargument name="t">
	<cfargument name="howMany" required="false" default="5">
	<cfargument name="lastMessageID" required="false" default="0">
	
 	<cfif listFind( session.user.enteredIn, arguments.t ) OR session.user.role EQ "admin">
		<cfset local.messages = getMessages( arguments.t, arguments.howMany + 1, arguments.lastMessageID )>
		<cfsavecontent variable="local.dataStruct.listItems">
		<cfoutput>
		<cfprocessingdirective suppressWhiteSpace="yes">
		<cfloop query="local.messages" endRow="#arguments.howMany#">
			<cfset variables.messageTime = convertTime( local.messages.timestamp, session.user.timezone )>
			<li class="message" id="#local.messages.messageID#">
				<img style="float: left; margin: 0 10px 0 0;" src="#application.imgPath#/profiles/#local.messages.imgFilename#" height="50px" />
				<strong>#local.messages.firstname# #local.messages.lastname#</strong><br />
				<cfif len( local.messages.content ) GT 180>
					<p><cfset variables.firstPart = left( local.messages.content, 180 )>
					<cfset variables.secondPart = right( local.messages.content, len( local.messages.content ) - 180 )>
					#HTMLEditFormat( variables.firstPart )#<span class="#local.messages.messageID#extra" style="display: none;">#variables.secondPart#</span>
					<span class="#local.messages.messageID#more"><em><small>...expand</small></em></span></p>
				<cfelse>
					<p>#HTMLEditFormat( local.messages.content )#</p>
				</cfif>
				<div class="#local.messages.messageID#extra right" style="display: none;">
					<cfif local.messages.image NEQ "">
						<p class="center"><img src="#application.imgPath#/boards/#local.messages.image#" width="200" /></p>
					</cfif>
					<p style="margin: 10px 5px" class="right"><small>#DateFormat( variables.messageTime, "long" )# &ndash; #TimeFormat( variables.messageTime, "short" )#</small></p>
				</div>
			</li>
		</cfloop>
		</cfprocessingdirective>
		</cfoutput>
		</cfsavecontent>
		<!---figure out if we should show the "more" button; if we brought back the max + 1, then there is more--->		
		<cfif local.messages.recordcount EQ ( arguments.howMany + 1 )>
			<cfset local.datastruct.showMore = TRUE>
		<cfelse>
			<cfset local.datastruct.showMore = FALSE>
		</cfif>		
		<cfreturn local.dataStruct>
	<cfelse>
		<cfreturn "">
	</cfif>
</cffunction>

<cffunction name="getNowPlaying" hint="gets expanded info for in progress tourneys">
	<cfargument name="userID" required="true">
	<cfset var getCurrent = "">
	<cfquery name="getCurrent">
		SELECT tourneys.name, tourneys.tourneyID, tourneys.league, tourneys.season, 
			v_TourneyTotals.bankroll, v_TourneyTotals.atrisk, v_CurrentRound.currentRound, sub1.*
		FROM enteredIn
		JOIN tourneys 
		ON enteredIn.tourneyID = tourneys.tourneyID
 		LEFT JOIN v_TourneyTotals
		ON enteredIn.tourneyID = v_TourneyTotals.tourneyID AND enteredIn.userID = v_TourneyTotals.userID
		LEFT JOIN v_CurrentRound
		ON tourneys.league = v_CurrentRound.league AND tourneys.season = v_CurrentRound.season
		LEFT JOIN (
			SELECT bets.tourneyID, bets.round AS betRound, bets.betID, bets.risked, bets.towin, bets.result as wholeResult, 
				betDetail.segmentID, betDetail.optionID, betDetail.mark, betDetail.result AS segResult, betDetail.displayText,
				games.homeFinal, games.awayFinal, games.status, games.timeRemaining, games.home, games.away, games.gametime
			FROM bets
			JOIN betDetail
			ON bets.betID = betDetail.betID
			LEFT JOIN games
			ON betDetail.gameID = games.gameID
			WHERE userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
			ORDER BY bets.result
			) as sub1
		ON tourneys.tourneyID = sub1.tourneyID AND v_CurrentRound.currentRound = sub1.betRound
		WHERE enteredIn.userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
		AND tourneys.status IN ( 'open', 'upcoming', 'ongoing' )
		ORDER BY enteredIn.tourneyID, sub1.betID, sub1.gametime, sub1.segmentID
	</cfquery>	
	<cfreturn getCurrent>
</cffunction>

<cffunction name="renderDashboard" access="remote" returnformat="plain">
	<cfset var hasBets = false>
	<cfset local.nowPlaying = getNowPlaying( session.user.userID )>
	<cfsavecontent variable="formattedCode"><cfoutput>
		<cfif local.nowPlaying.recordcount>
			<p style="margin: 20px 0 0"><span class="label label-info">Now Playing</span></p>
			<cfoutput query="local.nowPlaying" group="tourneyID">
				<h2 style="margin-top: 10px;"><a href="/tourney/lobby/#local.nowPlaying.tourneyID#">#local.nowPlaying.name#</a></h2>
				<p> Week #val( local.nowPlaying.currentRound )# | Bank: #dollarFormat( local.nowPlaying.bankroll )# | Risk: #dollarFormat( local.nowPlaying.atrisk )# | <a href="/tourney/book/#local.nowPlaying.tourneyID#">Sportsbook</a></p>
		
				<cfif local.nowPlaying.betID EQ "">
					<p style="margin: 15px 0 20px;">No bets currently.</p>		
				<cfelse>
					<table class="table table-striped" style="margin-bottom: 20px;">
						<cfoutput group="betID">
							<tr>
								<td>
									<p style="margin: 0 0;">
										#dollarFormat( local.nowPlaying.risked )# to win #dollarFormat( local.nowPlaying.towin )#
										<cfif local.nowPlaying.wholeResult EQ "win"><span class="label label-success">Win!</span>
										<cfelseif local.nowPlaying.wholeResult EQ "winadj"><span class="label label-success">Win!*</span>
										<cfelseif local.nowPlaying.wholeResult EQ "push"><span class="label label-info">Push</span>
										<cfelseif local.nowPlaying.wholeResult EQ "loss"><span class="label">Loss</span>
										</cfif>
									</p>
									<ul style="margin-bottom: 0px;">
									<cfoutput>
										<li>
											#replace( local.nowPlaying.displayText, " points", "" )# 
											<cfset local.winlosedraw = "">
											<cfif local.nowPlaying.segResult NEQ "undecided">
												<cfset local.winlosedraw = local.nowPlaying.segResult>
											<cfelseif local.nowPlaying.status NEQ "Pregame" AND local.nowPlaying.status NEQ ""><!---game in progress or finished--->
												<cfset local.winlosedraw = didIwin( val( local.nowPlaying.homeFinal ), val( local.nowPlaying.awayFinal ), local.nowPlaying.optionID, local.nowPlaying.mark )>
											</cfif>
											<cfif local.winlosedraw NEQ "">
												<cfif local.winlosedraw EQ "win">
													<i class="icon-ok"></i>
												<cfelseif local.winlosedraw EQ "push">
													<i class="icon-adjust"></i>
												<cfelse>
													<i class="icon-remove"></i>
												</cfif>
											</cfif>
											<cfif local.nowPlaying.status NEQ "Pregame" AND local.nowPlaying.status NEQ ""><!---we have some score info--->
												<span class="hidden-tablet"><br /></span>
												<span class="subtext">#local.nowPlaying.home# #val( local.nowPlaying.homeFinal )#, #local.nowPlaying.away# #val( local.nowPlaying.awayFinal )#
												&ndash; <cfif local.nowPlaying.status EQ "Final" OR local.nowPlaying.status EQ "Halftime">#local.nowPlaying.status#
													    <cfelseif local.nowPlaying.status EQ 5>OT #local.nowPlaying.timeRemaining#
													    <cfelseif local.nowPlaying.status EQ "final overtime">Final OT
													    <cfelse>Q#local.nowPlaying.status# #local.nowPlaying.timeRemaining#
														</cfif></span>
											<cfelseif local.nowPlaying.gametime NEQ "">
												<cfset variables.localGametime = convertTime( local.nowPlaying.gametime, session.user.timezone )>
												<span class="subtext hidden-phone">&ndash; #dateformat( variables.localGametime, "dddd")#, #timeFormat( variables.localGametime, "short")#</span>
											</cfif>
										</li>
									</cfoutput>
									</ul>
								</td>
							</tr>
						</cfoutput>
					</table>
					<cfset local.hasBets = true>
				</cfif>
			</cfoutput>
			<cfif local.hasBets>
				<p style="margin: 20px 0;" class="subtext"><em>*Scores update every 30 secs. No need to refresh.</em></p>
			</cfif>
			<hr>
		</cfif>
	</cfoutput></cfsavecontent>

	<cfreturn formattedCode />
</cffunction>

<cffunction name="areWeAnnoying" hint="check to see if we've sent an email to this person today">
	<cfargument name="t">
	<cfargument name="toEmail">
	<cfset checkInvite = "">
	<cfquery name="checkInvite">
		SELECT *
		FROM invitations
		WHERE tourneyID = <cfqueryparam value="#arguments.t#" cfsqltype="integer">
		AND toEmail = <cfqueryparam value="#arguments.toEmail#">
		AND timesent > #DateAdd( "d", -1, DateConvert( 'local2Utc', now() ) )#
	</cfquery>
	<cfif checkInvite.recordcount>
		<cfreturn true />
	<cfelse>
		<cfreturn false />
	</cfif>
</cffunction> 

<cffunction name="insertInvite" hint="for emails">
	<cfargument name="t">
	<cfargument name="userID">
	<cfargument name="toEmail">
	<cfset insertInvite = "">
	<cftry>
		<cfquery name="insertInvite">
			INSERT INTO invitations ( tourneyID, senderID, toEmail, timeSent )
			VALUES ( <cfqueryparam value="#arguments.t#" cfsqltype="integer">,
					 <cfqueryparam value="#arguments.userID#" cfsqltype="integer">,
					 <cfqueryparam value="#arguments.toEmail#">,
					 #DateConvert( 'local2Utc', now() )# )
		</cfquery>
		<cfreturn true>
		<cfcatch>
			<cfset logDbError( cfcatch, "ajax.insertInvite" )>									
			<cfreturn false>
		</cfcatch>
	</cftry>
</cffunction> 

<cffunction name="sendInvite" access="remote" returnformat="plain" output="true">
	<cfargument name="emailAddr">
	<cfargument name="t">
	<cfset var i = "" />
	<cfset var goodEmails = "" />
	<cfset var badEmails = "" />
	<cfset var spamEmails = "" />
	<cfset var returnMsg = "" />
	<cfinvoke component="services.tourney" method="getTourneyBasics" t="#arguments.t#" returnVariable="local.tourneyInfo" />
	
	<!---1. make sure someone isn't trying to hack the form--->
	<cfif NOT listfind( session.user.isComm, t ) OR NOT isnumeric( arguments.t )>
		<cfreturn "You cannot invite people to a tourney that isn't yours or doesn't exist. (Quit messing with things.)" />
	<cfelseif listLen( arguments.emailAddr ) GT 20>
		<cfreturn "Please do not exceed 20 email addresses at once." />

	<!---2. make sure the tourney is accepting people--->
	<cfelseif local.tourneyInfo.status NEQ "open">
		<cfreturn "This tourney is not accepting new players, so you cannot send an invite." />

	<cfelse>
		<!---3. send good emails, log bad emails.--->
		<cfset arguments.emailAddr = replace( arguments.emailAddr, ";", ",", "all" ) />
		<cfloop list="#arguments.emailAddr#" index="i">
			<cfset i = htmlEditFormat( trim(i) ) />
			<cfif isValid( "email", i )>
			
				<!---4.only send emails to somebody once a day--->
				<cfif areWeAnnoying( arguments.t, i ) is false>
					<cfset this.insertInvite( arguments.t, session.user.userID, i ) />

					<!---5. send email--->
						<cfmail from="Sharp League <mailer@sharpleague.com>" to="#i#" subject="#session.user.firstName# #session.user.lastName# has invited you" 
						attributeCollection="#application.mailAttributes#" type="HTML"
						>#session.user.firstName# #session.user.lastName# has invited you to "#local.tourneyInfo.name#", a Sharp League tournament of incalculable joy and devious excitement.<br /><br />
						 Sharp League is a fantasy wagering game where players start with $2,000 fake dollars, which they use to "bet" on games.
						 The site keeps track of all the bets and the person with the most money at the end wins.<br /><br />
						 To sign up: http://sharpleague.com/join/#local.tourneyInfo.codeword#<br />
						 For more info on Sharp League: http://sharpleague.com<br /><br />
						 You should join. For real. It's fun. Let us know if you have any questions.<br />
						 -Sharp League</cfmail>
					<cfset local.goodEmails = listAppend( local.goodEmails, i ) />
				<cfelse>
					<cfset local.spamEmails = listAppend( local.spamEmails, i ) />
				</cfif>
			<cfelse>
				<cfset local.badEmails = listAppend( local.badEmails, i ) />
			</cfif>
		</cfloop>		

		<!---6. format return message--->
		<cfif listLen( local.goodEmails )>
			<cfset local.returnMsg = "#listLen( local.goodEmails )# email(s) sent. " />
		</cfif>
		<cfif listLen( local.badEmails )>
			<cfset local.returnMsg = local.returnMsg & "The following email(s) were improperly formatted: #replace( htmlEditFormat( local.badEmails ), ",", ", ", "all" )#. " />
		</cfif>
		<cfif listLen( local.spamEmails )>
			<cfset local.returnMsg = local.returnMsg & "We didn't send to #replace( htmlEditFormat( local.spamEmails ), ",", ", ", "all" )# because we already sent a email within the last 24 hours. " />
		</cfif>				
		
		<cfsavecontent variable="local.returnHTML">
			<div class="alert alert-info">
				<button class="close" data-dismiss="alert">x</button>
				#trim( local.returnMsg )#
			</div>			
		</cfsavecontent>
		<cfreturn local.returnHTML />
	</cfif>
</cffunction>

<cffunction name="showInvites" access="remote" returnformat="plain" output="true">
	<cfargument name="t">
	<cfset var getInvites = "">
	<cfquery name="getInvites">
		SELECT *
		FROM invitations
		WHERE tourneyID = <cfqueryparam value="#arguments.t#" cfsqltype="integer">
		ORDER BY timeSent DESC
	</cfquery>
	<cfif getInvites.recordcount>
		<cfsavecontent variable="local.returnHTML">
			<table class="table table-striped table-condensed">
				<tr>
					<th>Recepient</th>
					<th>Sent On</th>
				</tr>
				<cfloop query="getInvites">
					<cfset localTime = convertTime( getInvites.timeSent, session.user.timezone )>
					<tr>
						<td>#getInvites.toEmail#</td>
						<td>#dateformat( localTime, "mmm dd, yyyy")# &ndash; #timeFormat( localTime, "short")#</td>
					</tr>
				</cfloop>
			</table>
		</cfsavecontent>
		<cfreturn local.returnHTML>
	</cfif>
</cffunction>

</cfcomponent>