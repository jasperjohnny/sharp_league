<cfcomponent extends="common" hint="logged in users, not tourney-specific views">

<cffunction name="init" hint="set variables for framework API and needed services">
	<cfargument name="fw">
	<cfset variables.fw = arguments.fw>
	<cfset variables.myService = new services.my()>
	<cfset variables.pwdService = new services.password()>
</cffunction>	

<cffunction name="before" hint="always occurs before the section.item() method">
	<cfargument name="rc">
	<cfif NOT session.user.userID>
		<cfset variables.fw.redirect( "front" )>
	<cfelse>
		<cfset rc.profileInfo = variables.myService.getProfileInfo( session.user.userID )>
		<cfset rc.john = "john">
	</cfif>	
</cffunction>

<cffunction name="default" hint="the default view for this section">
	<cfset variables.fw.redirect( "my/dashboard" )>
	
</cffunction>

<cffunction name="dashboard" hint="overview of what's going on; logged in homepage">
	<cfargument name="rc">
	<cfset rc.tourneyHistory = variables.myService.getTourneyHistory( session.user.userID )>
	<!---there is AJAXed content in /services/ajax.cfc, renderDashboard()--->
</cffunction>

<cffunction name="profile" hint="profile display and edit">
	<cfargument name="rc">
	<cfset rc.tzArray = variables.myService.getTimezones() >
</cffunction>

<cffunction name="profile_basics_form" hint="name, email, timezone">
	<cfargument name="rc">
	<cfif rc.firstname EQ "" OR rc.lastname EQ "" OR rc.email EQ "" or rc.timezone EQ "">
		<cfset rc.returnMsg = "All of these fields are required">
		<cfset variables.fw.redirect( "my/profile", "returnMsg" )>
	<cfelseif rc.email NEQ rc.profileInfo.email>
		<cfset local.checkEmail = variables.pwdService.getUserFromEmail ( rc.email )>
		<cfif local.checkEmail.recordcount GT 0>
			<cfset rc.returnMsg = "That email address is already registered to another user.">
			<cfset variables.fw.redirect( "my/profile", "returnMsg" )>
		</cfif>
	</cfif>
	<!---passed validation checkes, so we can proceed--->
	<cfset local.response = variables.myService.updateBasics( rc )>
	<cfif local.response is true>
		<cfset rc.returnMsg = "Change successful.">
		<cfset variables.fw.redirect( "my/profile", "returnMsg" )>					
	<cfelse>
		<cfset rc.returnMsg = "There was an error with the update. Please try again later.">
		<cfset variables.fw.redirect( "my/profile", "returnMsg" )>
	</cfif>
</cffunction>

<cffunction name="profile_pwd_form" hint="change password">
	<cfargument name="rc">
	<cfif rc.password1 NEQ rc.password2>
		<cfset rc.returnMSG = "The passwords do not match. Please try again.">
		<cfset variables.fw.redirect( "my/profile", "returnMsg" )>
	<cfelseif variables.pwdService.isPasswordOK( rc.password1 ) is false>
		<cfset rc.returnMSG = "The password must be eight characters and include one number." >
		<cfset variables.fw.redirect( "my/profile", "returnMsg" )>
	<cfelse>
		<cfset rc.pwdChange = variables.pwdService.updatePwdFromUserID( rc.password1 )>
		<cfif rc.pwdChange is true>
			<cfset rc.returnMsg = "Your password has been changed.">
			<cfset variables.fw.redirect( "my/profile", "returnMsg" )>
		<cfelse>
			<cfset rc.returnMsg = "Something went wrong with the password update. Please contact support if the problem persists.">
			<cfset variables.fw.redirect( "my/profile", "returnMsg" )>
		</cfif>
	</cfif>
</cffunction>

