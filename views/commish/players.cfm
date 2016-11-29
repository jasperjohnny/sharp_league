<cfoutput>

<!---BUYIN & REBUYIN--->

<div class="row">
	<div class="span3">
		<div class="well" style="padding: 8px 0; background-color: white;">
			<ul class="nav nav-list">
 				<li class="nav-header">Commissioner Tools</li>
				<li class="active"><a href="/commish/settings/#rc.t#">Players</a></li>
				<li><a href="/commish/invites/#rc.t#">Invitations</a></li>
				<li><a href="/commish/settings/#rc.t#">Settings</a></li>
			</ul>
		</div>
	</div>
	<div class="span9">
		<h4 style="margin-top: 12px;">Mark Players as Paid</h4>
		<ul>
		<cfloop query="rc.players">
			<li>#rc.players.firstname# #rc.players.lastname# (#dollarFormat( rc.players.bankroll )#) =>
				<cfif rc.players.haspaid is false> 
					<a href="/commish/markPaid/#rc.t#/#rc.players.userID#">Mark as Paid</a>
				<cfelse>
					Paid.
				</cfif>
				<cfif rc.players.rebuy is false AND rc.players.haspaid is true AND rc.players.bankroll LT 100>
					<a href="/commish/rebuy/#rc.t#/#rc.players.userID#">Re-buy</a>
				<cfelseif rc.players.rebuy is true>
					Re-bought.
				</cfif>
			</li>
		</cfloop>
		</ul>

		<br />
		<h4>Sign Up Link</h4>
		<p>People can sign up for your tournament by going here:<br />
		<a style="font-size: 12px;" href="/join/#rc.tourneyBasics.codeword#">http://sharpleague.com/join/#rc.tourneyBasics.codeword#</a></p>


		
<!--- 
		<!---EMAILS--->		
		<br />
		<h4>Email List</h4>
		<p><em>
		<cfloop query="rc.players">
			#rc.players.email#<cfif rc.players.recordcount NEQ rc.players.currentrow>, </cfif>
		</cfloop>
		</em></p>		
 --->
	</div>
</div>

<!--- <cfdump var="#rc#"> --->

</cfoutput>