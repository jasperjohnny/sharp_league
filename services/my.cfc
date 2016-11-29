<cfcomponent extends="common">

<cffunction name="getTourneyHistory" hint="gets basic info for eneteredIn tourneys">
	<cfargument name="userID" required="true">
	<cfset var getHistory = "">
	<cfquery name="getHistory">
		SELECT * 
		FROM enteredIn		
		JOIN tourneys 
		ON enteredIn.tourneyID = tourneys.tourneyID
<!--- 		LEFT JOIN v_TourneyTotals
		ON enteredIn.tourneyID = v_TourneyTotals.tourneyID AND enteredIn.userID = v_TourneyTotals.userID		 --->
		WHERE enteredIn.userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
		AND status = 'closed'
		ORDER BY enteredIn.tourneyID DESC
	</cfquery>	
	<cfreturn getHistory>
</cffunction>

<cffunction name="getProfileInfo" hint="all from users on userID">
	<cfargument name="userID" required="true">
	<cfset var getProfile = "">
	<cfquery name="getProfile">
		SELECT *
		FROM users
		WHERE userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
		LIMIT 1
	</cfquery>
	<cfreturn getProfile>
</cffunction>

<cffunction name="makeTourney" hint="inserts new tourney record">
	<cfargument name="tourneyName">
	<cfargument name="createdBy">
	<cfargument name="league">
	<cfargument name="season">
	<cfargument name="tourneyType">
	<cfargument name="suicideType">
	<cfset var insert = "" />
	<cfset var getnewID = "" />
	<cftry>
		<cfquery name="insert">
			INSERT INTO tourneys ( name, createdBy, league, season, codeword, tourneyType, suicideType, createdOn )
			VALUES ( <cfqueryparam value="#arguments.tourneyName#">,
					 <cfqueryparam value="#arguments.createdBy#" cfsqltype="integer">,
					 <cfqueryparam value="#arguments.league#">,
					 <cfqueryparam value="#arguments.season#">,
					 <cfqueryparam value="#listGetAt( createUUID(), 1, "-" )#-#arguments.createdBy#">,
					 <cfqueryparam value="#arguments.tourneyType#">,
					 <cfqueryparam value="#arguments.suicideType#">,
					 #DateConvert( 'local2Utc', now() )# )
		</cfquery>
		<cfquery name="getnewID">
			SELECT last_insert_id() as theID
		</cfquery>
		
		<!---also mail me--->
		<cfmail from="mailer@sharpleague.com" to="john@sharpleague.com" subject="New Tourney Added" 
			attributeCollection="#application.mailAttributes#" type="HTML"
			>New tourney "#arguments.tourneyName#" created by userID #arguments.createdBy# on #DateFormat( convertTime(), "long" )# at #TimeFormat( convertTime(), "short" )#.
		</cfmail>

		<cfreturn getnewID.theID>
		<cfcatch>
			<cfset logDbError( cfcatch, "my.makeTourney" )>			
			<cfreturn 0>
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="addUserToTourney" hint="as it sounds">
	<cfargument name="userID" required="true">
	<cfargument name="tourneyID" required="true">
	<cfargument name="isComm" required="false" default="0">
	<cfset var insert = "">
	<cftry>
		<cfquery name="insert">
			INSERT INTO enteredIn ( userID, tourneyID, isComm, enteredOn )
			VALUES ( <cfqueryparam value="#arguments.userID#" cfsqltype="integer">,
					 <cfqueryparam value="#arguments.tourneyID#" cfsqltype="integer">,
					 <cfqueryparam value="#arguments.isComm#" cfsqltype="integer">,
					 #DateConvert( 'local2Utc', now() )# )	
		</cfquery>
		
		<!---also mail me--->
		<cfmail from="mailer@sharpleague.com" to="john@sharpleague.com" subject="Player Added to Tourney" 
			attributeCollection="#application.mailAttributes#" type="HTML"
			>Player ###arguments.userID# added to Tourney ###arguments.tourneyID# on #DateFormat( convertTime(), "long" )# at #TimeFormat( convertTime(), "short" )#.
		</cfmail>
		
		<cfreturn true>
		<cfcatch>
			<cfset logDbError( cfcatch, "my.addUserToTourney" )>						
			<cfreturn false>
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="getOpenPublic" hint="looks for an open public with room; if none, creates one">
	<cfargument name="league">
	<cfargument name="season">
	<cfset var getOpens = "">
	<cfquery name="getOpens">
		SELECT tourneys.tourneyID, count( tourneys.tourneyID ) AS playerCount
		FROM tourneys		
		JOIN enteredIn
		ON tourneys.tourneyID = enteredIn.tourneyID
		WHERE tourneyType = 'public'
		AND status = 'open'
		AND league = <cfqueryparam value="#arguments.league#">
		AND season = <cfqueryparam value="#arguments.season#" cfsqltype="integer">
		GROUP BY tourneys.tourneyID
		LIMIT 1
	</cfquery>
	
	<cfif getOpens.recordCount EQ 0>
		<cfset local.suicide = ( arguments.league EQ 'NFL' ) ? "double" : "none" />
		<cfset newTourneyID = makeTourney( "Public #RandRange( 0, 100000 )#", 101, arguments.league, arguments.season, "public", local.suicide ) />	
		<cfreturn newTourneyID />
	<cfelseif getOpens.playerCount EQ 12>
		<!---if tourney is at max, set open tourney to 'ongoing' and make a new 'open' public tourney--->
		<cfinvoke component="services.commish" method="updateStatus" t="#getOpens.tourneyID#" status="ongoing" />
		<cfset newTourneyID = makeTourney( "Public #RandRange( 0, 100000 )#", 101, arguments.league, arguments.season, "public" ) />
		<cfreturn newTourneyID />		
	<cfelse>
		<cfreturn getOpens.tourneyID />
	</cfif>		
</cffunction>

<cffunction name="getTimezones" hint="probably change this in the fuure">
	<cfset local.tzArray = [
		"America/New_York;(GMT-05:00) Eastern Time (US & Canada)",
 		"America/Chicago;(GMT-06:00) Central Time (US & Canada)",
		"America/Denver;(GMT-07:00) Mountain Time (US & Canada)",
		"America/Los_Angeles;(GMT-08:00) Pacific Time (US & Canada)",
		";---",
		"Pacific/Midway;(GMT-11:00) Midway Island, Samoa",
		"America/Adak;(GMT-10:00) Hawaii-Aleutian",
		"Pacific/Honolulu;(GMT-10:00) Hawaii",
		"Pacific/Marquesas;(GMT-09:30) Marquesas Islands",
		"Pacific/Gambier;(GMT-09:00) Gambier Islands",
		"America/Anchorage;(GMT-09:00) Alaska",
		"America/Tijuana;(GMT-08:00) Tijuana, Baja California",
		"Pacific/Pitcairn;(GMT-08:00) Pitcairn Islands",
		"America/Chihuahua;(GMT-07:00) Chihuahua, La Paz, Mazatlan",
		"America/Dawson_Creek;(GMT-07:00) Arizona",
		"America/Belize;(GMT-06:00) Saskatchewan, Central America",
		"America/Cancun;(GMT-06:00) Guadalajara, Mexico City, Monterrey",
		"Pacific/Easter;(GMT-06:00) Easter Island",
		"America/Havana;(GMT-05:00) Cuba",
		"America/Bogota;(GMT-05:00) Bogota, Lima, Quito, Rio Branco",
		"America/Caracas;(GMT-04:30) Caracas",
		"America/Santiago;(GMT-04:00) Santiago",
		"America/La_Paz;(GMT-04:00) La Paz",
		"Atlantic/Stanley;(GMT-04:00) Faukland Islands",
		"America/Campo_Grande;(GMT-04:00) Brazil",
		"America/Goose_Bay;(GMT-04:00) Atlantic Time (Goose Bay)",
		"America/Glace_Bay;(GMT-04:00) Atlantic Time (Canada)",
		"America/St_Johns;(GMT-03:30) Newfoundland",
		"America/Araguaina;(GMT-03:00) UTC-3",
		"America/Montevideo;(GMT-03:00) Montevideo",
		"America/Miquelon;(GMT-03:00) Miquelon, St. Pierre",
		"America/Godthab;(GMT-03:00) Greenland",
		"America/Argentina/Buenos_Aires;(GMT-03:00) Buenos Aires",
		"America/Sao_Paulo;(GMT-03:00) Brasilia",
		"America/Noronha;(GMT-02:00) Mid-Atlantic",
		"Atlantic/Cape_Verde;(GMT-01:00) Cape Verde Is.",
		"Atlantic/Azores;(GMT-01:00) Azores",
		"Europe/Dublin;(GMT) Greenwich Mean Time : Dublin",
		"Europe/Lisbon;(GMT) Greenwich Mean Time : Lisbon",
		"Europe/London;(GMT) Greenwich Mean Time : London",
		"Africa/Abidjan;(GMT) Monrovia, Reykjavik",
		"Europe/Amsterdam;(GMT+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna",
		"Europe/Belgrade;(GMT+01:00) Belgrade, Bratislava, Budapest, Ljubljana, Prague",
		"Europe/Brussels;(GMT+01:00) Brussels, Copenhagen, Madrid, Paris",
		"Africa/Algiers;(GMT+01:00) West Central Africa",
		"Africa/Windhoek;(GMT+01:00) Windhoek",
		"Asia/Beirut;(GMT+02:00) Beirut",
		"Africa/Cairo;(GMT+02:00) Cairo",
		"Asia/Gaza;(GMT+02:00) Gaza",
		"Africa/Blantyre;(GMT+02:00) Harare, Pretoria",
		"Europe/Helsinki;(GMT+02:00) Helsinki, Riga, Tallinn, Athens",
		"Asia/Jerusalem;(GMT+02:00) Jerusalem",
		"Europe/Minsk;(GMT+02:00) Minsk",
		"Asia/Damascus;(GMT+02:00) Syria",
		"Europe/Moscow;(GMT+03:00) Moscow, St. Petersburg, Volgograd",
		"Africa/Addis_Ababa;(GMT+03:00) Nairobi",
		"Asia/Tehran;(GMT+03:30) Tehran",
		"Asia/Dubai;(GMT+04:00) Abu Dhabi, Muscat",
		"Asia/Yerevan;(GMT+04:00) Yerevan",
		"Asia/Kabul;(GMT+04:30) Kabul",
		"Asia/Yekaterinburg;(GMT+05:00) Ekaterinburg",
		"Asia/Tashkent;(GMT+05:00) Tashkent",
		"Asia/Kolkata;(GMT+05:30) Chennai, Kolkata, Mumbai, New Delhi",
		"Asia/Kathmandu;(GMT+05:45) Kathmandu",
		"Asia/Dhaka;(GMT+06:00) Astana, Dhaka",
		"Asia/Novosibirsk;(GMT+06:00) Novosibirsk",
		"Asia/Rangoon;(GMT+06:30) Yangon (Rangoon)",
		"Asia/Bangkok;(GMT+07:00) Bangkok, Hanoi, Jakarta",
		"Asia/Krasnoyarsk;(GMT+07:00) Krasnoyarsk",
		"Asia/Hong_Kong;(GMT+08:00) Beijing, Chongqing, Hong Kong, Urumqi",
		"Asia/Irkutsk;(GMT+08:00) Irkutsk, Ulaan Bataar",
		"Australia/Perth;(GMT+08:00) Perth",
		"Australia/Eucla;(GMT+08:45) Eucla",
		"Asia/Tokyo;(GMT+09:00) Osaka, Sapporo, Tokyo",
		"Asia/Seoul;(GMT+09:00) Seoul",
		"Asia/Yakutsk;(GMT+09:00) Yakutsk",
		"Australia/Adelaide;(GMT+09:30) Adelaide",
		"Australia/Darwin;(GMT+09:30) Darwin",
		"Australia/Brisbane;(GMT+10:00) Brisbane",
		"Australia/Hobart;(GMT+10:00) Hobart",
		"Asia/Vladivostok;(GMT+10:00) Vladivostok",
		"Australia/Lord_Howe;(GMT+10:30) Lord Howe Island",
		"Pacific/Noumea;(GMT+11:00) Solomon Is., New Caledonia",
		"Asia/Magadan;(GMT+11:00) Magadan",
		"Pacific/Norfolk;(GMT+11:30) Norfolk Island",
		"Asia/Anadyr;(GMT+12:00) Anadyr, Kamchatka",
		"Pacific/Auckland;(GMT+12:00) Auckland, Wellington",
		"Pacific/Fiji;(GMT+12:00) Fiji, Kamchatka, Marshall Is.",
		"Pacific/Chatham;(GMT+12:45) Chatham Islands",
		"Pacific/Tongatapu;(GMT+13:00) Nuku'alofa",
		"Pacific/Kiritimati;(GMT+14:00) Kiritimati"
	] />
	<cfreturn local.tzArray>
</cffunction>

<cffunction name="updateBasics" hint="for profile">
	<cfargument name="userInfo">
	<cfset var updater = "">
	<cftry>
		<cfquery name="updater">
			UPDATE users 
			SET firstname = <cfqueryparam value="#arguments.userInfo.firstname#">,
				lastname = <cfqueryparam value="#arguments.userInfo.lastname#">,
				email = <cfqueryparam value="#arguments.userInfo.email#">,
				timezone = <cfqueryparam value="#arguments.userInfo.timezone#">
			WHERE userID = <cfqueryparam value="#session.user.userID#" cfsqltype="integer">	
		</cfquery>
		<cfset session.user.firstname = arguments.userInfo.firstname>
		<cfset session.user.lastName = arguments.userInfo.lastname>
		<cfset session.user.timezone = arguments.userInfo.timezone>
		<cfreturn true>
		<cfcatch>
			<cfset logDbError( cfcatch, "my.updateBasics" )>			
			<cfreturn false>
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="updateImage" hint="for profile">
	<cfargument name="filename">
	<cfset var addPhoto = "">
	<cftry>
		<cfquery name="addPhoto">
			UPDATE users
			SET imgFilename = <cfqueryparam value="#arguments.filename#">
			WHERE userID = <cfqueryparam value="#session.user.userID#" cfsqltype="integer">	
		</cfquery>
		<cfreturn true>
		<cfcatch>
			<cfset logDbError( cfcatch, "my.updateImage" )>			
			<cfreturn false>
		</cfcatch>
	</cftry>
</cffunction>

</cfcomponent>