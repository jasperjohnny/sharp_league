<cfoutput>

<div class="row">
	<div class="span12">

		<h2>Reset Password</h2>
		<br />
		<cfif structKeyExists( rc, "returnMsg" )>
			<div class="alert alert-error left">
				<button class="close" data-dismiss="alert">x</button>
				#rc.returnMsg#
			</div>
		</cfif>
		<p>Hello #rc.resetData.firstname# #rc.resetData.lastname#.</p>
		<p>Please fill in the below fields to reset your password. The password must be eight characters and include one number.</p>
				
		<form action="/front/reset_pass_form" method="post">
			<p><label>Password: <input name="password1" type="password"></label></p>
			<p><label>Re-type Password: <input name="password2" type="password"></label></p>
			<input type="hidden" name="resetID" value="#rc.resetID#">
			<input type="submit" name="submit" value="submit" class="btn">
		</form>
	</div>
</div>

</cfoutput>

<!--- <cfdump var="#rc#"> --->
