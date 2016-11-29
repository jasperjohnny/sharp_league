<cfoutput>

<div class="btn-group pull-right" style="margin: 15px;">
	<a class="btn btn-small" href="/my/dashboard">Home</a>
	<button class="btn btn-small dropdown-toggle" data-toggle="dropdown">
		<span class="caret"></span>
	</button>
	<ul class="dropdown-menu">
		<li><a href="/my/dashboard"><i class="icon-home"></i> Home</a></li>
		<li><a href="/my/profile"><i class="icon-user"></i> Edit Profile</a></li>
		<li><a href="/front/logout">Logout</a></li>  
	</ul>
</div>

<!--- <div class="btn-group pull-right" style="margin:15px;">
	<a class="btn btn-primary dropdown-toggle btn-small" data-toggle="dropdown" href="##">
    	Account <span class="caret"></span>
	</a>
	<ul class="dropdown-menu">
		<li><a href="/my/dashboard"><i class="icon-home"></i> Dashboard</a></li>
		<li><a href="/my/profile"><i class="icon-user"></i> Edit Profile</a></li>
		<cfif listFind( session.user.isComm, rc.t )>
			<li><a href="/commish/options/#rc.t#"><i class="icon-wrench"></i> Commish Tools</a></li>
		</cfif>
		<li><a href="/front/logout">Logout</a></li>  
	</ul>
</div> --->

<div>
	<h1 style="padding: 15px 0" class="noChange"><a href="/tourney/lobby/#rc.t#">#rc.tourneyBasics.name#</a></h2>
</div>

<cfif listFind( session.user.isComm, rc.t ) AND ( rc.tourneyBasics.suicideType NEQ "none" OR ( rc.tourneyBasics.league EQ "NFLp" AND rc.tourneyBasics.currentRound EQ 4 ) )>
	<cfset variables.hideLobbyTab = true>
<cfelse>
	<cfset variables.hideLobbyTab = false>
</cfif>

<ul class="nav nav-tabs">
	<li class="
		<cfif cgi.path_info EQ "/tourney/lobby/#rc.t#">active</cfif>
		<cfif variables.hideLobbyTab is true>hidden-phone</cfif>
		"><a href="/tourney/lobby/#rc.t#">Lobby</a></li>
	<li <cfif cgi.path_info EQ "/tourney/ledger/#rc.t#">class="active"</cfif>><a href="/tourney/ledger/#rc.t#">My Bets</a></li>
	<li <cfif cgi.path_info EQ "/tourney/book/#rc.t#">class="active"</cfif>><a href="/tourney/book/#rc.t#">Book</a></li>
	<cfif rc.tourneyBasics.suicideType NEQ "none">
		<li <cfif cgi.path_info EQ "/tourney/suicide/#rc.t#">class="active"</cfif>><a href="/tourney/suicide/#rc.t#">Suicide</a></li>
	</cfif>
 	<cfif rc.tourneyBasics.league EQ "NFLp" AND rc.tourneyBasics.currentRound EQ 4>
		<li <cfif cgi.path_info EQ "/tourney/super/#rc.t#">class="active"</cfif>><a href="/tourney/super/#rc.t#">Super</a></li>
	</cfif>
 	<cfif listFind( session.user.isComm, rc.t )>
		<li <cfif listgetAt( cgi.path_info, 1, "/") EQ "commish">class="active"</cfif>><a href="/commish/players/#rc.t#">Tools</a></li>
	</cfif>
</ul>

#body#

</cfoutput>