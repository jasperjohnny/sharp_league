<cfset rc.pageTitle = "Edit Profile">
<cfoutput>

<div class="span7">

	<cfif structKeyExists( rc, "returnMsg" )>
		<div class="alert alert-success">
			<button class="close" data-dismiss="alert">x</button>
			#rc.returnMsg#
		</div>
	</cfif>

	<br />	
	<h3>Update the Basics</h3>
	<form method="post" action="profile_basics_form" class="form-horizontal">
		<div class="control-group">
			<label class="control-label" for="firstname">First Name</label>
			<div class="controls">
				<input type="text" id="firstname" name="firstname" value="#rc.profileinfo.firstname#" />
			</div>
		</div>
		<div class="control-group">
			<label class="control-label" for="lastname">Last Name</label>
			<div class="controls">
				<input type="text" id="lastname" name="lastname" value="#rc.profileinfo.lastname#" />
			</div>
		</div>
		<div class="control-group">
			<label class="control-label" for="email">Email</label>
			<div class="controls">
				<input type="text" id="email" name="email" value="#rc.profileinfo.email#" />
			</div>
		</div>
		<div class="control-group">
			<label class="control-label" for="timezone">Timezone</label>
			<div class="controls">
				<select name="timezone" id="timezone">
				<cfloop array="#rc.tzArray#" index="i">
				 	<option value="#listGetAt( i, 1, ";", true )#" <cfif rc.profileinfo.timezone EQ "#listGetAt( i, 1, ";", true )#">selected="selected"</cfif> >#listGetAt( i, 2, ";", true )#</option>
				</cfloop>
				</select>
				<br /><br/>
				<input type="submit" name="submit" value="submit change" class="btn">
			</div>
		</div>
	</form>
	
	<br />
	<h3>Change Password</h3>
	<form method="post" action="profile_pwd_form" class="form-horizontal">
		<div class="control-group">
			<label class="control-label" for="password1">Password</label>
			<div class="controls">
				<input type="password" id="password1" name="password1" />
			</div>
		</div>
		<div class="control-group">
			<label class="control-label" for="password2">Type Again</label>
			<div class="controls">
				<input type="password" id="password2" name="password2" />
				<br /><br />
				<input type="submit" name="submit" value="submit change" class="btn">
			</div>
		</div>
	</form>
	
	<br />
	<h3>Change Image</h3>
	<form method="post" action="profile_img_form" enctype="multipart/form-data" class="form-horizontal">
		<div class="control-group">
			<label class="control-label" for="newImage">Change to</label>
			<div class="controls">
				<input type="file" id="newImage" name="newImage">
				<br /><br />
				<input type="submit" name="submit" value="submit change" class="btn"></p>
			</div>
		</div>
	</form>
</div>

<!--- <cfdump var="#rc#"> --->

</cfoutput>
