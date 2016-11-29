<cfoutput>

<div class="row">
	<div class="span8">
		<h2>Forgot your Password?</h2>
		<p>We can send you an email with instructions on how to reset it.</p>
		<br />
		<form class="form-inline" action="resend_pass_form" method="post">
		<p><label>Email address: <input type="text" name="email"></label>
		<input type="submit" name="submit" value="submit" class="btn">
		</p>
		</form>
		<cfif structKeyExists( rc, "returnMsg" )>
			<div class="alert alert-error left">
				<button class="close" data-dismiss="alert">x</button>
				#rc.returnMsg#
			</div>
		</cfif>
	</div>
</div>

</cfoutput>

<!---  <cfdump var="#rc#"> --->
