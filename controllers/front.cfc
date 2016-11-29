<cfcomponent extends="common" hint="not logged in users">
	
<cffunction name="init" hint="set variables for framework API and needed services">
	<cfargument name="fw">
	<cfset variables.fw = arguments.fw>
	<cfset variables.frontService = new services.front()>
	<cfset variables.pwdService = new services.password()>
	<cfset variables.myService = new services.my()>
</cffunction>	

<cffunction name="default" hint="the first page of the site; not logged in homepage">
	<cfif session.user.userID><!---logged in--->
		<cfset variables.fw.redirect( "my/dashboard" )>	
	</cfif>
</cffunction>

<cffunction name="join" hint="someone has been invited and knows the link">
	<cfargument name="rc">
	<cfif NOT isDefined( "rc.codeword" )>
		<cfset variables.fw.redirect( "front" )>
	<cfelse>
		<cfset rc.tourneyInfo = variables.frontService.getTourneyFromCode( rc.codeword )>
	</cfif>
</cffunction>

<cffunction name="reset_pass" hint="coming from email link">
	<cfargument name="rc">
	<cfif structKeyExists( rc, "resetID" )>
		<cfset rc.resetData = variables.pwdService.getUserFromResetID( rc.resetID )>
		<cfif NOT rc.resetData.recordcount OR dateConvert( "local2Utc", now() ) GTE dateAdd( "d", 1, rc.resetData.createdOn )>
			<cfset rc.resendError = "The reset link is not understood or is no longer valid. Please request another.">
			<cfset variables.fw.redirect( "front/resend_pass", "resendError" )>
		</cfif>
	<cfelse>
		<cfset variables.fw.redirect( "front/resend_pass" )>
	</cfif>	
</cffunction>

<cffunction name="register_form" hint="new peope">
	<cfargument name="rc">
	<cfif isDefined( "rc.firstname" ) AND isDefined( "rc.lastname" ) AND isDefined( "rc.email" ) AND isDefined( "rc.password" )>
		<cfset local.checkData = variables.frontService.checkRegistrationData( rc.firstname, rc.lastname, rc.password, rc.email ) />
		<cfif local.checkData NEQ "OK">
			<cfset rc.returnMsg2 = local.checkData />
			<cfset variables.fw.redirect( "front/default", "returnMsg2" ) />
		<cfelse>
			<cfset local.newUserID = variables.frontService.registerUser( rc )>
			<cfif local.newUserID EQ 0>
				<cfset rc.returnMsg2 = "Something went wrong with the registration process. Please contact support.">
				<cfset variables.fw.redirect( "front/default", "returnMsg2" )>					
			<cfelse>
				<cfset session.user = variables.frontService.getUserFromID ( local.newUserID )>
					<cfset rc.newUser = true>
				<cfset variables.fw.redirect( "my/dashboard", "newUser" )>
			</cfif>
		</cfif>
	<cfelse>
		<cfset rc.returnMsg2 = "All fields are required." />
		<cfset variables.fw.redirect( "front/default", "returnMsg2" ) />
	</cfif>
</cffunction>

<cffunction name="register_join_form" hint="from the join page, register needed">
	<cfargument name="rc">
	<cfif NOT isDefined( "rc.codeword" )>
		<cfset variables.fw.redirect( "front" )>
	<cfelse>
		<cfset local.checkData = variables.frontService.checkRegistrationData( rc.firstname, rc.lastname, rc.password, rc.email ) />
		<cfif local.checkData NEQ "OK">
			<cfset rc.returnMsg2 = local.checkData />
			<cfset variables.fw.redirect( "join/#rc.codeword#", "returnMsg2" ) />
		<cfelse>
			<cfset local.newUserID = variables.frontService.registerUser( rc ) />
			<cfif local.newUserID EQ 0>
				<cfset rc.returnMsg2 = "Something went wrong with the registration process. Please contact support." />
				<cfset variables.fw.redirect( "join/#rc.codeword#", "returnMsg2" ) />
			<cfelse>
				<cfset session.user = variables.frontService.getUserFromID ( local.newUserID ) />
 				<cfset rc.newUser = true>
				<!---now send to join tourney form--->
				<cfset join_form( rc ) />
			</cfif>
		</cfif>
	</cfif>
</cffunction>
	
<cffunction name="login_form" hint="run the log in service and set cookie if requested">
	<cfargument name="rc">
	<cfparam name="rc.rememberMe" default="0">
	<cfif NOT structKeyExists( rc, "email" ) OR NOT structKeyExists( rc, "password" ) OR trim( rc.email ) EQ "" OR trim( rc.password ) EQ "">
		<cfset rc.returnMsg = "You need an email and password.">
		<cfset variables.fw.redirect( "front", "returnMsg" )>
	<cfelse>
		<cfset local.userData = variables.frontService.getUserFromLogin( rc.email, rc.password )>
		<cfif local.userData.recordcount>
			<cfset session.user = local.userData />
			<cfif rc.rememberMe>
				<cfset variables.frontService.setRememberMe( local.userData.userID ) />
			</cfif>
			<cfset variables.fw.redirect( "my/dashboard" )>
		<cfelse>
			<cfset rc.returnMsg = "Email and password combination did not match any record.">
			<cfset variables.fw.redirect( "front/default", "returnMsg" )>
		</cfif>
	</cfif>
</cffunction>

