<cfset rc.pageTitle = "A Friendly, Fantastic Wagering Tournament" />
<cfset rc.pageDesc = "A fantasy tournament where everyone starts with $2,000 fake dollars. You *bet* all season long on real NFL games, and the person with the most money at the end wins." />
<cfoutput>

<!--- <div class="alert alert-info">
	<i class="icon-exclamation-sign"></i> Now forming tournaments for the NFL Playoffs, including a prop-bet contest for the Super Bowl.
</div> --->

<div class="row">
	<div class="span6 center">
		<h2 class="left">Sign In</h2>
		<p class="left">Welcome back. <a href="/front/resend_pass">Forgot your password?</a></p>
		<div class="right" style="width: 280px;">
		<form action="/front/login_form" method="post">
			<p><label>email: <input type="text" name="email" size="20" tabindex="1"></label></p>
			<p><label>pass: <input type="password" name="password" size="20" tabindex="2"></label></p>
			<p><label>remember me: <input type="checkbox" name="rememberMe" value="1" tabindex="3"></label>
			   <input class="btn" type="submit" value="Log In" tabindex="4"></p>
		</form>
		<cfif structKeyExists( rc, "returnMsg" )>
			<div class="alert alert-error left">
				<button class="close" data-dismiss="alert">x</button>
				#rc.returnMsg#
			</div>
		</cfif>
		</div>
	</div>
	<div class="span6 right">
		<h2 class="left">New? Sign Up</h3>
		<p class="left">Register for free to join a tourney or start your own.</p>

		<div class="right" style="width: 280px;">
		<form action="/front/register_form" method="post">
			<p><label>first: <input type="text" name="firstName" size="20" tabindex="5"></label></p>
			<p><label>last: <input type="text" name="lastName" size="20" tabindex="6"></label></p>
			<p><label>email: <input type="text" name="email" size="20"  tabindex="7"></label></p>
			<p><label>pass: <input type="password" name="password" size="20" tabindex="8"></label></p>
			<p><input class="btn" type="submit" value="Sign Up" tabindex="9"></p>
		</form>
		<cfif structKeyExists( rc, "returnMsg2" )>
			<div class="alert alert-error left">
				<button class="close" data-dismiss="alert">x</button>
				#rc.returnMsg2#
			</div>
		</cfif>
		</div>
	</div>
</div>

<div class="row">
	<div class="span4">
		<div class="well">
			<h3><i class="icon-star"></i> What is this?</h3>
			<p class="subtext">Imagine a contest where everyone starts with $2,000 fake dollars. 
			You "bet" all season long on real NFL games, and the person with the most money at the end wins.</p>
		</div>
	</div>
	<div class="span4">
		<div class="well">
			<h3><i class="icon-star"></i> How do I play?</h3>
			<p class="subtext">Run a league and invite your friends. It's free and super easy.
			Sharp League does not collect or pay any real money. We just provide the software.</p>
		</div>
	</div>
	<div class="span4">
		<div class="well">
			<h3><i class="icon-star"></i> Anything else?</h3>
			<p class="subtext">Oh, yes. There are side pools, message boards, crazy parlays, hidden bets. 
			Check out the <a href="front/faq">Frequently Asked Questions</a> for more info.
		</div>
	</div>
</div>

</cfoutput>