<cffunction name="profile_img_form" hint="upload new photo">
	<cfargument name="rc">
	<cfset var upResult = "">
	<cfif structKeyExists( rc, "newImage" ) AND rc.newImage NEQ ""> 
		<cffile action="upload" filefield="newImage" destination="s3:///#application.s3bucket#/profiles/" nameConflict="makeUnique" result="upResult">
		<cfif ( upResult.FileSize GT (200 * 1024) )>
			<cffile action="delete" file="s3:///#application.s3bucket#/profiles/#upResult.ServerFile#" />
			<cfset rc.returnMsg = "The file size cannot exceed 200k.">
			<cfset variables.fw.redirect( "my/profile", "returnMsg" )>			
		<cfelseif listFindNoCase( "jpeg,jpg,gif,png", upResult.serverFileExt ) EQ 0>
			<cffile action="delete" file="s3:///#application.s3bucket#/profiles/#upResult.ServerFile#" />
			<cfset rc.returnMsg = "Accepted filetypes are: jpg, jpeg, gif, & png.">
			<cfset variables.fw.redirect( "my/profile", "returnMsg" )>
		<cfelse>
			<cfset local.response = variables.myService.updateImage ( upResult.ServerFile )>
			<cfif local.response is true>
				<cfthread action="sleep" duration="500" /><!---give AWS half sec to process--->
				<cfset rc.returnMsg = "Image update successful.">
				<cfset variables.fw.redirect( "my/profile", "returnMsg" )>
			<cfelse>
				<cfset rc.returnMsg = "There was a problem with the file upload. Please try again later.">
				<cfset variables.fw.redirect( "my/profile", "returnMsg" )>
			</cfif>
		</cfif>
	<cfelse>
		<cfset rc.returnMsg = "No file selected.">
		<cfset variables.fw.redirect( "my/profile", "returnMsg" )>
	</cfif>        
</cffunction>

<cffunction name="make_tourney_form" hint="redone. makes a new tournament">
	<cfargument name="rc">
	<cfparam name="rc.suicide" default="0">
	<cfset local.suicideType = ( rc.suicide ) ? "double" : "none" />
	<cfif rc.tourneyName EQ "">
		<cfset rc.somethingWrong = "Please provide a name.">			
	<cfelseif len( rc.tourneyName ) GT 40>
		<cfset rc.somethingWrong = "Not so long please.">			
	<cfelse>
		<cfset local.newTourneyID = variables.myService.makeTourney( rc.tourneyName, session.user.userID, "NFL", 2013, "private", local.suicideType )>
		<cfif local.newTourneyID>
			<cfset variables.myService.addUserToTourney( session.user.userID, local.newTourneyID, 1 ) />
			<cfset session.user.enteredIn = listAppend( session.user.enteredIn, local.newTourneyID ) /> 
			<cfset session.user.isComm = listAppend( session.user.isComm, local.newTourneyID ) /> 
			<cfset rc.newCommish = true />
			<cfset variables.fw.redirect( "tourney/lobby/#newTourneyID#", "newCommish" ) />
		<cfelse>
			<cfset rc.somethingWrong = "Sorry, but there was an error creating the tournament." />
		</cfif>
	</cfif>
	<cfset variables.fw.redirect( "my/dashboard", "somethingWrong" )>
</cffunction>

<cffunction name="join_public_form" hint="redone">
	<cfargument name="rc">
	<cfset local.publicTourneyID = variables.myService.getOpenPublic( "NFL", 2013 ) />
	<cfif listFind( session.user.enteredIn, local.publicTourneyID )>
		<cfset rc.somethingWrong2 = "You are already entered in the public tourney that is currently forming. Please try again later." />
	<cfelseif local.publicTourneyID>
		<cfset variables.myService.addUserToTourney( session.user.userID, local.publicTourneyID, 0 ) />
		<cfset session.user.enteredIn = listAppend( session.user.enteredIn, local.publicTourneyID ) />
		<cfinvoke component="services.commish" method="addBankroll" t="#local.publicTourneyID#" player="#session.user.userID#" />
		<cfset variables.fw.redirect( "tourney/lobby/#publicTourneyID#" ) />
	<cfelse>
		<cfset rc.somethingWrong2 = "Sorry, but there was an error creating the tournament." />
	</cfif>
 	<cfset variables.fw.redirect( "my/dashboard", "somethingWrong2" ) />
</cffunction>

</cfcomponent>
