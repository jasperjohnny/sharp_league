<cfoutput>

<div class="row" style="margin-top: 20px;">
	<div class="span4 center hidden-phone">
		<a href="/"><img src="/images/sharp_league_228px.jpg"></a>
		<h1 style="margin: 20px 0 10px;">#session.user.firstname# #session.user.lastname#</h1>
		<p>Email: #rc.profileInfo.email#</p>
		<p>Timezone: #rc.profileInfo.timezone#</p>
		<p><a href="/my/profile">Edit Profile</a> | <a href="/front/logout">Log Out</a></p>
		<cfif rc.profileInfo.imgFilename NEQ "default.jpg">
			<br />
			<p><img src="#application.imgPath#/profiles/#rc.profileInfo.imgFilename#" height="120px" />
		</cfif>
	</div>
	<div class="span4 right hidden-tablet">
		<p><a href="/"><img style="float:right;margin: 0 10px;" src="/images/sharp_league_shield2.png" width="45px"></a>
			Logged in as #session.user.firstname#<br /><a href="/my/profile">Edit Profile</a> | <a href="/front/logout">Log Out</a></p>
		</p>
	</div>
	#body#
</div>

</cfoutput>