<cffunction name="login_join_form" hint="from the join page, login needed">
	<cfargument name="rc">
	<cfparam name="rc.rememberMe" default="0">
	<cfif NOT isDefined( "rc.codeword" )>
		<cfset variables.fw.redirect( "front" )>
	<cfelseif trim( rc.email ) EQ "" OR trim( rc.password ) EQ "">
		<cfset rc.returnMsg = "You need an email and password.">
		<cfset variables.fw.redirect( "join/#rc.codeword#", "returnMsg" )>
	<cfelse>
		<cfset local.userData = variables.frontService.getUserFromLogin( rc.email, rc.password )>
		<cfif local.userData.recordcount>
			<cfset session.user = local.userData />
			<cfif rc.rememberMe>
				<cfset variables.frontService.setRememberMe( local.userData.userID ) />
			</cfif>
			<!---now send to join tourney form--->
			<cfset join_form( rc ) />
		<cfelse>
			<cfset rc.returnMsg = "Email and password combination did not match any record.">
			<cfset variables.fw.redirect( "join/#rc.codeword#", "returnMsg" )>
		</cfif>
	</cfif>
</cffunction>

<cffunction name="join_form" hint="join a tourney">
	<cfargument name="rc">
 	<cfif NOT isDefined( "rc.codeword" ) OR NOT session.user.userID>
		<cfset variables.fw.redirect( "front" )>
	<cfelse>	
		<cfset rc.tourneyInfo = variables.frontService.getTourneyFromCode( rc.codeword )>
		<!---make sure we found a tourney that matches--->
		<cfif rc.tourneyInfo.recordcount>
			<!---make sure we're not entering twice--->
			<cfif listContains( session.user.enteredIn, rc.tourneyInfo.tourneyID )>
				<cfset variables.fw.redirect( "tourney/lobby/#rc.tourneyInfo.tourneyID#" )>		
			<cfelse>
				<cfset variables.myService.addUserToTourney( session.user.userID, rc.tourneyInfo.tourneyID )>
				<cfset session.user.enteredIn = listAppend( session.user.enteredIn, rc.tourneyInfo.tourneyID )> 
				<cfset variables.fw.redirect( "tourney/lobby/#rc.tourneyInfo.tourneyID#" )>
			</cfif>
		<cfelse>
			<cfset variables.fw.redirect( "front" )>
		</cfif>
	</cfif>
</cffunction>

<cffunction name="resend_pass_form" hint="decision point in flow">
	<cfargument name="rc">
	<cfif structKeyExists( rc, "email" )>
		<cfset local.userInfo = variables.pwdService.getUserFromEmail( rc.email )>
		<cfif local.userInfo.recordcount>
			<cfset local.resetID = variables.pwdService.createResetID( local.userInfo.userID )>	
			<cfif local.resetID NEQ 0>
				<cfset local.emailSend = variables.pwdService.emailResetID( local.resetID, rc.email, local.userInfo.firstname )>
				<cfif local.emailSend is true>
					<cfset logThis( "Password reset request sent to #local.userInfo.firstname# #local.userInfo.lastname# at #convertTime()#", "password" )>
					<cfset variables.fw.redirect( "front/password_sent" )>
				</cfif>
			</cfif>
			<cfif local.resetID is false OR local.emailSend is false>
				<cfset rc.returnMsg = "There was an error sending your reset email. Please try again later.">
				<cfset variables.fw.redirect( "front/resend_pass", "returnMsg" )>
			</cfif>
		<cfelse>
			<cfset rc.returnMsg = "We could not find any record connected to this email address.">
			<cfset variables.fw.redirect( "front/resend_pass", "returnMsg" )>			
		</cfif>
	<cfelse>
		<cfset variables.fw.redirect( "front/resend_pass" )>
	</cfif>
</cffunction>

<cffunction name="reset_pass_form" hint="decision point">
	<cfargument name="rc">
	<cfif rc.password1 NEQ rc.password2>
		<cfset rc.returnMsg = "The passwords do not match. Please try again.">
		<cfset variables.fw.redirect( "front/reset_pass/#rc.resetID#", "returnMsg" )>

	<cfelseif variables.pwdService.isPasswordOK( rc.password1 ) is false>
		<cfset rc.returnMsg = "The password must be eight characters and include one number." >
		<cfset variables.fw.redirect( "front/reset_pass/#rc.resetID#", "returnMsg" )>

	<cfelse>
		<cfset rc.pwdChange = variables.pwdService.updatePwdFromResetID( rc.resetID, rc.password1 )>
		<cfif rc.pwdChange is true>
			<cfset local.userInfo = variables.pwdService.getUserFromResetID ( rc.resetID )> 
			<cfset logThis( "Password was reset by #local.userInfo.firstname# #local.userInfo.lastname# on #convertTime()#", "password" )>
			<cfset variables.pwdService.deleteResetLink( rc.resetID )>
			<cfset rc.returnMsg = "Success! Your password has been changed. Please log in with your new credentials.">
			<cfset variables.fw.redirect( "front/default", "returnMsg" )>
		<cfelse>
			<cfset rc.returnMsg = "Something went wrong with the password update. Please contact support if the problem persists.">
			<cfset variables.fw.redirect( "front/reset_pass/#rc.resetID#", "returnMsg" )>
		</cfif>
	</cfif>
</cffunction>

<cffunction name="logout" hint="adios">
	<cfset session.user.userID = 0 />
 	<cfcookie name="rememberMe" value="" expires="now" /> 
	<cfset variables.fw.redirect( "front" )>
</cffunction>

<cffunction name="error" output="true" hint="logs the error">
	<cfset var debugInfo = "">
	<cftry>
		<cfsavecontent variable="debugInfo">
#now()#: #request.exception.cause.detail#
#request.exception.cause.message#
---------
Line #request.exception.TagContext[1].line#
---------
#request.exception.TagContext[1].codePrintPlain#
---------
#request.exception.stacktrace#						
		</cfsavecontent>
			
		<cfset logThis( debugInfo, "error" )>
		<cfcatch />
	</cftry>
</cffunction>

</cfcomponent>