<cfcomponent extends="common">

<cffunction name="getUserFromLogin" hint="looks for user and then processes">
	<cfargument name="email" required="true">
	<cfargument name="password" required="true">
	<cfset var userData = "">
	<cfquery name="userData">
		SELECT users.*, group_concat( tourneyID ) as enteredIn, group_concat( if( isComm is true, tourneyID, null ) ) as isComm
		FROM users
		LEFT JOIN enteredIn
		ON users.userID = enteredIn.userID
		WHERE email = <cfqueryparam value="#arguments.email#"> 
		AND password = <cfqueryparam value="#hash( arguments.password, "SHA-256" )#">
		GROUP BY users.userID
		LIMIT 1
	</cfquery>	
	<cfreturn userData>	
</cffunction>

<cffunction name="getUserFromID" hint="id stored in rememberMe cookie">
	<cfargument name="userID" required="true">
	<cfset var userData = "">
	<cfquery name="userData">
		SELECT users.*, group_concat( tourneyID ) as enteredIn, group_concat( if( isComm is true, tourneyID, null ) ) as isComm
		FROM users
		LEFT JOIN enteredIn
		ON users.userID = enteredIn.userID
		WHERE users.userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
		GROUP BY users.userID
		LIMIT 1
	</cfquery>
	<cfreturn userData>	
</cffunction>

<cffunction name="setRememberMe" hint="encrypt and store in cookie, no expiration.">
	<cfargument name="userID">
	<cfset var strRememberMe = "">
	<cftry>
		<cfset strRememberMe = createuuid() & ":" & arguments.userID & ":" & createuuid() />
		<cfset strRememberMe = encrypt( strRememberMe, application.AESkey, "AES", "hex" ) />
		<cfcookie name="rememberMe" value="#strRememberMe#" expires="never" />
		<cfreturn true>
		<cfcatch>
			<cfreturn false>
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="registerUser" hint="expects a struct; returns the new user ID">
	<cfargument name="userData">
	<cfset var insertUser = "">
	<cfset var getUserID = "">
	<cftry>
		<cfquery name="insertUser">
			INSERT INTO users ( email, password, firstname, lastname )
			VALUES ( <cfqueryparam value="#arguments.userData.email#">,
					 <cfqueryparam value="#hash( arguments.userData.password, "SHA-256" )#">,
					 <cfqueryparam value="#arguments.userData.firstname#">,
					 <cfqueryparam value="#arguments.userData.lastname#"> )
		</cfquery>
		<cfquery name="getUserID">
			SELECT last_insert_id() AS theID
		</cfquery>
		<cfreturn getUserID.theID>
 		<cfcatch>
			<cfset logDbError( cfcatch, "front.registerUser" )>
			<cfreturn 0>
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="getTourneyFromCode" hint="for invites">
	<cfargument name="codeword">
	<cfset var getTourney = "">
	<cfquery name="getTourney">
		SELECT *
		FROM tourneys
		JOIN users
		ON tourneys.createdBy = users.userID
		WHERE codeword = <cfqueryparam value="#arguments.codeword#">
	</cfquery>
	<cfreturn getTourney>
</cffunction>		

<cffunction name="checkRegistrationData" hint="runs through a seroes of checks">
	<cfargument name="firstName" default="">
	<cfargument name="lastName" default="">
	<cfargument name="password" default="">
	<cfargument name="email" default="">
	
	<cfif trim( arguments.firstname ) EQ "" OR trim( arguments.lastname ) EQ "" OR trim( arguments.email ) EQ "" OR trim( arguments.password ) EQ "">
		<cfreturn "All fields are required.">
	<cfelseif isPasswordOK( arguments.password ) is false>
		<cfreturn "Password must contain at least eight characters, including one number.">
	<cfelseif NOT isValid( "email", arguments.email )>
		<cfreturn "Email address is not properly formatted.">
	<cfelse>
		<cfinvoke component="services.password" method="getUserFromEmail" email="#arguments.email#" returnVariable="local.checkEmail">
		<cfif local.checkEmail.recordcount>
			<cfreturn "This email address is already registered.">
		<cfelse>
			<!---passed all the checks--->
			<cfreturn "OK">
		</cfif>
	</cfif>
</cffunction>
	
</cfcomponent>