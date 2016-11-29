<cfoutput>
<cfset rc.pageTitle = "Join a Tournament">

<h2>Join Tournament</h2>

<cfif NOT rc.tourneyInfo.recordCount>
	<p>We cannot determine the tournament you would like to join. Please contact the commissioner. Thanks.</p>
<cfelseif rc.tourneyInfo.status NEQ "open">
	<p>"#rc.tourneyInfo.name#" is not currently accepting any new players. Sorry about that.</p>

<cfelse>
	<br/>
	<blockquote>
		<p><strong>#rc.tourneyInfo.name#</strong><br />
		Commissioner: #rc.tourneyInfo.firstName# #rc.tourneyInfo.lastName#</p>
	</blockquote>
	<!---user is logged in and already joined--->
	<cfif session.user.userID AND listContains( session.user.enteredIn, rc.tourneyInfo.tourneyID)>
		<p>You are already entered in this tournament. <a href="/tourney/lobby/#rc.tourneyInfo.tourneyID#">Go to Lobby</a></p>

	<!---user is logged but NOT joined--->
	<cfelseif session.user.userID>
		<form action="/join_form/#rc.tourneyInfo.codeword#" method="post">
			<p>You are invited to join this tournament.</p>
			<input class="btn btn-primary" type="submit" name="submit" value="Join Tourney">
		</form>
	
	<!---user is not logged in--->
	<cfelse>
		<p style="margin-top: 30px;">You have been invited to play in this tournament. Please sign in or create an account to join.</p>
		<input type="radio" name="dothis" value="register" <cfif NOT isDefined("rc.returnMsg")>checked="checked"</cfif> id="showRegister"> I am a new here.<br />
		<input type="radio" name="dothis" value="login" <cfif isDefined("rc.returnMsg")>checked="checked"</cfif> id="showLogin"> I have an account already.
		<div style="margin-top: 20px; <cfif isDefined("rc.returnMsg")> display: none;</cfif>" id="newUser">
			<form action="/front/register_join_form" method="post" class="form-horizontal">
			<cfif structKeyExists( rc, "returnMsg2" )>
				<div class="alert alert-error left">
					<button class="close" data-dismiss="alert">x</button>
					#rc.returnMsg2#
				</div>
			</cfif>
			<div class="control-group">
				<label class="control-label" for="firstName">first name:</label>
				<div class="controls">
					<input type="text" id="firstName" name="firstName">
				</div>
			</div>
			<div class="control-group">
				<label class="control-label" for="lastName">last name:</label>
				<div class="controls">
					<input type="text" id="lastName" name="lastName">
				</div>
			</div>
			<div class="control-group">
				<label class="control-label" for="email">email:</label>
				<div class="controls">
					<input type="text" id="email" name="email">
				</div>
			</div>
			<div class="control-group">
				<label class="control-label" for="password">password:</label>
				<div class="controls">
					<input type="password" id="password" name="password">
				</div>
			</div>				
			<div class="control-group">
				<div class="controls">
					<input type="hidden" name="codeword" value="#rc.codeword#">
					<input class="btn btn-primary" type="submit" value="Register & Join Tourney">
				</div>
			</div>
			</form>
		</div>		
		<div style="margin-top: 20px; <cfif NOT isDefined("rc.returnMsg")>display: none;</cfif>" id="existingUser">
			<cfif structKeyExists( rc, "returnMsg" )>
				<div class="alert alert-error left">
					<button class="close" data-dismiss="alert">x</button>
					#rc.returnMsg#
				</div>
			</cfif>
			<form action="/front/login_join_form" method="post" class="form-horizontal">
			<div class="control-group">
				<label class="control-label" for="email">email:</label>
				<div class="controls">
					<input type="text" id="email" name="email">
				</div>
			</div>
			<div class="control-group">
				<label class="control-label" for="password">password:</label>
				<div class="controls">
					<input type="password" id="password" name="password">
				</div>
			</div>				
			<div class="control-group">
				<div class="controls">
					<input type="hidden" name="codeword" value="#rc.codeword#">
					<input class="btn btn-primary" type="submit" value="Login & Join Tourney">
				</div>
			</div>
			</form>
		</div>
	</cfif>
</cfif>

<script type="text/javascript">
	$("##showRegister").click(function() {
		$("##newUser").show();
		$("##existingUser").hide();
	});
	$("##showLogin").click(function() {
		$("##newUser").hide();
		$("##existingUser").show();
	});
</script>

<br />
<!--- <cfdump var="#rc#"> --->

</cfoutput>