<cfoutput>
	
<cfif cgi.HTTP_HOST EQ "localsharp2">
	Don't throw anything.
	<cfdump var="#request.exception#">
<cfelse>

	<div class="row">
		<div class="span6">
			<h2>Crap, an error</h2>
			<p>Sorry. Something didn't happen right.<br />
			Let's not point fingers.</p>
			<p>Please let John know so he can have a look. Thanks.</p>
			<p><a href="/">Take me home</a>.</p>
		</div>
		<div class="span6">
			<img src="/images/gifs/high_jump_bravado.gif" />
		</div>
	</div>
	
</cfif>
	
</cfoutput>