<cfcomponent extends="common" hint="password change functions, used by both 'front' and 'my' sections">

<cffunction name="getUserFromEmail" hint="used for password reset requests">
	<cfargument name="email">
	<cfset var checkEmail = "">
	<cfquery name="checkEmail">
		SELECT userID, firstname, lastname
		FROM users
		WHERE email = <cfqueryparam value="#arguments.email#">
		LIMIT 1
	</cfquery>
	<cfreturn checkEmail>
</cffunction>

<cffunction name="createResetID" hint="inserts a record with a resetID used for password reset email">
	<cfargument name="userID">
	<cfset var local.resetID = createUUID()>
	<cfset var insertID = "">
	<cftry>
		<cfquery name="insertID">
			INSERT INTO pwdReset ( resetID, userID, createdOn )
			VALUES ( '#local.resetID#', 
					 <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">,
					 #dateConvert( "local2Utc", now() )# )
		</cfquery>
		<cfreturn local.resetID>
		<cfcatch>
			<cfset logDbError( cfcatch, "front.createResetID" )>
			<cfreturn false>
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="emailResetID" hint="sends an email">
	<cfargument name="resetID" required="true">
	<cfargument name="email" required="true">
	<cfargument name="firstname" required="true">
	<cfset var resetLink = "http://www.sharpleague.com/front/reset_pass/#arguments.resetID#">								
	<cftry>
		<cfmail from="mailer@sharpleague.com" to="#arguments.email#" subject="Reset Your Password" 
			attributeCollection="#application.mailAttributes#" type="HTML"
			>Hi #arguments.firstname#,<br /><br />
			We received a request to reset you password. If you would like to do so, please use this link:<br />
			<a href="#resetLink#">#resetLink#</a><br /><br />
			This link we be active for 24 hours.<br /><br />
			If you do not wish to change your password, you needn't do anything. The old one will still work.<br /><br />
			Thanks,<br />Sharp League Team</cfmail>
		<cfreturn true>
		<cfcatch>
			<cfreturn false>
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="getUserFromResetID" hint="second part of password reset requests">
	<cfargument name="resetID" required="true">
	<cfset var userData = "" />
	<cfquery name="userData">
		SELECT *
		FROM pwdReset
		JOIN users
		ON pwdReset.userID = users.userID
		WHERE resetID = <cfqueryparam value="#arguments.resetID#">
		LIMIT 1
	</cfquery>
	<cfreturn userData>
</cffunction>

<cffunction name="updatePwdFromResetID" hint="final step">
	<cfargument name="resetID" required="true">
	<cfargument name="password" required="true">
	<cfset var updatePwd = "">
	<cftry>
		<cfquery name="updatePwd">
			UPDATE users
			SET password = <cfqueryparam value="#hash( arguments.password, "SHA-256" )#">
			WHERE userID = (
				SELECT userID
				FROM pwdReset
				WHERE resetID = <cfqueryparam value="#arguments.resetID#">
				)
			LIMIT 1
		</cfquery>
		<cfreturn true>
		<cfcatch>
			<cfset logDbError( cfcatch, "front.updatePwdFromResetID" )>
			<cfreturn false>
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="updatePwdFromUserID" hint="final step">
	<cfargument name="password" required="true">
	<cfset var updatePwd = "">
	<cftry>
		<cfquery name="updatePwd">
			UPDATE users
			SET password = <cfqueryparam value="#hash( arguments.password, "SHA-256" )#">
			WHERE userID = #session.user.userID#
			LIMIT 1
		</cfquery>
		<cfreturn true>
		<cfcatch>
			<cfset logDbError( cfcatch, "front.updatePwdFromUserID" )>
			<cfreturn false>
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="deleteResetLink" hint="after password update">
	<cfargument name="resetID" required="true">
	<cfset var disableLink = "">
	<cftry>
		<cfquery name="disableLink">
			DELETE FROM pwdReset
			WHERE resetID = <cfqueryparam value="#arguments.resetID#">
			LIMIT 1
		</cfquery>
		<cfreturn true>
		<cfcatch>
			<cfset logDbError( cfcatch, "front.deleteResetLink" )>			
			<cfreturn false>
		</cfcatch>
	</cftry>
</cffunction>

</cfcomponent>